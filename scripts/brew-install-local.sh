#!/usr/bin/env bash
# Build a local tarball and brew-install macpaper via a local tap.
# Homebrew 6+ rejects loose formula files; they must live in a tap.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(python3 -c "import pathlib,re; t=pathlib.Path('$ROOT/macpaper').read_text(); print(re.search(r'__version__ = \"([^\"]+)\"', t).group(1))")"
NAME="macpaper-${VERSION}"
TAP_USER="local"
TAP_NAME="macpaper"
TAP="${TAP_USER}/${TAP_NAME}"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/macpaper-brew.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

echo "==> Staging ${NAME}"
mkdir -p "${STAGE}/${NAME}"
cp "${ROOT}/macpaper" "${STAGE}/${NAME}/macpaper"
chmod 0755 "${STAGE}/${NAME}/macpaper"
cp -R "${ROOT}/helpers" "${STAGE}/${NAME}/helpers"
cp "${ROOT}/README.md" "${ROOT}/LICENSE" "${STAGE}/${NAME}/"
find "${STAGE}/${NAME}" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true

TAR="${STAGE}/${NAME}.tar.gz"
# Keep the archive outside the temp dir that we delete — brew caches by url.
CACHE_DIR="${HOME}/Library/Caches/macpaper-brew"
mkdir -p "${CACHE_DIR}"
TAR_PERSIST="${CACHE_DIR}/${NAME}.tar.gz"
tar -C "${STAGE}" -czf "${TAR_PERSIST}" "${NAME}"
SHA="$(shasum -a 256 "${TAR_PERSIST}" | awk '{print $1}')"
echo "==> sha256 ${SHA}"
echo "==> archive ${TAR_PERSIST}"

# Ensure local tap exists
if ! brew tap-info "${TAP}" &>/dev/null; then
  echo "==> Creating tap ${TAP}"
  brew tap-new "${TAP}" --no-git
fi

TAP_PATH="$(brew --repo "${TAP}")"
FORMULA_PATH="${TAP_PATH}/Formula/macpaper.rb"
mkdir -p "${TAP_PATH}/Formula"

python3 - <<PY
from pathlib import Path
src = Path("${ROOT}/Formula/macpaper.rb").read_text()
tar = Path("${TAR_PERSIST}").resolve().as_uri()
sha = "${SHA}"
ver = "${VERSION}"
out = []
for line in src.splitlines(keepends=True):
    if line.lstrip().startswith("url "):
        out.append(f'  url "{tar}"\n')
    elif line.lstrip().startswith("sha256 "):
        out.append(f'  sha256 "{sha}"\n')
    elif line.lstrip().startswith("version "):
        out.append(f'  version "{ver}"\n')
    else:
        out.append(line)
Path("${FORMULA_PATH}").write_text("".join(out))
print(f"==> Wrote {Path('${FORMULA_PATH}')}")
PY

echo "==> brew install ${TAP}/macpaper"
# Reinstall if already present from a previous local build
if brew list --formula macpaper &>/dev/null; then
  brew reinstall "${TAP}/macpaper"
else
  brew install "${TAP}/macpaper"
fi

echo
echo "Installed. Try:  macpaper version"
echo "Uninstall:       brew uninstall macpaper"
echo "Untap:           brew untap ${TAP}"
