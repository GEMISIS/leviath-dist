#!/usr/bin/env bash
#
# Leviath installer for Linux and macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/Sun-Forge-AI/leviath-dist/main/install.sh | bash
# Usage: curl -fsSL https://raw.githubusercontent.com/Sun-Forge-AI/leviath-dist/main/install.sh | bash -s -- --channel alpha
#
set -euo pipefail

# Defaults
CHANNEL="alpha"
REPO="Sun-Forge-AI/leviath"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="lev"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)
      CHANNEL="$2"
      shift 2
      ;;
    --channel=*)
      CHANNEL="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate channel
case "$CHANNEL" in
  alpha|beta|stable) ;;
  *) echo "error: invalid channel '$CHANNEL'. Use: alpha, beta, or stable"; exit 1 ;;
esac

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}==>${NC} $*"; }
ok()    { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}==>${NC} $*"; }
err()   { echo -e "${RED}error:${NC} $*" >&2; exit 1; }

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux)  PLATFORM="linux" ;;
    Darwin) PLATFORM="macos" ;;
    *)      err "Unsupported OS: $OS. Use Windows instructions from the README." ;;
esac

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)   ARCH_SUFFIX="x64" ;;
    aarch64|arm64)   ARCH_SUFFIX="arm64" ;;
    *)               err "Unsupported architecture: $ARCH" ;;
esac

ASSET_NAME="leviath-${PLATFORM}-${ARCH_SUFFIX}.tar.gz"

info "Channel: ${CHANNEL}"
info "Detected platform: ${PLATFORM}-${ARCH_SUFFIX}"

# Check for required tools
for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || err "'$cmd' is required but not found"
done

# Determine release tag
case "$CHANNEL" in
  alpha)  RELEASE_TAG="alpha" ;;
  beta)   RELEASE_TAG="beta" ;;
  stable) RELEASE_TAG="latest" ;;
esac

# Get release info
info "Fetching ${CHANNEL} release..."

# Try authenticated first (for private repos), fall back to unauthenticated
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
else
    AUTH_HEADER=""
fi

RELEASE_URL="https://api.github.com/repos/${REPO}/releases/tags/${RELEASE_TAG}"
if [ -n "$AUTH_HEADER" ]; then
    RELEASE_JSON="$(curl -fsSL -H "$AUTH_HEADER" "$RELEASE_URL" 2>/dev/null)" || err "Failed to fetch release info. Is GITHUB_TOKEN set and valid?"
else
    RELEASE_JSON="$(curl -fsSL "$RELEASE_URL" 2>/dev/null)" || err "Failed to fetch release info. For private repos, set GITHUB_TOKEN."
fi

TAG="$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"
[ -n "$TAG" ] || err "Could not determine release tag"

info "Release tag: ${TAG}"

# Find the download URL for our asset.
# Private repos: browser_download_url returns 404 even WITH a token — assets
# must be fetched through the API asset endpoint (releases/assets/<id>) with
# Accept: application/octet-stream. Public repos can use the plain URL.
if [ -n "$AUTH_HEADER" ]; then
    DOWNLOAD_URL="$(echo "$RELEASE_JSON" | awk -v name="$ASSET_NAME" '
        /"url": *"[^"]*\/releases\/assets\// { url=$0; sub(/.*"url": *"/, "", url); sub(/".*/, "", url) }
        /"name": *"/ { n=$0; sub(/.*"name": *"/, "", n); sub(/".*/, "", n); if (n == name && url != "") { print url; exit } }
    ')"
else
    DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$ASSET_NAME" | head -1 | sed 's/.*"browser_download_url": *"//;s/".*//')"
fi
[ -n "$DOWNLOAD_URL" ] || err "No release asset found for ${ASSET_NAME}. Check available assets at https://github.com/${REPO}/releases"

# Download and extract
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

info "Downloading ${ASSET_NAME}..."
if [ -n "$AUTH_HEADER" ]; then
    curl -fsSL -H "$AUTH_HEADER" -H "Accept: application/octet-stream" -o "${TMPDIR}/${ASSET_NAME}" "$DOWNLOAD_URL"
else
    curl -fsSL -o "${TMPDIR}/${ASSET_NAME}" "$DOWNLOAD_URL"
fi

info "Extracting..."
tar xzf "${TMPDIR}/${ASSET_NAME}" -C "$TMPDIR"

# Find the binary
LEV_BIN="$(find "$TMPDIR" -name "$BINARY_NAME" -type f | head -1)"
[ -n "$LEV_BIN" ] || err "Binary '${BINARY_NAME}' not found in archive"
chmod +x "$LEV_BIN"

# Install
if [ -w "$INSTALL_DIR" ]; then
    mv "$LEV_BIN" "${INSTALL_DIR}/${BINARY_NAME}"
else
    info "Installing to ${INSTALL_DIR} (requires sudo)..."
    sudo mv "$LEV_BIN" "${INSTALL_DIR}/${BINARY_NAME}"
fi

ok "Leviath (${CHANNEL}) installed to ${INSTALL_DIR}/${BINARY_NAME}"
echo ""
echo "Get started:"
echo "  lev setup        # configure an LLM provider"
echo "  lev run coder --task \"Your task here\""
echo ""
