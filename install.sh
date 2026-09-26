#!/bin/sh
# Install prebuilt binaries from inference-gateway/binaries into $INSTALL_DIR
# (default ~/.infer/bin/tools), verified against the release's checksums.txt.
# Downloads through gh when it is authenticated, curl otherwise. A binary whose
# sha256 already matches the release is kept; anything else is replaced.
#
#   curl -fsSL https://raw.githubusercontent.com/inference-gateway/binaries/main/install.sh | sh -s -- ffmpeg
#   VERSION=v0.5.0 sh install.sh whisper-cli ffmpeg    # no names = all binaries
set -eu

repo=inference-gateway/binaries
dir=${INSTALL_DIR:-$HOME/.infer/bin/tools}
version=${VERSION:-latest}
[ $# -gt 0 ] || set -- whisper-cli ffmpeg llama-tts

case $(uname -s) in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  MINGW* | MSYS* | CYGWIN*) os=windows ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
case $(uname -m) in
  x86_64 | amd64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
ext=
if [ "$os" = windows ]; then ext=.exe; fi

if command -v gh > /dev/null 2>&1 && gh auth status > /dev/null 2>&1; then
  tag=
  if [ "$version" != latest ]; then tag=$version; fi
  fetch() { gh release download $tag -R "$repo" -p "$1" -O "$2" --clobber; }
else
  base=https://github.com/$repo/releases/latest/download
  if [ "$version" != latest ]; then base=https://github.com/$repo/releases/download/$version; fi
  fetch() { curl -fsSL -o "$2" "$base/$1"; }
fi
sha256() { { sha256sum "$1" 2> /dev/null || shasum -a 256 "$1"; } | cut -d' ' -f1; }

mkdir -p "$dir"
sums=$(fetch checksums.txt -)
for name in "$@"; do
  asset=$name-$os-$arch$ext
  bin=$dir/$name$ext
  want=$(printf '%s\n' "$sums" | awk -v a="$asset" '$2 == a { print $1 }')
  [ -n "$want" ] || { echo "no $asset in $repo ($version)" >&2; exit 1; }
  if [ -f "$bin" ] && [ "$(sha256 "$bin")" = "$want" ]; then
    echo "$bin is up to date"
    continue
  fi
  tmp=$dir/.$name$ext.partial
  fetch "$asset" "$tmp"
  [ "$(sha256 "$tmp")" = "$want" ] || { rm -f "$tmp"; echo "checksum mismatch for $asset" >&2; exit 1; }
  chmod +x "$tmp"
  mv -f "$tmp" "$bin"
  echo "installed $bin ($asset)"
done
