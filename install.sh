#!/bin/sh

set -e

LIB_DEST="/usr/local/lib/pam"
REPO_URL="https://github.com/tsdevau/pam_watchid.git"
TMP_DIR="$(mktemp -d)"
FORCE=0

# Parse args
if [ "$1" = "--force" ]; then
  FORCE=1
fi

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

# Pre-read the installed version (if it exists)
INSTALLED_LIB="$(find "${LIB_DEST}" -name 'pam_watchid.so.*' | sort | tail -n 1)"

if [ "${FORCE}" -eq 0 ] && [ -n "${INSTALLED_LIB}" ]; then
  echo "Library already installed at ${INSTALLED_LIB}. Use --force to reinstall."
  exit 0
fi

echo "Installing pam-watchid..."
git clone --depth 1 "${REPO_URL}" "${TMP_DIR}"
cd "${TMP_DIR}"
make install

VERSION="$(cat VERSION)"
LIB_PATH="${LIB_DEST}/pam_watchid.so.${VERSION}"

# Ensure sudo_local exists
if [ ! -f "/etc/pam.d/sudo_local" ]; then
  sudo touch "/etc/pam.d/sudo_local"
fi

# Ensure pam_tid.so line is present and uncommented
if ! grep -q '^auth\s\+sufficient\s\+pam_tid.so' /etc/pam.d/sudo_local; then
  if grep -q 'pam_tid.so' /etc/pam.d/sudo_local; then
    sudo sed -i '' 's/^#\?\s*auth\s\+sufficient\s\+pam_tid.so/auth sufficient pam_tid.so/' /etc/pam.d/sudo_local
  else
    echo 'auth sufficient pam_tid.so' | sudo tee -a /etc/pam.d/sudo_local >/dev/null
  fi
fi

# Ensure pam_watchid.so line is present with full path
if ! grep -q "^auth\s\+sufficient\s\+${LIB_PATH}" /etc/pam.d/sudo_local; then
  if grep -q 'pam_watchid.so' /etc/pam.d/sudo_local; then
    sudo sed -i '' "s|^#\?\s*auth\s\+sufficient\s\+pam_watchid.so|auth sufficient ${LIB_PATH}|" /etc/pam.d/sudo_local
  else
    echo "auth sufficient ${LIB_PATH}" | sudo tee -a /etc/pam.d/sudo_local >/dev/null
  fi
fi
