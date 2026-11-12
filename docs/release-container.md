# release-container

Builds a container image from binaries that [release-go](release-go.md) or [release-rust](release-rust.md) already released, attests it, and pushes it to GHCR. This page is the **caller contract**: anything listed here changes only under the versioning rules in [RELEASE.md](../RELEASE.md). The workflow file's comments explain _how_; this page defines _what_ callers may rely on.

There's no Dockerfile and no Docker daemon. An image is a base of Wolfi packages, built by [apko](https://github.com/chainguard-dev/apko) from a lock file, or `scratch`, plus one layer holding your binaries. Binaries are never rebuilt: each one is downloaded from its release and must pass `gh attestation verify` before it's added. Arbitrary Dockerfiles are not supported, and won't be. A project that needs one isn't served by this workflow.

## Usage

```yaml
name: release
on:
  push:
    tags: ["v*.*.*"]

permissions: {}

jobs:
  release:
    permissions:
      id-token: write # OIDC identity for Sigstore signing
      attestations: write # persist attestations
      contents: write # create the release, upload assets
    uses: purpleclay/release-workflows/.github/workflows/release-go.yml@<pinned-sha> # vX.Y.Z
    with:
      bin: nsv
      targets: '["linux/amd64","linux/arm64","darwin/amd64","darwin/arm64"]'

  image:
    needs: release
    permissions:
      contents: read # read the apko config, download release assets
      packages: write # push the image to GHCR
      id-token: write # OIDC identity for Sigstore signing
      attestations: write # persist the image attestation
    uses: purpleclay/release-workflows/.github/workflows/release-container.yml@<pinned-sha> # vX.Y.Z
    with:
      bin: nsv
      built-by: release-go
      apko-config: .github/container/apko.yaml
      include: '[{"repo":"purpleclay/gpg-import","tag":"0.13.0","bin":"gpg-import","built-by":"release-rust"}]'
      scripts: .github/container/entrypoint.sh
      entrypoint: '["/usr/bin/tini","--","/usr/bin/entrypoint.sh"]'
      cmd: '["--help"]'
```

Must be triggered from a **tag push**, and the tag's release must already exist, so run it as a job that `needs` the release job.

## Inputs

See [release-container.yml](../.github/workflows/release-container.yml)

```yaml
uses: purpleclay/release-workflows/.github/workflows/release-container.yml@<pinned-sha> # vX.Y.Z
with:
  # Binary to put in the image, taken from the release for the tag that
  # triggered the run.
  # Required.
  bin:

  # Workflow that released bin: release-go or release-rust.
  # Required.
  built-by:

  # JSON array of image platforms. Unsupported platforms and duplicates
  # fail in the plan job.
  # Optional. Default is '["linux/amd64","linux/arm64"]'
  platforms:

  # Path to an apko config listing the Wolfi packages the image needs, with
  # its lock file beside it (apko.yaml -> apko.lock.json).
  # Optional. Default is "" (scratch)
  apko-config:

  # JSON array of binaries from other release-workflows releases, each with
  # repo, tag, bin and built-by. Each is verified against its own release.
  # Optional. Default is "[]"
  include:

  # Space-separated list of repository files added to /usr/bin with mode
  # 0755, such as an entrypoint script.
  # Optional. Default is ""
  scripts:

  # JSON array for the image entrypoint.
  # Optional. Default is '["/usr/bin/<bin>"]'
  entrypoint:

  # JSON array for the image cmd.
  # Optional. Default is "" (none)
  cmd:

  # GitHub environment the publish job runs under. GitHub creates a missing
  # environment without protection, so add a required reviewer in each repo.
  # Optional. Default is release
  environment:
```

The apko config may only use Wolfi: its `contents.repositories` must be exactly `https://packages.wolfi.dev/os`, its `contents.keyring` exactly that repository's `wolfi-signing.rsa.pub`, and it can't use `include` or `contents.baseimage`. Every package in the lock file must come from the same repository, and the lock must cover every platform. Anything else fails in the plan job. A minimal config:

