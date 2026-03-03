#!/usr/bin/env bash
# Builds espeak-ng and produces assets/espeak_ng_data.zip for the Flutter package.
# Requires: Docker (or run the cmake/make steps manually on a system with cmake).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ESPEAK_SRC="$PKG_ROOT/third_party/espeak-ng"
OUT_ZIP="$PKG_ROOT/assets/espeak_ng_data.zip"
TEMP_DIR="${TEMP_DIR:-$PKG_ROOT/build/espeak-data}"

if [[ ! -d "$ESPEAK_SRC" ]]; then
  echo "espeak-ng source not found at $ESPEAK_SRC"
  exit 1
fi

mkdir -p "$(dirname "$TEMP_DIR")"

if command -v docker &>/dev/null; then
  echo "Building espeak-ng data using Docker..."
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"
  docker run --rm \
    -v "$ESPEAK_SRC:/src:ro" \
    -v "$TEMP_DIR:/work" \
    ubuntu:22.04 bash -c '
      set -e
      apt-get update -qq && apt-get install -y -qq cmake build-essential git >/dev/null
      cp -r /src /work/src
      cd /work/src
      mkdir -p build && cd build
      cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
      make -j"$(nproc)" data
      cp -r espeak-ng-data /work/
      ls -la /work/espeak-ng-data/
    '
else
  echo "Docker not found. Building locally (requires cmake)..."
  cd "$ESPEAK_SRC"
  mkdir -p build && cd build
  cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
  make -j"$(nproc 2>/dev/null || echo 2)" data
  cp -r espeak-ng-data "$TEMP_DIR/"
fi

if [[ ! -f "$TEMP_DIR/espeak-ng-data/phontab" ]]; then
  echo "Build did not produce phontab at $TEMP_DIR/espeak-ng-data/phontab"
  exit 1
fi

echo "Creating $OUT_ZIP ..."
mkdir -p "$(dirname "$OUT_ZIP")"
(cd "$TEMP_DIR" && zip -r "$OUT_ZIP" espeak-ng-data)
echo "Done. Asset is at $OUT_ZIP"
rm -rf "$TEMP_DIR"
