# Build inputs attestation

Predicate type: `https://github.com/purpleclay/release-workflows/build-inputs/v1`

GitHub's build provenance records which caller workflow ran, but not the `workflow_call` inputs it passed or what they resolved to. `release-rust.yml` and `release-go.yml` sign a second attestation over every release asset that records them. It is signed by the same reusable-workflow identity as the provenance, so `--signer-workflow` applies to it too.

## Predicate

```json
{
  "inputs": { "bin": "release-note", "targets": "[\"x86_64-unknown-linux-musl\"]", "toolchain": "stable", "...": "..." },
  "tools": { "cargo-auditable": "0.7.7", "syft": "v1.54.1" },
  "targets": {
    "x86_64-unknown-linux-musl": {
      "runner": { "image": "ubuntu26", "image-version": "20261005.1", "arch": "X64" },
      "rustc": "rustc 1.90.0 (1159e78c4 2025-09-14)\nbinary: rustc\n...",
      "zig": { "version": "0.17.0", "mirror": "https://zig.example/zig" },
      "cargo-zigbuild": "0.23.4"
    }
  }
}
```

| Field | Meaning |
| --- | --- |
| `inputs` | The `inputs` context exactly as the workflow received it, with defaults applied and `vars.*` or job outputs already resolved. JSON-valued inputs such as `targets` stay strings. |
| `tools` | Tool versions used on every target. Rust: `cargo-auditable`, `syft`. Go: `syft`. |
| `targets.<target>.runner` | The hosted runner image (`ImageOS`, `ImageVersion`) and architecture (`RUNNER_ARCH`) that built the target. |
| `targets.<target>.rustc` | Rust only. `rustc -Vv` output, captured in the checkout before any cargo command runs, so it reflects a `rust-toolchain.toml` override and caller code can't change it. |
| `targets.<target>.go` | Go only. `go version` output, captured with `GOTOOLCHAIN=local` before any module code is downloaded. |
| `targets.<target>.zig`, `cargo-zigbuild` | Rust zigbuild targets only. The Zig version and the reviewed mirror it was fetched from, and the cargo-zigbuild version. |

Go target keys use the `GOOS/GOARCH` form passed in `targets`.

## Reading it

```sh
gh attestation verify <artifact> \
  --repo purpleclay/<project> \
  --signer-workflow purpleclay/release-workflows/.github/workflows/release-<lang>.yml \
  --predicate-type https://github.com/purpleclay/release-workflows/build-inputs/v1 \
  --format json --jq '.[0].verificationResult.statement.predicate'
```

## Versioning

Adding fields is a minor change and keeps `v1`. Renaming or removing a field, or changing its meaning, moves the predicate to `v2`.
