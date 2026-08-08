# Static (musl) builds of the STT binaries, published as release assets.
# Build:
#   nix build --impure -f static.nix whisper-cli            (Linux amd64/arm64)
#   nix build --impure -f static.nix ffmpeg                 (Linux amd64/arm64)
#   nix build --impure -f static.nix whisper-cli-windows     (Windows amd64)
#
# macOS binaries build from source on native runners; Windows ffmpeg
# cross-compiles from source with mingw-w64 (nixpkgs marks win64 ffmpeg broken).
# Both live in the release workflow, not here.
#
# nixpkgs is pinned to a known-good revision so the release is reproducible;
# tracking nixos-unstable let upstream drift break the build.
#
# Every override below disables an optional feature whose dependency either
# refuses to build statically (badPlatforms isStatic), fails to compile/link
# under musl, or drags a C++ archive into ffmpeg's C link. None are needed:
# whisper-cli only receives pre-converted 16kHz mono WAV from the CLI, and
# the downloaded ffmpeg only does local file-to-file audio conversion
# (no capture devices, network protocols, video encoders, or filters).
let
  flake = builtins.getFlake "github:NixOS/nixpkgs/753cc8a3a87467296ddd1fa93f0cc3e81120ee46";
  ps = flake.legacyPackages.${builtins.currentSystem}.pkgsStatic;

  whisperFor = pkgs: pkgs.whisper-cpp.override {
    withSDL = false;
    withFFmpegSupport = false;
    wget = pkgs.wget.overrideAttrs (_: { doCheck = false; });
  };

  ffmpegOverride = pkg: pkg.override {
    withOpenmpt = false;
    withV4l2 = false;
    withVaapi = false;
    withOpencl = false; # ocl-icd fails to link statically
    withCudaLLVM = false; # tries to build all of LLVM statically, fails
    withBluray = false; # -> fontconfig/python-fonttools build failures
    withFontconfig = false;
    withFreetype = false;
    withHarfbuzz = false;
    withOpenapv = false; # static pkg-config file broken
    withOpenjpeg = false; # -> libtiff -> libwebp -> giflib, fails on x86_64 musl
    withVulkan = false;
    withSoxr = false; # not found by configure; swresample suffices
    withSsh = false;
    withSrt = false;
    withRist = false;
    withGnutls = false; # -> nettle, GOT relocation overflow on aarch64
    withAom = false; # links libvmaf (C++) -> undefined stdc++ refs
    withSvtav1 = false;
    withTheora = false;
    withVpx = false;
    withWebp = false;
    withX264 = false;
    withX265 = false;
    withXvid = false;
    withVidStab = false;
    withZimg = false;
    withZvbi = false;
  };

  win = flake.legacyPackages.${builtins.currentSystem}.pkgsCross.mingwW64.pkgsStatic;
in
{
  whisper-cli = whisperFor ps;
  ffmpeg = ffmpegOverride ps.ffmpeg-headless;

  whisper-cli-windows = whisperFor win;
}
