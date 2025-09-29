#!/usr/bin/env bash
set -e

GAME_NAME="particle-visualizer"
LOVE_FILE="$GAME_NAME.love"

rm -f "$LOVE_FILE"

echo "[*] Packaging $GAME_NAME into $LOVE_FILE (ignoring .git and .gitignore entries)..."
zip -9 -r "$LOVE_FILE" . -x@.gitignore -x '*.git*'

echo "[*] Done. You can run it with:"
echo "    love $LOVE_FILE"
