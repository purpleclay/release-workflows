# Keeping `zig-mirrors.txt` in sync

`zig-mirrors.txt` is the reviewed set of Zig community mirrors trusted as a build-job egress target for zigbuild legs. `release-rust.yml` only allows a mirror through if it's *both* in this file *and* currently live upstream (see [issue #31](https://github.com/purpleclay/release-workflows/issues/31) for why it isn't just fetched from upstream directly).

This is a deliberately manual process — a bot opening a routine PR risks training reviewers to rubber-stamp it, which defeats the point of requiring review at all. Automating this is tracked as a possible future issue if the manual upkeep ever becomes a real burden; it isn't expected to.

## When to check

There's no fixed schedule. Worth checking when:

- A zigbuild release fails with "no zig mirrors are both live upstream and reviewed" (`compose_build_matrix`'s hard-failure path) — this means the two lists have diverged enough to share nothing at all, and needs attention immediately.
- Roughly every few months, or whenever you're touching this workflow for another reason anyway.

## How to check

```bash
diff <(curl -fsSL https://ziglang.org/download/community-mirrors.txt | sort) \
     <(sort .github/zig-mirrors.txt)
```

Lines prefixed `<` are new upstream entries — this is the part that needs actual scrutiny, not a rubber stamp. Lines prefixed `>` are in the committed file but no longer live upstream — safe to drop, no review needed, they can't be reached anyway.

## Reviewing a new entry

For each newly-added host, actually verify it before adding it — don't just accept it because it's on the official list. At minimum:

1. Use the mirror's exact base URL as listed upstream, including its path — the path is part of what's being trusted, not incidental, and `release-rust.yml` compares the full URL when deciding what to approve (see #31). Most reviewed mirrors serve the archive flat, at `<base>/<file>` — unlike `ziglang.org/download` itself, which nests it under `<base>/<version>/<file>`; try the flat form first (only a minority of mirrors need the version segment). Download the archive *and* its `.minisig` sibling, then verify against the [Zig Software Foundation's public key](https://ziglang.org/download/) — a `200` response alone proves nothing, since a malicious mirror could serve any tarball it likes:

   ```sh
   archive=zig-x86_64-linux-<version>.tar.xz
   curl -fsSL "https://<mirror-base-url>/$archive" -o "$archive"
   curl -fsSL "https://<mirror-base-url>/$archive.minisig" -o "$archive.minisig"
   minisign -Vm "$archive" -P RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U
   ```

   `minisign` only checks that the signature matches the downloaded bytes — it does not check that the signed file is the one you actually asked for. A mirror could substitute the signature and archive for a *different*, still-genuinely-signed release. Verify that manually: the command above prints a `Trusted comment` line containing a `file:` field — confirm it reads exactly `file:zig-x86_64-linux-<version>.tar.xz`, matching the archive name you requested.

2. Check who operates it, if that's discoverable (project README, DNS WHOIS, whether it's referenced elsewhere in the Zig community). Prefer mirrors run by identifiable people/organizations over anonymous ones.

Then update `.github/zig-mirrors.txt` to match upstream, **and** add the new host to the `plan` job's `harden_runner` `allowed-endpoints` in `release-rust.yml` — `compose_build_matrix` probes reviewed mirrors for liveness before pinning one, and that probe can't reach a host harden-runner hasn't been told about. Commit both together as a normal PR, reviewed the same as any other change to this workflow.
