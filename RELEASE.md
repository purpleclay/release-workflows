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
   last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
   git log "${last_tag:+$last_tag..}main" --oneline
   ```

   (`git describe` fails outright before the first release ever cuts — the
   fallback above lists full history instead of erroring in that case.)

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

   The tag must be signed with the `purpleclay` key specifically — the
   workflow's only authorized signer (see step 3) — not just signed by
   anyone. Check before pushing: `git verify-tag vX.Y.Z`. Tag creation is
   restricted by ruleset to maintainers; the push is the release decision.
3. The `release` workflow triggers on the tag. It checks two different
   things, not one: that the tag is signed by an authorized signer (`git
   verify-tag` against a known key — this is what step 2's signature
   actually buys you), and separately, that the tag exists (`--verify-tag`
   on `gh release create` — existence only, it doesn't check who signed it
   or whether it was signed at all). It then generates the release note
   (release-note-action, provenance-verified binary) and publishes the
   release. No assets, by design.
4. Verify: the release exists, notes render correctly, and the tag/release
   are locked (immutable releases).

## Fixing a bad release

> [!WARNING]
> Never by mutation. A broken release is followed by a fixed patch release;
> the bad tag stays (immutable releases prevent deleting or re-pointing it,
> deliberately).

This applies just as much if the *publish itself* fails partway (for
example, `release-rust.yml` interrupted mid-asset-upload) as it does to a
release with a content bug. Immutable releases mean the workflow can't
delete or repair an existing release either way — it treats any existing
release for a tag as done, full stop. A stuck partial release isn't
recovered; it's abandoned the same as any other bad release, via a new tag.

If the defect is security-relevant, follow `SECURITY.md` and publish an
advisory alongside the fix.
