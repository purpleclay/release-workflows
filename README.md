# Release Workflows
 
[![MIT](https://img.shields.io/badge/MIT-gray?logo=github&logoColor=white)](LICENSE)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/purpleclay/release-workflows/badge)](https://scorecard.dev/viewer/?uri=github.com/purpleclay/release-workflows)
 
Reusable release workflows for `purpleclay` projects. Every release built here ships with SLSA Build Level 3 provenance, per-artifact SBOMs, and keyless Sigstore signatures — with no secrets, no key material, and no per-project security plumbing.
 
## Why this repository exists
 
GitHub artifact attestations generated inside a project's own workflow reach SLSA Build **Level 2**: the provenance is real, but it is produced by the same workflow a compromised repository could edit. Level **3** requires the provenance to be generated somewhere the build cannot reach — a shared, vetted, isolated workflow whose identity a tenant build cannot impersonate.
 
This repository is that workflow. Projects delegate their release to it with a single `uses:` call, and consumers gain something stronger than "this artifact has provenance": they can verify that a release was built by *this specific pipeline*, at a known commit, from a known source revision — and reject anything that wasn't.
 
Centralising the release path has a second benefit that has nothing to do with attestations: there is exactly one place where release security is implemented, reviewed, and improved. A hardening change lands here once and every project inherits it on its next release.