```yaml
contents:
  repositories:
    - https://packages.wolfi.dev/os
  keyring:
    - https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
  packages:
    - wolfi-baselayout
    - ca-certificates-bundle
    - git

accounts:
  groups:
    - groupname: nonroot
      gid: 65532
  users:
    - username: nonroot
      uid: 65532
      gid: 65532
  run-as: 65532

archs:
  - x86_64
  - aarch64
```

Generate the lock file with `apko lock .github/container/apko.yaml` and commit both files.

## Outputs

| Output   | Description                                                    |
| -------- | -------------------------------------------------------------- |
| `image`  | Image name, without a tag or digest: `ghcr.io/<owner>/<repo>`. |
| `digest` | Digest of the published image index.                           |

## Supported platforms

| Platform      | release-go archive | release-rust archive         |
| ------------- | ------------------ | ---------------------------- |
| `linux/amd64` | `linux-amd64`      | `x86_64-unknown-linux-musl`  |
| `linux/arm64` | `linux-arm64`      | `aarch64-unknown-linux-musl` |

Every binary, including those in `include`, must have been released for every requested platform. Adding a platform is a minor version; removing one is a major.

## What an image contains

- **Name:** `ghcr.io/<owner>/<repo>`, lowercased, tagged with the release tag, with `/` replaced by `-`.
- **An index** with one image per platform.
- **A base:** the packages pinned in your apko lock file, or nothing (`scratch`).
- **One layer** with `bin`, every `include` binary, and every `scripts` file in `/usr/bin`, all mode 0755, owned by root, with a fixed mtime.
- **Config:** your `entrypoint` and `cmd`, plus the `org.opencontainers.image.source`, `.revision` and `.version` labels. On `scratch` the user is `65532:65532`. With apko, the user is whatever your config sets with `run-as`.

The image provenance attestation is signed by this workflow's identity, with the index digest as its subject, and is stored both in GitHub's attestation API and in the registry beside the image.

## What callers must know

- **Pull by digest, not by tag.** Registry tags can be moved, and immutable releases have no registry equivalent. Verify and deploy `ghcr.io/<owner>/<repo>@sha256:…`.
- **`scratch` only suits static binaries.** A `cgo: true` Go binary is linked against glibc and needs a base with it. Wolfi is glibc-based, so add `wolfi-baselayout` and the packages your binary loads. musl-based images such as Alpine won't run it.
- **Package updates come from the lock file.** The image only picks up a Wolfi fix once `apko.lock.json` is regenerated. Renovate has no apko manager, so refresh the lock on a schedule (see [#147](https://github.com/purpleclay/release-workflows/issues/147)).
- **Rebuilds are reproducible.** The same tag, lock file and release assets give the same digest, so re-running the workflow re-pushes an identical image.
- **Wolfi package names don't always match other distributions.** For example, Wolfi's `gnupg` doesn't include the `gpg` binary; add the `gpg` and `gpg-agent` packages instead.
- **Dependencies are pinned centrally** (apko, crane, all actions) and bumped via reviewed `fix(deps)` patch releases.

## Verifying what it produced

```sh
gh attestation verify oci://ghcr.io/purpleclay/<project>@<digest> \
  --repo purpleclay/<project> \
  --signer-workflow purpleclay/release-workflows/.github/workflows/release-container.yml \
  --source-ref refs/tags/<tag> \
  --deny-self-hosted-runners
```

Add `--bundle-from-oci` to read the attestation from the registry instead of GitHub's attestation API. To also pin the exact revision of this workflow, add `--signer-digest <sha>` with the commit SHA your caller pins.

The image attestation covers the image. Each binary inside it keeps its own provenance on its release, which this workflow verified before adding it. The publish job runs the command above, against both the API and the registry, before the run reports success.

## Adoption checklist

1. Release your binaries with [release-go](release-go.md) or [release-rust](release-rust.md), including the Linux platforms the image needs.
2. Write the apko config, if the image needs packages, and commit it with its lock file.
3. Add the `image` job above, with `needs` on the release job.
4. Create the environment named by `environment` (default `release`) and add a required reviewer.
5. Cut a release, confirm the image is pushed, then make the GHCR package public if it should be.
6. Add the verify command to the project README.
