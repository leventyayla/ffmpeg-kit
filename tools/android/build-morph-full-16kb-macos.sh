#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: tools/android/build-morph-full-16kb-macos.sh"
  echo
  echo "Builds Morph full-GPL Android AAR (all ABIs, 16KB-compatible) on macOS."
  echo "The script checks/installs missing build dependencies via Homebrew,"
  echo "installs/updates Android NDK+platform via sdkmanager, then runs the local full build."
  echo "Set FFMPEG_KIT_ACCEPT_ANDROID_LICENSES=no to require explicit license confirmation."
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS (Darwin)." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required but not found. Install from https://brew.sh and run again." >&2
  exit 1
fi

ensure_brew_package() {
  local package="$1"
  local check_command="$2"

  if command -v "${check_command}" >/dev/null 2>&1; then
    return 0
  fi

  echo "Installing missing dependency: ${package}"
  brew install "${package}"
}

ensure_brew_cask() {
  local cask="$1"
  if brew list --cask "${cask}" >/dev/null 2>&1; then
    return 0
  fi

  echo "Installing missing cask: ${cask}"
  brew install --cask "${cask}"
}

ensure_brew_package autoconf autoconf
ensure_brew_package automake automake
ensure_brew_package libtool libtool
ensure_brew_package pkg-config pkg-config
ensure_brew_package cmake cmake
ensure_brew_package meson meson
ensure_brew_package ninja ninja
ensure_brew_package nasm nasm
ensure_brew_package yasm yasm
ensure_brew_package bison bison
ensure_brew_package autogen autogen
ensure_brew_package wget wget
ensure_brew_package gnu-sed gsed
ensure_brew_package gnu-getopt getopt
ensure_brew_package gettext autopoint
ensure_brew_package texinfo makeinfo
ensure_brew_package gperf gperf
ensure_brew_package ragel ragel
ensure_brew_package doxygen doxygen
ensure_brew_package coreutils greadlink

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ANDROID_SDK_ROOT_DEFAULT="${HOME}/Library/Android/sdk"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT_DEFAULT}}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT}}"
export ANDROID_NDK_VERSION="${ANDROID_NDK_VERSION:-27.2.12479018}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}}"
export FFMPEG_KIT_ACCEPT_ANDROID_LICENSES="${FFMPEG_KIT_ACCEPT_ANDROID_LICENSES:-yes}"

SDKMANAGER="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x "${SDKMANAGER}" ]]; then
  ensure_brew_cask android-commandlinetools
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"

  for tools_root in \
    "/opt/homebrew/share/android-commandlinetools/cmdline-tools" \
    "/usr/local/share/android-commandlinetools/cmdline-tools"; do
    if [[ -x "${tools_root}/bin/sdkmanager" ]]; then
      latest_link="${ANDROID_SDK_ROOT}/cmdline-tools/latest"
      if [[ "${ANDROID_SDK_ROOT}" == "/" ]]; then
        echo "ANDROID_SDK_ROOT is unsafe: '${ANDROID_SDK_ROOT}'" >&2
        exit 1
      fi
      if [[ "${latest_link}" != */cmdline-tools/latest ]]; then
        echo "Refusing to remove unexpected path: ${latest_link}" >&2
        exit 1
      fi
      rm -rf "${latest_link}"
      ln -s "${tools_root}" "${latest_link}"
      break
    fi
  done

  if [[ ! -x "${SDKMANAGER}" ]]; then
    echo "Missing sdkmanager at ${SDKMANAGER}" >&2
    echo "Install Android command line tools and place them under:" >&2
    echo "  ${ANDROID_SDK_ROOT}/cmdline-tools/latest/" >&2
    exit 1
  fi
fi

echo "Using ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
echo "Using ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}"

if [[ "${FFMPEG_KIT_ACCEPT_ANDROID_LICENSES}" != "yes" ]]; then
  echo "Android SDK licenses are required. Re-run with FFMPEG_KIT_ACCEPT_ANDROID_LICENSES=yes." >&2
  exit 1
fi

echo "Accepting Android SDK licenses automatically via sdkmanager --licenses."
yes | "${SDKMANAGER}" --licenses >/dev/null 2>&1 || true
"${SDKMANAGER}" "platforms;android-35" "ndk;${ANDROID_NDK_VERSION}"

"${BASEDIR}/tools/android/build-morph-full-16kb.sh"
