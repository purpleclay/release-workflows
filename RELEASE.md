# Releasing

Releases of this repository are deliberately low-tech: a human creates a
tag, and a tag-triggered workflow generates the release note and publishes
an asset-free GitHub release. There is nothing to build — reusable workflows
ship as source, consumed at a git ref — so the integrity story is git-native:
the tag ruleset, signed tags, immutable releases, and this documented process.

## Versioning

Tags are `vX.Y.Z` (v-prefixed, Actions ecosystem convention — unlike the
bare semver used by purpleclay binary projects). Semver tracks **the caller
interface**, not upstream dependency versions:

- **Major** — renamed/removed inputs or outputs; changes to archive naming
  or layout (installers parse these); changes to attestation subjects or
  predicate types (verification commands depend on these); any *increase*
  in the permissions callers must grant; dropping a supported target.
- **Minor** — new inputs with defaults, new outputs, new supported targets,
  new workflows.
- **Patch** — dependency bumps (Renovate lands these as `fix(deps)`),
  internal hardening, documentation.

An upstream dependency's major bump that leaves the caller interface
untouched is still a **patch** here. Review is where that judgement is made:
if a bump leaks caller-visible behaviour, escalate the commit type manually.

There are **no floating major tags** (`v1` does not move). Consumers pin
full commit SHAs with the version as a trailing comment; Renovate proposes
bumps and embeds these release notes in the PR — write them for that reader.

## Cutting a release

Tag creation is intentionally manual. Binary projects in the org automate
tagging with `nsv`; this repo keeps a human in the loop because every
release changes release security for every downstream project, and volume
is low. Revisit if that frequency ever makes the manual step a bottleneck.

1. Confirm main is green (ci, scorecard) and every merged-but-unreleased
   change is accounted for:

   ```sh
   git log $(git describe --tags --abbrev=0)..main --oneline
   ```

   > [!NOTE]
   > Consumers only discover updates through tags — a merged-but-untagged
   > fix, even a security-relevant one, is invisible to every downstream
   > project until it's released. If this check surprises you, you're not
   > tagging often enough.

2. Create a signed, annotated tag locally and push it:

   ```sh
   git tag -s vX.Y.Z -m "chore: release for vX.Y.Z"
   git push origin vX.Y.Z
   ```

   Tag creation is restricted by ruleset to maintainers; the push is the
   release decision.
3. The `release` workflow triggers on the tag: it generates the release
   note (release-note-action, provenance-verified binary) and publishes the
   release with `--verify-tag`. No assets, by design.
4. Verify: the release exists, notes render correctly, and the tag/release
   are locked (immutable releases).

## Fixing a bad release

> [!WARNING]
> Never by mutation. A broken release is followed by a fixed patch release;
> the bad tag stays (immutable releases prevent deleting or re-pointing it,
> deliberately).

If the defect is security-relevant, follow `SECURITY.md` and publish an
advisory alongside the fix.
