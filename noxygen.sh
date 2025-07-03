#!/bin/bash
set -euxo pipefail

DISTRO_NAME="NoxygenOS"
BUILD_DIR="./build"
ISO_OUTPUT_DIR="./iso"
BUILD_SCRIPT="ubuntu-setup.sh"

echo "[*] Starting NoxygenOS ISO build..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./noxygen.sh)"
    exit 1
fi

mkdir -p "$BUILD_DIR" "$ISO_OUTPUT_DIR"

# Clean up previous builds
echo "[*] Cleaning up previous builds..."
rm -rf "$BUILD_DIR"/* "$ISO_OUTPUT_DIR"/* 2>/dev/null || true

# Copy the build script and configs into the build directory
cp "$BUILD_SCRIPT" "$BUILD_DIR/"
cp -r configs "$BUILD_DIR/"

# Make build script executable
chmod +x "$BUILD_DIR/$BUILD_SCRIPT"

# Run the build script
cd "$BUILD_DIR"
./"$BUILD_SCRIPT"

# Move back to original directory
cd ..

echo "✅ ISO ready"
