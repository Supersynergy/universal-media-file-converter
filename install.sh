#!/usr/bin/env bash
set -e
echo "==> Installing dependencies..."
brew install exiftool qpdf
CONV_PATH="$HOME/projects/universal-media-file-converter/conv.sh"
SOURCE_LINE="source \"$CONV_PATH\""
if ! grep -qF "$SOURCE_LINE" "$HOME/.zshrc" 2>/dev/null; then
  echo "$SOURCE_LINE" >> "$HOME/.zshrc"
  echo "==> Added to ~/.zshrc"
else
  echo "==> Already in ~/.zshrc"
fi
echo "==> Done! Run: source ~/.zshrc"
