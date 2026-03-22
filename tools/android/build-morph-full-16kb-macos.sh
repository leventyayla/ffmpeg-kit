#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: tools/android/build-morph-full-16kb-macos.sh"
  echo
  echo "Builds Morph full-GPL Android AAR (all ABIs, 16KB-compatible) on macOS."
  echo "The script installs/updates Android NDK+platform via sdkmanager and then runs the local full build."
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS (Darwin)." >&2
  exit 1
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ANDROID_SDK_ROOT_DEFAULT="${HOME}/Library/Android/sdk"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT_DEFAULT}}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT}}"
export ANDROID_NDK_VERSION="${ANDROID_NDK_VERSION:-27.2.12479018}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}}"

SDKMANAGER="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x "${SDKMANAGER}" ]]; then
  echo "Missing sdkmanager at ${SDKMANAGER}" >&2
  echo "Install Android command line tools and place them under:" >&2
  echo "  ${ANDROID_SDK_ROOT}/cmdline-tools/latest/" >&2
  exit 1
fi

echo "Using ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
echo "Using ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}"

yes | "${SDKMANAGER}" --licenses >/dev/null 2>&1 || true
"${SDKMANAGER}" "platforms;android-35" "ndk;${ANDROID_NDK_VERSION}"

"${BASEDIR}/tools/android/build-morph-full-16kb.sh"
