# apko-lock

Regenerates the apko lock file that [release-container](release-container.md) builds an image from, and opens a PR when it changes. This page is the **caller contract**: anything listed here changes only under the versioning rules in [RELEASE.md](../RELEASE.md).

An image only picks up a Wolfi package fix once `apko.lock.json` is regenerated. Renovate can't do that: it has no apko manager, and the apko config names packages without versions, so a fixed package changes nothing but the lock file. Run this workflow on a schedule instead.

## Usage

```yaml
name: apko-lock
on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:

permissions: {}

jobs:
  apko-lock:
    permissions:
      contents: write # commit the lock file to the update branch
      pull-requests: write # open or update the PR
    uses: purpleclay/release-workflows/.github/workflows/apko-lock.yml@<pinned-sha> # vX.Y.Z
    with:
      config: .github/container/apko.yaml
```

Runs only on the default branch, which is where scheduled runs start.

## Inputs

See [apko-lock.yml](../.github/workflows/apko-lock.yml)

```yaml
uses: purpleclay/release-workflows/.github/workflows/apko-lock.yml@<pinned-sha> # vX.Y.Z
with:
  # Path to the apko config. Its lock file is the same path with
  # .lock.json in place of the extension (apko.yaml -> apko.lock.json).
  # Required.
  config:
```

The config must follow the same Wolfi-only rule as release-container: `contents.repositories` exactly `https://packages.wolfi.dev/os`, `contents.keyring` exactly its `wolfi-signing.rsa.pub`, and no `include` or `contents.baseimage`. Anything else fails before apko runs.

## What a run does

1. Runs `apko lock` with the same apko version and checksum that release-container uses, so the lock is written by the apko that later reads it.
2. Stops if the lock file hasn't changed.
3. Resets the `apko-lock` branch onto the default branch and commits the new lock through the GitHub API, unless the branch already holds the same lock. GitHub signs the commit. Its message is `fix(deps): refresh apko lock file` with a `Signed-off-by` for `github-actions[bot]`.
4. Opens a PR from `apko-lock`, or updates the body of the open one. The body lists every package whose version changed.

Step 4 runs even when the branch is already current, so re-running a failed run finishes it. Runs in the same repository queue rather than overlap. There is only ever one open PR. A run that commits replaces the branch, so edits pushed to it are lost.

## What callers must know

- **Approve CI on each PR.** GitHub creates the `pull_request` runs for a PR opened with `GITHUB_TOKEN`, but holds them until a maintainer selects **Approve workflows to run** on the PR. Their checks then appear on the PR as usual. Your CI workflow needs no changes.
- **Turn on "Allow GitHub Actions to create and approve pull requests"** under Settings → Actions → General. Without it, the PR step fails.
- **The commit type is `fix(deps)`.** The lock's packages ship in the image, which matches the convention for other dependencies that ship. With [nsv](https://github.com/purpleclay/nsv) that means merging the PR leads to a patch release, and the new image is built from the new lock.
- **One config per repository.** The branch name is fixed, so a second caller in the same repo would overwrite the first's PR.
- **A stale PR isn't closed.** If the lock is refreshed by hand on the default branch, close the open PR yourself.
- **apko is pinned centrally** with release-container's pin and bumped in the same reviewed `fix(deps)` PR.

## Adoption checklist

1. Adopt [release-container](release-container.md) with an apko config and lock file.
2. Turn on "Allow GitHub Actions to create and approve pull requests".
3. Add the workflow above, then run it once by hand to confirm it opens a PR or reports the lock is current.
