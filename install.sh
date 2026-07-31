#!/usr/bin/env bash
#
# Leviath installer for Linux and macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/GEMISIS/leviath-dist/main/install.sh | bash
# Usage: curl -fsSL https://raw.githubusercontent.com/GEMISIS/leviath-dist/main/install.sh | bash -s -- --channel alpha
#
set -euo pipefail

# Defaults
CHANNEL="alpha"
REPO="GEMISIS/leviath"
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
CHECKSUM_NAME="SHA256SUMS"

info "Channel: ${CHANNEL}"
info "Detected platform: ${PLATFORM}-${ARCH_SUFFIX}"

# Check for required tools
for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || err "'$cmd' is required but not found"
done

# A SHA-256 tool is required, not optional: an unverified binary is not
# installed. `sha256sum` ships with coreutils on Linux; macOS has `shasum`.
if command -v sha256sum >/dev/null 2>&1; then
    sha256_of() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
    sha256_of() { shasum -a 256 "$1" | awk '{print $1}'; }
else
    err "neither 'sha256sum' nor 'shasum' was found, so the download cannot be verified. Install coreutils and re-run."
fi

# Determine release tag
case "$CHANNEL" in
  alpha)  RELEASE_TAG="alpha" ;;
  beta)   RELEASE_TAG="beta" ;;
  stable) RELEASE_TAG="latest" ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Shared curl options. `--proto '=https'` refuses to speak anything but HTTPS
# even if a URL somewhere says otherwise, and `--tlsv1.2` refuses a downgrade;
# both matter because this script is what a user trusts to fetch a binary they
# are about to run.
CURL_OPTS=(--proto '=https' --tlsv1.2 -fsSL --retry 3 --retry-connrefused)

# Authentication, kept out of the process arguments. A token passed as
# `-H "Authorization: ..."` is visible in `ps` to every other user on the
# machine for as long as curl runs; a config file readable only by its owner is
# not.
AUTH_OPTS=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_CONFIG="${TMPDIR}/curlrc"
    (umask 077; printf 'header = "Authorization: token %s"\n' "$GITHUB_TOKEN" > "$AUTH_CONFIG")
    AUTH_OPTS=(--config "$AUTH_CONFIG")
fi

# Get release info
info "Fetching ${CHANNEL} release..."

