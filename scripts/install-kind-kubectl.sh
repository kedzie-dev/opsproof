#!/usr/bin/env bash
# Install kind without requiring sudo.
#
# Optional environment variables:
#   INSTALL_DIR=/custom/bin        Installation directory (default: ~/.local/bin)
#   KIND_VERSION=v0.31.0           Pin kind instead of downloading the latest release
#   FORCE=1                        Reinstall tools that are already on PATH
set -euo pipefail

install_dir="${INSTALL_DIR:-${HOME}/.local/bin}"
force="${FORCE:-0}"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *)
    echo "Unsupported operating system: $(uname -s). This script supports Linux and macOS." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64 | amd64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *)
    echo "Unsupported CPU architecture: $(uname -m). This script supports amd64 and arm64." >&2
    exit 1
    ;;
esac

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command is missing: $1" >&2
    exit 1
  fi
}

download() {
  local url="$1"
  local destination="$2"

  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "$url" --output "$destination"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet --output-document="$destination" "$url"
  else
    echo "Install curl or wget, then run this script again." >&2
    exit 1
  fi
}

fetch_text() {
  local url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet --output-document=- "$url"
  else
    echo "Install curl or wget, then run this script again." >&2
    exit 1
  fi
}

sha256() {
  local file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    shasum -a 256 "$file" | awk '{print $1}'
  fi
}

install_binary() {
  local name="$1"
  local binary_url="$2"
  local checksum_url="$3"
  local destination="${install_dir}/${name}"
  local temporary_dir binary_file checksum_file expected_checksum actual_checksum

  if [[ "$force" != "1" ]] && command -v "$name" >/dev/null 2>&1; then
    echo "$name is already available at $(command -v "$name"); skipping (set FORCE=1 to reinstall)."
    return
  fi

  temporary_dir="$(mktemp -d)"
  trap 'rm -rf "$temporary_dir"' RETURN
  binary_file="${temporary_dir}/${name}"
  checksum_file="${temporary_dir}/${name}.sha256"

  echo "Downloading ${name}..."
  download "$binary_url" "$binary_file"
  download "$checksum_url" "$checksum_file"

  expected_checksum="$(awk '{print $1}' "$checksum_file")"
  actual_checksum="$(sha256 "$binary_file")"
  if [[ ! "$expected_checksum" =~ ^[A-Fa-f0-9]{64}$ ]] || [[ "$expected_checksum" != "$actual_checksum" ]]; then
    echo "SHA-256 verification failed for ${name}; nothing was installed." >&2
    exit 1
  fi

  mkdir -p "$install_dir"
  cp "$binary_file" "$destination"
  chmod 0755 "$destination"
  echo "Installed ${name} to ${destination}."
}

require_command uname
require_command mktemp
require_command awk
require_command cp
require_command chmod
require_command mkdir
if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
  echo "Install sha256sum or shasum, then run this script again." >&2
  exit 1
fi

kind_version="${KIND_VERSION:-}"
if [[ -z "$kind_version" ]]; then
  kind_version="$(fetch_text https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | awk -F'"' '/"tag_name":/ && !found { print $4; found=1 }')"
fi
if [[ -z "$kind_version" ]]; then
  echo "Could not determine a release version. Set KIND_VERSION explicitly." >&2
  exit 1
fi

install_binary \
  kind \
  "https://kind.sigs.k8s.io/dl/${kind_version}/kind-${os}-${arch}" \
  "https://kind.sigs.k8s.io/dl/${kind_version}/kind-${os}-${arch}.sha256sum"

echo
echo "Verify the installation:"
echo "  kind version"
case ":${PATH}:" in
  *":${install_dir}:"*) ;;
  *)
    echo "Add ${install_dir} to PATH before running make cluster-up:"
    echo "  export PATH=\"${install_dir}:\$PATH\""
    ;;
esac
