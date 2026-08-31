# binaries

Prebuilt speech binaries — speech-to-text (whisper-cli, ffmpeg) and text-to-speech (llama-tts) — for Linux, macOS, and Windows, auto-downloaded into `~/.infer/bin` by the [Inference Gateway CLI](https://github.com/inference-gateway/cli) (when `speech_to_text.auto_download` is enabled) and by the [Inference Gateway](https://github.com/inference-gateway/inference-gateway)'s local `local/qwen3-tts` speech engine.

Assets are named `<name>-<os>-<arch>` and verified against `checksums.txt` (sha256). `llama-tts` ships for Linux and macOS only.

- **Linux** — Statically linked musl builds via `nix build nixpkgs#pkgsStatic.{whisper-cpp,ffmpeg-headless}`.
- **macOS** — Homebrew-built binaries, ad-hoc signed on native macOS runners.
- **Windows** — Mingw-w64 cross-compiled from Linux via Nix (`pkgsCross.mingwW64.pkgsStatic`).

Dispatching the [Release workflow](.github/workflows/release.yml) runs [semantic-release](https://semantic-release.gitbook.io): the next version is computed from Conventional Commits since the last `vX.Y.Z` tag and published as a new immutable release with freshly built binaries (no commits since the last release → no new release). To refresh binaries against current nixpkgs without other changes, land a `fix: refresh binaries` commit and dispatch. Previously macOS was served only by `$PATH` (`brew install whisper-cpp ffmpeg`); it now ships prebuilt assets like the other platforms.

## Licenses

The binaries are unmodified builds of the corresponding nixpkgs packages; the exact, reproducible build recipe is [`static.nix`](static.nix), which together with [nixpkgs](https://github.com/NixOS/nixpkgs) constitutes the complete corresponding source for every asset.

- `whisper-cli` — [MIT](https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE), © ggml-org / whisper.cpp contributors.
- `llama-tts` — [MIT](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE), © ggml-org / llama.cpp contributors.
- `ffmpeg` — [GPL-3.0](https://www.ffmpeg.org/legal.html) (built with `--enable-gpl --enable-version3`, as reported by `ffmpeg -version`); statically linked components include opus, vorbis, speex, lame, alsa-lib, libxml2, zlib, bzip2, xz under their respective LGPL/BSD-class licenses.
