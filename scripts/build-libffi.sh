#!/usr/bin/env bash
# ==============================================================================
# Script: build-libffi.sh
# Purpose: Cross-compile libffi for iOS arm64e (Roothide)
# ==============================================================================

set -euxo pipefail

# Load common environment variables
source "$(dirname "$0")/common-env.sh"

# Ensure we have our workspace directories ready
DEPS_SRC="$WORKDIR/deps/src"
DEPS_BUILD="$WORKDIR/deps/build/libffi"
DEPS_DIST="$WORKDIR/deps/libffi-ios"

mkdir -p "$DEPS_SRC" "$DEPS_BUILD" "$DEPS_DIST"

# 1. Download and extract libffi source if missing
LIBFFI_DIR="$DEPS_SRC/libffi-$LIBFFI_VER"
if [ ! -d "$LIBFFI_DIR" ]; then
    echo "Downloading libffi v$LIBFFI_VER..."
    curl -L "https://github.com" -o "$DEPS_SRC/libffi.tar.gz"
    tar -xf "$DEPS_SRC/libffi.tar.gz" -C "$DEPS_SRC"
fi

cd "$LIBFFI_DIR"

# Strip conflicting CFI directives from the assembly file before compilation
sed -i '' 's/\.cfi_.*//g' src/aarch64/sysv.S

# 2. ROOTHIDE / ARM64E ADJUSTMENT: Clean out previous build states
make clean || true
make distclean || true

# 3. Configure the source code for cross-compilation
# We explicitly map the host to arm64e so it matches the GitHub workflow.
echo "Configuring libffi for arm64e..."
./configure \
    --host="$HOST_TRIPLE" \
    --prefix="$DEPS_DIST" \
    --enable-static \
    --disable-shared \
    --with-pic

# 4. Build and install locally inside the workspace destination
make -j"$JOBS"
make install

echo "Success: libffi compiled for arm64e."
# force change
