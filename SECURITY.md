# Security Policy

This repository is the release trust root for the `purpleclay` organisation:
its workflows build, attest, and publish the artifacts other projects ship.
A vulnerability here potentially affects every downstream release, so reports
are taken seriously and handled with priority.

## Reporting a vulnerability

Report privately via GitHub's private vulnerability reporting on this
repository (Security tab → Report a vulnerability). Do not open a public
issue or discuss suspected vulnerabilities in pull requests.

You can expect an acknowledgement within 48 hours and an assessment within
7 days. Coordinated disclosure is preferred: a fix is developed privately, a
patched release is tagged, a security advisory is published crediting the
reporter (unless you'd rather not be named), and consuming repositories are
bumped via Renovate.

## What counts as a vulnerability here

Anything that weakens the guarantees these workflows exist to provide:

- Forging, bypassing, or weakening build provenance — e.g. a way for a
  calling repository's build steps to influence attestation subjects, or to
  obtain the signing identity of these workflows.
- Artifact tampering between build and publish — e.g. defeating the
  immutable-artifact-id handoff or the checksum coverage.
- Injection through caller-controlled inputs (`bin`, `targets`,
  `package-files`, tag names) into shell, filenames, or release content.
- Egress or cache weaknesses that permit poisoning of the release build.
- Vulnerable or compromised pinned dependencies (actions, Zig, cargo-zigbuild)
  where the pinned version is affected.

Hardening suggestions that don't cross the line into exploitability are
welcome too — open a regular issue for those.

## Supported versions

Only the latest tagged release receives fixes. Consumers pin full commit
SHAs and are expected to track new releases via Renovate; a security fix is
delivered as a new patch release, never by mutating an existing tag or
release (releases here are immutable by policy and by repository setting).

## Verifying what you consume

Every artifact produced by these workflows carries verifiable provenance:

```sh
gh attestation verify <artifact> \
  --repo purpleclay/<project> \
  --signer-workflow purpleclay/release-workflows/.github/workflows/release-rust.yml
```

If verification fails on an artifact claiming to come from this pipeline,
treat that as a security report in itself.
