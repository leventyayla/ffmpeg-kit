#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: tools/android/build-morph-full-16kb.sh"
  echo
  echo "Builds Morph full-GPL Android AAR (16KB page-size compatible) locally without GitHub Actions."
  echo "Requires ANDROID_SDK_ROOT and ANDROID_NDK_ROOT to be set."
  exit 0
fi

if [[ -z "${ANDROID_SDK_ROOT:-}" ]]; then
  echo "ANDROID_SDK_ROOT is not set." >&2
  exit 1
fi

if [[ -z "${ANDROID_NDK_ROOT:-}" ]]; then
  echo "ANDROID_NDK_ROOT is not set." >&2
  exit 1
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKDIR="${BASEDIR}/android/.morph-full-16kb-build"
STAGING_LIBS="${WORKDIR}/libs"

build_single_abi() {
  local abi="$1"
  shift

  echo "==== Building ${abi} ===="
  (cd "${BASEDIR}" && ./android.sh --enable-gpl --full --disable-arm-v7a-neon "$@" --no-archive)

  mkdir -p "${STAGING_LIBS}/${abi}"
  cp -a "${BASEDIR}/android/libs/." "${STAGING_LIBS}/${abi}/"
}

rm -rf "${WORKDIR}"
mkdir -p "${STAGING_LIBS}"

build_single_abi "armeabi-v7a" --disable-arm64-v8a --disable-x86 --disable-x86-64
build_single_abi "arm64-v8a" --disable-arm-v7a --disable-x86 --disable-x86-64
build_single_abi "x86" --disable-arm-v7a --disable-arm64-v8a --disable-x86-64
build_single_abi "x86_64" --disable-arm-v7a --disable-arm64-v8a --disable-x86

echo "==== Merging ABI outputs ===="
rm -rf "${BASEDIR}/android/libs"
mkdir -p "${BASEDIR}/android/libs"
cp -a "${STAGING_LIBS}/armeabi-v7a/." "${BASEDIR}/android/libs/"
cp -a "${STAGING_LIBS}/arm64-v8a/." "${BASEDIR}/android/libs/"
cp -a "${STAGING_LIBS}/x86/." "${BASEDIR}/android/libs/"
cp -a "${STAGING_LIBS}/x86_64/." "${BASEDIR}/android/libs/"

echo "==== Packaging AAR ===="
(
  cd "${BASEDIR}/android/ffmpeg-kit-android-lib"
  chmod +x ../gradlew
  ../gradlew --no-daemon assembleRelease
)

OUTPUT_DIR="${BASEDIR}/prebuilt/bundle-android-aar/ffmpeg-kit"
OUTPUT_AAR="${OUTPUT_DIR}/ffmpeg-kit-morph-full-16kb.aar"

mkdir -p "${OUTPUT_DIR}"
cp "${BASEDIR}/android/ffmpeg-kit-android-lib/build/outputs/aar/ffmpeg-kit-release.aar" "${OUTPUT_AAR}"

echo "AAR created: ${OUTPUT_AAR}"
echo "Attach this file to your GitHub release tag for JitPack publishing."
