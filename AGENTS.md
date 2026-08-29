# AGENTS.md

This repo publishes prebuilt speech-to-text binaries (`whisper-cli`, `ffmpeg`) as GitHub release assets, auto-downloaded by the Inference Gateway CLI. There is no application code to build, test, or lint — the "product" is the release pipeline. See `README.md` for what the binaries are and their licenses.

## Build

Linux binaries build locally via Nix (musl, static):

```sh
nix build --impure -f static.nix whisper-cli   # linux amd64/arm64
nix build --impure -f static.nix ffmpeg
```

macOS and Windows binaries are **not** built from `static.nix` — they build from source on their runners inside `.github/workflows/release.yml` (Homebrew on macOS, mingw-w64 cross-compile on Linux for Windows). Do not try to reproduce them locally.

`static.nix` pins nixpkgs to a known-good revision (`builtins.getFlake "github:NixOS/nixpkgs/<rev>"`). Do not bump it casually; upstream drift breaks the static build. Every `with* = false` override disables an optional feature whose dependency fails to build statically — read the comments before touching them.

## Releasing

Releases are fully automated. Dispatching the **Release** workflow runs semantic-release, which:

- computes the next version from Conventional Commits since the last `vX.Y.Z` tag,
- builds all assets, and
- publishes an immutable release.

No commits since the last release → no new release. To refresh binaries against current nixpkgs without other changes, land a `fix: refresh binaries` commit and dispatch.

## Conventions

- **Commit messages must be Conventional Commits** (`feat:`, `fix:`, `chore:`, …). The version bump is derived from them (see `releaseRules` in `.releaserc.json`). A `fix:`/`chore:` is a patch; `feat:` is a minor; `breaking: true` is a minor.
- Assets are named `<name>-<os>-<arch>` (e.g. `whisper-cli-darwin-arm64`, `ffmpeg-windows-amd64.exe`) and verified against `dist/checksums.txt` (sha256). The asset list in `.releaserc.json` must stay in sync with what `release.yml` produces.
- Releases are immutable — never edit or re-upload an existing release; land a fix commit and dispatch a new one.

## Gotchas

- `whisper-cli` only receives pre-converted 16 kHz mono WAV; `ffmpeg` only does local file-to-file audio conversion. No capture devices, network protocols, or video encoders are needed — don't re-enable disabled features.
- macOS binaries are ad-hoc signed on native runners; Windows builds need bash on the host, which is why they cross-compile from Linux rather than via nixpkgs.
