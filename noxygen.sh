#!/bin/bash
set -euxo pipefail

DISTRO_NAME="NoxygenOS"
BUILD_DIR="./build"
ISO_OUTPUT_DIR="./iso"
BUILD_SCRIPT="docker.sh"

mkdir -p "$BUILD_DIR"

# Cleanup to avoid conflicts (use Docker to clean root-owned files)
docker run --rm --privileged --platform linux/amd64 -v "$(pwd)/$BUILD_DIR":/build -w /build archlinux:latest sh -c "chmod -R 777 work/ out/ airootfs/ build/ cache/ 2>/dev/null || true; rm -rf work/ out/ airootfs/ build/ cache/" 2>/dev/null || true
# Also ensure the build directory is completely clean
find "$BUILD_DIR" -name "*.pkg.tar*" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "*.log" -delete 2>/dev/null || true

# Copy the build script and configs into the build directory
cp "$BUILD_SCRIPT" "$BUILD_DIR/"
cp -r configs "$BUILD_DIR/"

# Ensure we start with a completely fresh Docker environment
echo "Pulling latest Arch Linux Docker image..."
docker pull --platform linux/amd64 archlinux:latest

# Clean any existing containers that might have artifacts
docker container prune -f

# Run the build script inside the Docker container
docker run --rm --privileged --platform linux/amd64 -v "$(pwd)/$BUILD_DIR":/build -w /build archlinux:latest bash "$BUILD_SCRIPT"

# Move the ISO to Desktop
ISO_FILE=$(ls "$ISO_OUTPUT_DIR"/archlinux-*.iso | head -n1)
mv "$ISO_FILE" "$HOME/Desktop/${DISTRO_NAME}.iso"
echo "✅ ISO ready: $HOME/Desktop/${DISTRO_NAME}.iso"
