# Releasing

Releases of this repository are deliberately low-tech: a human pushes a signed tag, and a tag-triggered workflow generates the release note and publishes an asset-free GitHub release. Reusable workflows ship as source, consumed at a git ref, so the integrity story is git-native: the tag ruleset, signed tags, immutable releases, and this process.

## Versioning

Tags are `vX.Y.Z`, following the Actions convention rather than the bare semver purpleclay binary projects use. Semver tracks **the caller interface**, not upstream dependency versions:

- **Major**: renamed or removed inputs or outputs; changes to archive naming or layout, which installers parse; changing or removing an attestation subject or predicate type, which verification commands rely on; any *increase* in the permissions callers must grant; dropping a supported target.
- **Minor**: new inputs with defaults, new outputs, new supported targets, new workflows, new attestations or predicate types, and any *decrease* in the permissions callers must grant.
- **Patch**: dependency bumps (Renovate lands these as `fix(deps)`), internal hardening, documentation.

An upstream major bump that leaves the caller interface untouched is still a **patch**. Review is where that call is made: if a bump changes anything callers can see, raise the commit type by hand.

There are **no floating major tags** (`v1` does not move). Consumers pin full commit SHAs with the version as a trailing comment. Renovate proposes bumps and embeds these release notes in the PR, so write them for that reader.

## Cutting a release

Tagging is manual. Binary projects automate it with `nsv`, but every release here changes release security for every downstream project, and volume is low, so a human stays in the loop.

1. Confirm `main` is green (ci, scorecard) and every change since the last tag is accounted for:

   ```sh
   git log "$(git describe --tags --abbrev=0)..main" --oneline
   ```

   > [!NOTE]
   > Consumers only see changes once they're tagged. A merged but untagged fix, even a security fix, reaches no downstream project.

2. Create a signed, annotated tag and push it:

   ```sh
   git tag -s vX.Y.Z -m "chore: release for vX.Y.Z"
   git verify-tag vX.Y.Z
   git push origin vX.Y.Z
   ```

   The tag must be signed with the `purpleclay` key, the only signer the workflow accepts. Tag creation is restricted to maintainers by ruleset, so the push is the release decision.

3. The `release` workflow then:
   - rejects any tag that isn't exactly `vX.Y.Z`
   - verifies the tag's signature against the `purpleclay` GPG key
   - generates the release note with release-note-action
   - creates the release with `gh release create --verify-tag`, which only confirms the tag exists

   The release has no assets, by design.

4. Check the release exists, the notes render, and the release shows as immutable.

## Fixing a bad release

> [!WARNING]
> Never by changing it. Immutable releases can't be edited, deleted, or re-pointed, so a bad release is followed by a fixed patch release under a new tag.

The same applies when a caller's publish fails partway, for example `release-rust.yml` interrupted mid-upload: the workflow treats any existing release for a tag as done, so the only recovery is a new tag.

If the defect is security-relevant, follow [SECURITY.md](SECURITY.md) and publish an advisory alongside the fix.
