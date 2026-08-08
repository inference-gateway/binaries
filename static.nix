# Static (musl) builds of the STT binaries, published as release assets.
# Build:
#   nix build --impure -f static.nix whisper-cli            (Linux amd64/arm64)
#   nix build --impure -f static.nix whisper-cli-windows     (Windows amd64)
#   nix build --impure -f static.nix ffmpeg-windows          (Windows amd64)
#
# macOS builds use brew on native macOS runners (not Nix).
#
# Every override below disables an optional feature whose dependency either
# refuses to build statically (badPlatforms isStatic), fails to compile/link
# under musl, or drags a C++ archive into ffmpeg's C link. None are needed:
# whisper-cli only receives pre-converted 16kHz mono WAV from the CLI, and
# the downloaded ffmpeg only does local file-to-file audio conversion
# (no capture devices, network protocols, video encoders, or filters).
let
  flake = builtins.getFlake "github:NixOS/nixpkgs/nixos-unstable";
  ps = flake.legacyPackages.${builtins.currentSystem}.pkgsStatic;

  whisperOverride = pkg: pkg.override {
withSDL = false;
withFFmpegSupport = false;
    wget = pkg.wget.overrideAttrs (_: { doCheck = false; });
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
  whisper-cli = whisperOverride ps.whisper-cpp;
  ffmpeg = ffmpegOverride ps.ffmpeg-headless;

  whisper-cli-windows = whisperOverride win.whisper-cpp;
  ffmpeg-windows = ffmpegOverride win.ffmpeg-headless;
}
