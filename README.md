# binaries

Prebuilt speech binaries - speech-to-text (whisper-cli, ffmpeg) and text-to-speech (llama-tts) - for Linux, macOS, and Windows, auto-downloaded into `~/.infer/bin` by the [Inference Gateway CLI](https://github.com/inference-gateway/cli) (when `speech_to_text.auto_download` is enabled) and by the [Inference Gateway](https://github.com/inference-gateway/inference-gateway)'s local `local/qwen3-tts` speech engine.

Assets are named `<name>-<os>-<arch>` and verified against `checksums.txt` (sha256).

- **Linux** - Statically linked musl builds via `nix build nixpkgs#pkgsStatic.{whisper-cpp,ffmpeg-headless}`.
- **macOS** - Homebrew-built binaries, ad-hoc signed on native macOS runners.
- **Windows** - Mingw-w64 cross-compiled from Linux via Nix (`pkgsCross.mingwW64.pkgsStatic`).

`ffmpeg` macOS/Windows builds additionally cover video for the Desktop's content projects: they decode h264, hevc, prores, mjpeg, png, vp8/vp9 and mpeg4, write image sequences, mix/normalize audio (`adelay`, `amix`, `apad`, `volume`, `loudnorm`, …), and mux mp4/mov. No `ffprobe` - probe with `ffmpeg -i`. The Linux build (nixpkgs `ffmpeg-headless`) already covers all of this.

`ffmpeg` also records the screen for the CLI's `RecordStart` tool: every build includes the `libx264` H.264 encoder and the platform screen grabber (`avfoundation` on macOS, `gdigrab` on Windows, `x11grab` on Linux). It is the only video encoder; other consumers stream-copy video.

Dispatching the [Release workflow](.github/workflows/release.yml) runs [semantic-release](https://semantic-release.gitbook.io): the next version is computed from Conventional Commits since the last `vX.Y.Z` tag and published as a new immutable release with freshly built binaries (no commits since the last release → no new release). To refresh binaries against current nixpkgs without other changes, land a `fix: refresh binaries` commit and dispatch. Previously macOS was served only by `$PATH` (`brew install whisper-cpp ffmpeg`); it now ships prebuilt assets like the other platforms.

## Licenses

The binaries are unmodified builds of the corresponding nixpkgs packages; the exact, reproducible build recipe is [`static.nix`](static.nix), which together with [nixpkgs](https://github.com/NixOS/nixpkgs) constitutes the complete corresponding source for every asset.

- `whisper-cli` - [MIT](https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE), © ggml-org / whisper.cpp contributors.
- `llama-tts` - [MIT](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE), © ggml-org / llama.cpp contributors.
- `ffmpeg` - [GPL](https://www.ffmpeg.org/legal.html): Linux builds are GPL-3.0 (built with `--enable-gpl --enable-version3`, as reported by `ffmpeg -version`); macOS/Windows builds are GPL-2.0-or-later (`--enable-gpl`), configured from FFmpeg source by [`build.yml`](.github/workflows/build.yml). All builds statically link [x264](https://code.videolan.org/videolan/x264) (GPL-2.0-or-later, `stable` branch); other statically linked components include opus, vorbis, speex, lame, alsa-lib, libxcb, libxml2, zlib, bzip2, xz under their respective LGPL/BSD-class licenses.
