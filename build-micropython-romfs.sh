#!/bin/bash

# === CONFIG ===
PROJECT_DIR="/mnt/d/git/micropython"
FROZEN_DIR="myapp"
MANIFEST="manifest.py"
BOARD="ESP32_GENERIC"

# === Ensure project and frozen dirs exist ===
if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Project directory not found: $PROJECT_DIR"
  exit 1
fi

mkdir -p "$PROJECT_DIR/$FROZEN_DIR"

# === START DOCKER (WSL/Linux) ===
echo "🔄 Starting Docker (if needed)..."
sudo service docker start 2>/dev/null || echo "⚠️  Docker may already be running."

# === CREATE MANIFEST ===
echo "📝 Generating $MANIFEST for frozen dir '$FROZEN_DIR'..."
echo "freeze('$FROZEN_DIR')" > "$PROJECT_DIR/$MANIFEST"

# === FETCH GIT SUBMODULES ON HOST ===
echo "📦 Updating submodules on host..."
make -C "$PROJECT_DIR/ports/esp32" BOARD=$BOARD submodules

# === RUN DOCKER TO BUILD ===
echo "🚀 Building MicroPython with ROMFS..."
docker run --rm -it \
  -v "$PROJECT_DIR":/project \
  -w /project \
  -u 1000 \
  -e HOME=/tmp \
  espressif/idf:v5.2.3 bash -c "
    set -e
    echo '🛠️  Loading ESP-IDF...'
    . /opt/esp/idf/export.sh

    echo '🧹 Cleaning old mpy-cross (if needed)...'
    make -C mpy-cross clean || true

    echo '⚙️  Building mpy-cross...'
    make -C mpy-cross

    echo '🚧 Building MicroPython firmware...'
    cd ports/esp32
    rm -rf build-ESP32_GENERIC
    make BOARD=ESP32_GENERIC FROZEN_MANIFEST=../../../$MANIFEST
  "


# === DONE ===
FIRMWARE="$PROJECT_DIR/ports/esp32/build-$BOARD/firmware.bin"
if [ -f "$FIRMWARE" ]; then
  echo "✅ Build complete!"
  echo "➡️  Firmware located at: $FIRMWARE"
else
  echo "❌ Build failed — firmware not found."
fi




