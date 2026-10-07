# Security Policy

This repository is the release trust root for purpleclay projects: its workflows build, attest, and publish what those projects ship. A vulnerability here can affect every downstream release, so reports are handled with priority.

## Reporting a vulnerability

Report privately through GitHub's private vulnerability reporting:

https://github.com/purpleclay/release-workflows/security/advisories/new

Don't open a public issue or discuss a suspected vulnerability in a pull request.

Expect an acknowledgement within 48 hours and an assessment within 7 days. Disclosure is coordinated: the fix is developed privately, a patched release is tagged, an advisory is published crediting you (unless you'd rather not be named), and consuming repositories are bumped via Renovate.

## What counts as a vulnerability

Anything that weakens the guarantees these workflows provide:

- Forging, bypassing, or weakening provenance, for example letting a caller's build steps influence attestation subjects or reach the signing identity.
- Swapping or tampering with an artifact between build and attestation.
- Injection through caller-controlled inputs or tag names into shell commands, filenames, or release content.
- Egress or cache weaknesses that allow the release build to be poisoned.
- A pinned action or build tool affected by a known vulnerability or compromise.

Hardening suggestions that aren't exploitable are welcome as regular issues.

## Supported versions

Only the latest release receives fixes. Consumers pin full commit SHAs and track new releases via Renovate. A security fix ships as a new patch release, never by changing an existing tag or release.

## Verifying what you consume

Every artifact these workflows produce carries verifiable provenance. The commands are in each workflow's contract: [release-rust](docs/release-rust.md#verifying-what-it-produced) and [release-go](docs/release-go.md#verifying-what-it-produced).

If an artifact claiming to come from this pipeline fails verification, treat that as a security report in itself.
