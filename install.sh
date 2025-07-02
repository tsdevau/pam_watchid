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

echo "Installing pam_watchid.so..."
git clone --depth 1 "${REPO_URL}" "${TMP_DIR}"
cd "${TMP_DIR}"
make install

LIB_PATH="${LIB_DEST}/pam_watchid.so"
TID_PATH="pam_tid.so"
SUDO_PATH="/etc/pam.d/sudo_local"

# Ensure sudo_local exists
if [ ! -f "${SUDO_PATH}" ]; then
  sudo touch "${SUDO_PATH}"
fi

# Ensure pam_tid.so line is present and uncommented
if ! grep -q "^auth\s\+sufficient\s\+${TID_PATH}" "${SUDO_PATH}"; then
  if grep -q '${TID_PATH}' "${SUDO_PATH}"; then
    sudo sed -i '' "s|^#\?\s*auth\s\+sufficient\s\+${TID_PATH}|auth sufficient ${TID_PATH}|" "${SUDO_PATH}"
  else
    echo "auth sufficient ${TID_PATH}" | sudo tee -a "${SUDO_PATH}" >/dev/null
  fi
fi

# Ensure pam_watchid.so line is present with full path
if ! grep -q "^auth\s\+sufficient\s\+${LIB_PATH}" "${SUDO_PATH}"; then
  if grep -q 'auth\s\+sufficient\s\+\S*pam_watchid\.so' "${SUDO_PATH}"; then
    sudo sed -i '' "s|^#\?\s*auth\s\+sufficient\s\+\S*pam_watchid\.so|auth sufficient ${LIB_PATH}|" "${SUDO_PATH}"
  else
    echo "auth sufficient ${LIB_PATH}" | sudo tee -a "${SUDO_PATH}" >/dev/null
  fi
fi
