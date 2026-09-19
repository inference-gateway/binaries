# AGENTS.md

This repo publishes prebuilt speech binaries (`whisper-cli`, `ffmpeg` for speech-to-text; `llama-tts` for text-to-speech) as GitHub release assets, auto-downloaded by the Inference Gateway CLI and by the gateway's local speech engine. There is no application code to build, test, or lint — the "product" is the release pipeline. See `README.md` for what the binaries are and their licenses.

## Build

Linux binaries build locally via Nix (musl, static):

```sh
nix build --impure -f static.nix whisper-cli   # linux amd64/arm64
nix build --impure -f static.nix ffmpeg
nix build --impure -f static.nix llama-tts
```

macOS and Windows binaries are **not** built from `static.nix` — `.github/workflows/build.yml` builds them from source on their runners (cmake/nasm via Homebrew on macOS; llvm-mingw for `whisper-cli`/`llama-tts` and gcc-mingw-w64 for `ffmpeg`, cross-compiled on Linux for Windows). Do not try to reproduce them locally. Dispatch the **Build** workflow to test build changes: it runs the per-binary matrix with a sanity-check step (static/self-contained/PE) and uploads artifacts without publishing.

`static.nix` pins nixpkgs to a known-good revision (`builtins.getFlake "github:NixOS/nixpkgs/<rev>"`). Do not bump it casually; upstream drift breaks the static build. Every `with* = false` override disables an optional feature whose dependency fails to build statically — don't re-enable them.

## Releasing

Releases are fully automated. Dispatching the **Release** workflow runs semantic-release, which:

- computes the next version from Conventional Commits since the last `vX.Y.Z` tag,
- builds all assets via the `build.yml` matrix, and
- publishes an immutable release.

No commits since the last release → no new release. To refresh binaries against current nixpkgs without other changes, land a `fix: refresh binaries` commit and dispatch.

## Conventions

- **Commit messages must be Conventional Commits** (`feat:`, `fix:`, `chore:`, …). The version bump is derived from them (see `releaseRules` in `.releaserc.json`). A `fix:`/`chore:` is a patch; `feat:` is a minor; `breaking: true` is a minor.
- Assets are named `<name>-<os>-<arch>` (e.g. `whisper-cli-darwin-arm64`, `ffmpeg-windows-amd64.exe`) and verified against `dist/checksums.txt` (sha256). The asset list in `.releaserc.json` must stay in sync with what `release.yml` produces.
- Releases are immutable — never edit or re-upload an existing release; land a fix commit and dispatch a new one.

## Gotchas

- `whisper-cli` only receives pre-converted 16 kHz mono WAV; `ffmpeg` only does local file-to-file audio conversion. No capture devices, network protocols, or video encoders are needed — don't re-enable disabled features.
- macOS binaries are built from source, ad-hoc signed, and must stay self-contained (system libs only — enforced by the `otool -L` sanity check, which is why llama.cpp builds with `LLAMA_OPENSSL=OFF` on macOS). Windows builds cross-compile from Linux rather than via nixpkgs.
- `llama-tts`'s static build deliberately disables the server, examples, tests, and dynamic CPU dispatch (`GGML_NATIVE=OFF`). Windows builds via the same llvm-mingw toolchain as whisper-cli.
- `llama-tts` pins its own llama.cpp tag (`b10621`, set in `static.nix` and hardcoded in `build.yml`'s macOS and Windows steps) instead of nixpkgs' `llama-cpp` src: the nixpkgs pin predates `--tts-lang`/Qwen3-TTS. Bump all three together.
