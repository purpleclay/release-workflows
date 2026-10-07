# Release Workflows

Reusable GitHub Actions workflows that build, sign, and publish releases, with no secrets and no signing keys.

[![MIT](https://img.shields.io/badge/MIT-gray?logo=github&logoColor=white)](LICENSE)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/purpleclay/release-workflows/badge)](https://scorecard.dev/viewer/?uri=github.com/purpleclay/release-workflows)
[![SLSA 3](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev)

## What every release gets

- **SLSA Build L3 provenance.** Signed under this repository's workflow identity, which a calling project can neither edit nor impersonate.
- **Keyless Sigstore signing.** Short-lived certificates issued over OIDC. No per-project secrets, no key rotation, nothing to leak.
- **Per-binary SPDX SBOMs.** Generated from the compiled binary rather than the lockfile, and attested alongside it.
- **Recorded build inputs.** The inputs, toolchain, and runner image behind each binary, signed as their own attestation.
- **Verified before publishing.** Every attestation is checked against the release tag and this workflow's commit. Nothing that fails is published.
- **Hardened by default.** Clean-room builds with no caches, every action pinned to a commit SHA, and network egress limited to an allowlist.

## Why this repository exists

Attestations generated inside a project's own workflow reach SLSA Build Level 2: the provenance is real, but a compromised repository could edit the workflow that produced it. Level 3 needs provenance from a shared workflow the project can't edit or impersonate. This repository is that workflow, so consumers can verify a release was built by this pipeline, at a known commit, from a known source revision.

**One place to get release security right.** Centralising the release path means there's exactly one implementation to review and improve. A hardening change lands here once, and every project inherits it on its next release.

## How it works

A project delegates its release with a single `uses:` call. Every stage then runs as its own job, and only the final stages can sign anything.

## Getting started

Pick a workflow and follow its caller contract. Each contract is the single source of truth for that workflow: usage, inputs, outputs, supported targets, archive naming, attestation subjects, an adoption checklist, and how consumers verify what was produced. Contracts change only under the versioning rules in [RELEASE.md](RELEASE.md).

| Workflow                                             | Builds        | Example tag | Caller contract                                                                                                                                          |
| :--------------------------------------------------- | :------------ | :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`release-rust`](.github/workflows/release-rust.yml) | Rust binaries | `1.2.3`     | [Usage](docs/release-rust.md#usage) · [Adopting](docs/release-rust.md#adoption-checklist) · [Verifying](docs/release-rust.md#verifying-what-it-produced) |
| [`release-go`](.github/workflows/release-go.yml)     | Go binaries   | `v1.2.3`    | [Usage](docs/release-go.md#usage) · [Adopting](docs/release-go.md#adoption-checklist) · [Verifying](docs/release-go.md#verifying-what-it-produced)       |

> [!IMPORTANT]
> **Pin the full commit SHA**, with the version as a trailing comment, so Renovate or Dependabot can propose bumps. There are no floating major tags here, by design.
