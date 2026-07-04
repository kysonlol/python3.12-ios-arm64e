#!/usr/bin/env bash
# ==============================================================================
# Script: package-dpkg.sh
# Purpose: Package the staged files into a Debian .deb package for Roothide.
# Requires: WORKDIR, STAGE, PY_VER (set in environment)
# ==============================================================================

set -euxo pipefail

# Load common environment variables
# shellcheck disable=SC1091
source "$(dirname "$0")/common-env.sh"

# ------------------------------------------------------------------------------
# Prepare Package Root
# ------------------------------------------------------------------------------
PKGROOT="$WORKDIR/pkgroot"
mkdir -p "$PKGROOT/DEBIAN"

# ROOTHIDE CHANGE: All jailbreak files must be packed relative to real root paths.
# The Roothide installation framework handles dynamic path mapping automatically.
mv "$STAGE/usr" "$PKGROOT/usr"

# Calculate installed size for control file
INSTALLED_SIZE="$(du -sk "$PKGROOT/usr" | awk '{print $1}')"

# ------------------------------------------------------------------------------
# Generate Control Files
# ------------------------------------------------------------------------------
# Render control file from template, substituting variables
CONTROL_TEMPLATE="$(dirname "$0")/../debian/control.in"
# shellcheck disable=SC2016
sed -e "s#\${PY_VER}#${PY_VER}#g" \
    -e "s#\${INSTALLED_SIZE}#${INSTALLED_SIZE}#g" \
    "$CONTROL_TEMPLATE" > "$PKGROOT/DEBIAN/control"

# Copy changelog to package for package manager integration
CHANGELOG_FILE="$(dirname "$0")/../debian/changelog"
if [ -f "$CHANGELOG_FILE" ]; then
    mkdir -p "$PKGROOT/usr/share/doc/com.k1tty-xz.python3"
    gzip -9 -n -c "$CHANGELOG_FILE" > "$PKGROOT/usr/share/doc/com.k1tty-xz.python3/changelog.gz"
fi

# Copy copyright file (Debian package requirement)
COPYRIGHT_FILE="$(dirname "$0")/../debian/copyright"
if [ -f "$COPYRIGHT_FILE" ]; then
    mkdir -p "$PKGROOT/usr/share/doc/com.k1tty-xz.python3"
    cp "$COPYRIGHT_FILE" "$PKGROOT/usr/share/doc/com.k1tty-xz.python3/copyright"
fi

# ------------------------------------------------------------------------------
# PATH Configuration
# ------------------------------------------------------------------------------
# Create a profile script. For Roothide environments, /usr/local/bin must map safely.
mkdir -p "$PKGROOT/etc/profile.d"
cat > "$PKGROOT/etc/profile.d/python3.sh" <<'EOF'
export PATH="/usr/local/bin:$PATH"
EOF
chmod 0644 "$PKGROOT/etc/profile.d/python3.sh"

# ------------------------------------------------------------------------------
# Build Package
# ------------------------------------------------------------------------------
# ROOTHIDE CHANGE: Updated output filename architecture identifier to iphoneos-arm64e
OUTPUT="python3.12_${PY_VER}-1_iphoneos-arm64e.deb"
dpkg-deb --build --root-owner-group "$PKGROOT" "$WORKDIR/$OUTPUT"

echo "Success: Roothide Package built at $WORKDIR/$OUTPUT"
