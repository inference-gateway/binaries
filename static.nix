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
    withOpencl = false;
    withCudaLLVM = false;
    withBluray = false;
    withFontconfig = false;
    withFreetype = false;
    withHarfbuzz = false;
    withOpenapv = false;
    withOpenjpeg = false;
    withVulkan = false;
    withSoxr = false;
    withSsh = false;
    withSrt = false;
    withRist = false;
    withGnutls = false;
    withAom = false;
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

  llamaCppTag = "b10621";
  llamaTtsFor = pkgs: pkgs.stdenv.mkDerivation {
    pname = "llama-tts";
    version = llamaCppTag;
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = llamaCppTag;
      sha256 = "10v5xxn4fh5gkhx38dz3adbl68g2dc4jgfx9pbcxbs0dwpwvnnmx";
    };
    nativeBuildInputs = [ pkgs.cmake ];
    cmakeFlags = [
      "-DGGML_NATIVE=OFF"
      "-DBUILD_SHARED_LIBS=OFF"
      "-DLLAMA_BUILD_SERVER=OFF"
      "-DLLAMA_BUILD_EXAMPLES=OFF"
      "-DLLAMA_BUILD_TESTS=OFF"
      "-DLLAMA_BUILD_TOOLS=ON"
    ];
    buildPhase = ''
      cmake --build . -j"$NIX_BUILD_CORES" --target llama-tts
    '';
    installPhase = ''
      install -Dm755 bin/llama-tts $out/bin/llama-tts
    '';
  };

in
{
  whisper-cli = whisperFor ps;
  ffmpeg = ffmpegOverride ps.ffmpeg-headless;
  llama-tts = llamaTtsFor ps;
}
