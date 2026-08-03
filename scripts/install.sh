#!/usr/bin/env bash
# One-shot installer for macpaper via Homebrew.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/anantdark/macpaper/refs/heads/main/scripts/install.sh | bash
set -euo pipefail

TAP="anantdark/macpaper"
FORMULA="macpaper"

if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew is required. Install it from https://brew.sh" >&2
  exit 1
fi

echo "==> Tapping ${TAP}"
brew tap "${TAP}" </dev/null

echo "==> Trusting ${TAP}"
brew trust "${TAP}" </dev/null

echo "==> Installing ${FORMULA}"
# Close stdin: when this script is piped via `curl | bash`, brew would otherwise
# consume the remaining script lines as stdin and skip the trailing echoes.
brew install "${FORMULA}" </dev/null

echo
echo "Done. Try:  macpaper version"
echo "Help:       macpaper"

# v1.4.1 installer