RELEASE_URL="https://api.github.com/repos/${REPO}/releases/tags/${RELEASE_TAG}"
if [ ${#AUTH_OPTS[@]} -gt 0 ]; then
    RELEASE_JSON="$(curl "${CURL_OPTS[@]}" "${AUTH_OPTS[@]}" "$RELEASE_URL" 2>/dev/null)" || err "Failed to fetch release info. Is GITHUB_TOKEN set and valid?"
else
    RELEASE_JSON="$(curl "${CURL_OPTS[@]}" "$RELEASE_URL" 2>/dev/null)" || err "Failed to fetch release info. Check your network, or https://github.com/${REPO}/releases for the channel's status."
fi

TAG="$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"
[ -n "$TAG" ] || err "Could not determine release tag"

info "Release tag: ${TAG}"

# Resolve an asset's download URL by name.
#
# Private repos: browser_download_url returns 404 even WITH a token — assets
# must be fetched through the API asset endpoint (releases/assets/<id>) with
# Accept: application/octet-stream. Public repos can use the plain URL.
asset_url() {
    local want="$1"
    if [ ${#AUTH_OPTS[@]} -gt 0 ]; then
        echo "$RELEASE_JSON" | awk -v name="$want" '
            /"url": *"[^"]*\/releases\/assets\// { url=$0; sub(/.*"url": *"/, "", url); sub(/".*/, "", url) }
            /"name": *"/ { n=$0; sub(/.*"name": *"/, "", n); sub(/".*/, "", n); if (n == name && url != "") { print url; exit } }
        '
    else
        echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$want" | head -1 | sed 's/.*"browser_download_url": *"//;s/".*//'
    fi
}

# Every URL taken out of the release JSON is checked before curl sees it.
# Defence in depth: the JSON arrives over HTTPS from GitHub, so tampering here
# implies a compromise that has bigger consequences — but a one-line check costs
# nothing and keeps a malformed or redirected value from becoming a fetch to
# somewhere else entirely.
require_github_https() {
    case "$1" in
        https://api.github.com/*|https://github.com/*|https://objects.githubusercontent.com/*|https://release-assets.githubusercontent.com/*) ;;
        *) err "refusing to download from an unexpected URL: $1" ;;
    esac
}

DOWNLOAD_URL="$(asset_url "$ASSET_NAME")"
[ -n "$DOWNLOAD_URL" ] || err "No release asset found for ${ASSET_NAME}. Check available assets at https://github.com/${REPO}/releases"
require_github_https "$DOWNLOAD_URL"

CHECKSUM_URL="$(asset_url "$CHECKSUM_NAME")"
[ -n "$CHECKSUM_URL" ] || err "This release publishes no ${CHECKSUM_NAME}, so the download cannot be verified. Refusing to install."
require_github_https "$CHECKSUM_URL"

info "Downloading ${ASSET_NAME}..."
# ${arr[@]+...} keeps `set -u` on macOS's bash 3.2 from treating an *empty*
# array (the tokenless case) as an unbound variable.
curl "${CURL_OPTS[@]}" ${AUTH_OPTS[@]+"${AUTH_OPTS[@]}"} -H "Accept: application/octet-stream" -o "${TMPDIR}/${ASSET_NAME}" "$DOWNLOAD_URL"

info "Downloading ${CHECKSUM_NAME}..."
curl "${CURL_OPTS[@]}" ${AUTH_OPTS[@]+"${AUTH_OPTS[@]}"} -H "Accept: application/octet-stream" -o "${TMPDIR}/${CHECKSUM_NAME}" "$CHECKSUM_URL"

# Verify before unpacking, and refuse to continue on any doubt.
#
# What this does and does not buy: the checksum comes from the same release as
# the archive, so it does not protect against someone who can rewrite the whole
# release — that needs a signature checked against a trusted identity, which is
# tracked separately. It does catch a corrupted or truncated download, a
# tampered or swapped *asset*, and a cache or mirror serving something else,
# which is the class this installer could previously not detect at all.
info "Verifying checksum..."
EXPECTED="$(awk -v n="$ASSET_NAME" '$2 == n { print $1; exit }' "${TMPDIR}/${CHECKSUM_NAME}")"
[ -n "$EXPECTED" ] || err "${CHECKSUM_NAME} has no entry for ${ASSET_NAME}. Refusing to install."

ACTUAL="$(sha256_of "${TMPDIR}/${ASSET_NAME}")"
if [ "$ACTUAL" != "$EXPECTED" ]; then
    err "checksum mismatch for ${ASSET_NAME}.
  expected: ${EXPECTED}
  actual:   ${ACTUAL}
This means the file you received is not the one that was published. Do not
install it. Re-run to retry, and report it if it persists."
fi
ok "Checksum verified (${EXPECTED})"

info "Extracting..."
tar xzf "${TMPDIR}/${ASSET_NAME}" -C "$TMPDIR"

# Find the binary
LEV_BIN="$(find "$TMPDIR" -name "$BINARY_NAME" -type f | head -1)"
[ -n "$LEV_BIN" ] || err "Binary '${BINARY_NAME}' not found in archive"
chmod +x "$LEV_BIN"

# Install
# `install` rather than `mv`: the temp dir and ${INSTALL_DIR} are usually
# different filesystems, so `mv` is a copy followed by an unlink — an
# interruption partway leaves a truncated `lev` on PATH. `install` writes to a
# temporary name and renames, and sets the mode explicitly rather than inheriting
# whatever the archive carried.
if [ -w "$INSTALL_DIR" ]; then
    install -m 755 "$LEV_BIN" "${INSTALL_DIR}/${BINARY_NAME}"
else
    info "Installing to ${INSTALL_DIR} (requires sudo)..."
    sudo install -m 755 "$LEV_BIN" "${INSTALL_DIR}/${BINARY_NAME}"
fi

ok "Leviath (${CHANNEL}) installed to ${INSTALL_DIR}/${BINARY_NAME}"
echo ""
echo "Get started:"
echo "  lev setup        # configure an LLM provider"
echo "  lev run coder --task \"Your task here\""
echo ""
