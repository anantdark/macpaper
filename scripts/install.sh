#!/usr/bin/env bash
# One-shot installer for macpaper via Homebrew.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/anantdark/macpaper/main/scripts/install.sh | bash
set -euo pipefail

TAP="anantdark/macpaper"
FORMULA="macpaper"

if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew is required. Install it from https://brew.sh" >&2
  exit 1
fi

echo "==> Tapping ${TAP}"
brew tap "${TAP}"

echo "==> Trusting ${TAP}"
brew trust "${TAP}"

echo "==> Installing ${FORMULA}"
brew install "${FORMULA}"

echo
echo "Done. Try:  macpaper version"
echo "Help:       macpaper"
