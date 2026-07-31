# Keeping `zig-mirrors.txt` in sync

`zig-mirrors.txt` is the reviewed set of Zig community mirrors trusted as a build-job egress target for zigbuild legs. `release-rust.yml` only allows a mirror through if it's *both* in this file *and* currently live upstream (see [issue #31](https://github.com/purpleclay/release-workflows/issues/31) for why it isn't just fetched from upstream directly).

This is a deliberately manual process — a bot opening a routine PR risks training reviewers to rubber-stamp it, which defeats the point of requiring review at all. Automating this is tracked as a possible future issue if the manual upkeep ever becomes a real burden; it isn't expected to.

## When to check

There's no fixed schedule. Worth checking when:

- A zigbuild release fails with "no zig mirrors are both live upstream and reviewed" (`compose_build_matrix`'s hard-failure path) — this means the two lists have diverged enough to share nothing at all, and needs attention immediately.
- Roughly every few months, or whenever you're touching this workflow for another reason anyway.

## How to check

```sh
diff <(curl -fsSL https://ziglang.org/download/community-mirrors.txt | sort) \
     <(sort .github/zig-mirrors.txt)
```

Lines prefixed `<` are in the committed file but no longer live upstream — safe to drop, no review needed, they can't be reached anyway. Lines prefixed `>` are new upstream entries — this is the part that needs actual scrutiny, not a rubber stamp.

## Reviewing a new entry

For each newly-added host, actually verify it before adding it — don't just accept it because it's on the official list. At minimum:

1. Confirm it resolves and serves a real Zig release tarball. It should return `200`, not a redirect to somewhere unexpected or a `404`.
   ```sh
   curl -sIL "https://<mirror>/zig-x86_64-linux-<version>.tar.xz"
   ```
2. Check who operates it, if that's discoverable (project README, DNS WHOIS, whether it's referenced elsewhere in the Zig community). Prefer mirrors run by identifiable people/organizations over anonymous ones.

Then update `.github/zig-mirrors.txt` to match upstream and commit — a normal PR, reviewed the same as any other change to this workflow.
