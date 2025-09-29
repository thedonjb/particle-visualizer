#!/usr/bin/env bash
set -e

GAME_NAME="particle-visualizer"
LOVE_FILE="$GAME_NAME.love"
OUTPUT_DIR="web-output"

rm -rf "$OUTPUT_DIR" "$LOVE_FILE"

echo "[*] Packaging $GAME_NAME into $LOVE_FILE..."
zip -9 -r "$LOVE_FILE" . -x@.gitignore -x '*.git*'

echo "[*] Building web version into $OUTPUT_DIR (compatibility mode for GitHub Pages)..."
love.js -c "$LOVE_FILE" "$OUTPUT_DIR"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "[!] Build failed: $OUTPUT_DIR not created"
    exit 1
fi

echo "[*] Done. To test locally:"
echo "    cd $OUTPUT_DIR && python -m http.server 8000"
