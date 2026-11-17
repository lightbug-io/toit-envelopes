#!/usr/bin/env bash

# Build one public envelope from firmware-profiles.json without changing the
# repository's pinned Toit submodule. Each SDK is kept in its own local clone.

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_FILE="${SOURCE_DIR}/firmware-profiles.json"

usage() {
  cat <<'EOF'
Usage: scripts/build-envelope.sh <asset-name>

Example:
  scripts/build-envelope.sh esp32c6-single-ota.198.envelope

The asset name must be listed in firmware-profiles.json. The selected Toit
source is cloned below .cache/toit and does not modify the toit submodule.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required to read ${PROFILE_FILE}." >&2
  exit 1
fi

ASSET="$1"
PROFILE="$(jq -ce --arg asset "${ASSET}" '(.envelopes + (.experimental_envelopes // []))[] | select(.asset == $asset)' "${PROFILE_FILE}")" || {
  echo "Unknown envelope asset: ${ASSET}" >&2
  jq -r '(.envelopes + (.experimental_envelopes // []))[].asset' "${PROFILE_FILE}" >&2
  exit 1
}

TOIT_REF="$(jq -r '.toit_ref' <<<"${PROFILE}")"
TOIT_REPOSITORY="$(jq -r '.toit_repository // "toitlang/toit"' <<<"${PROFILE}")"
VARIANT="$(jq -r '.variant' <<<"${PROFILE}")"
SAFE_REF="${TOIT_REF//\//_}"
SAFE_REPOSITORY="${TOIT_REPOSITORY//\//_}"
TOIT_ROOT="${SOURCE_DIR}/.cache/toit/${SAFE_REPOSITORY}/${SAFE_REF}"
BUILD_PATH="${SOURCE_DIR}/build/sdk-${SAFE_REPOSITORY}-${SAFE_REF}"

mkdir -p "$(dirname "${TOIT_ROOT}")"
if [[ ! -d "${TOIT_ROOT}/.git" ]]; then
  # Some developer machines rewrite GitHub HTTPS URLs to SSH globally. Builds
  # must remain usable without a GitHub SSH key, so deliberately use HTTPS.
  env GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git clone --no-checkout \
    "https://github.com/${TOIT_REPOSITORY}.git" "${TOIT_ROOT}"
fi

env GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git -C "${TOIT_ROOT}" fetch --depth=1 origin \
  "${TOIT_REF}"
env GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git -C "${TOIT_ROOT}" checkout --detach FETCH_HEAD
IDF_SUBMODULES=(third_party/esp-idf)
if [[ -f "${SOURCE_DIR}/variants/${VARIANT}/idf_target" ]] &&
   [[ "$(<"${SOURCE_DIR}/variants/${VARIANT}/idf_target")" == esp32s31 ]]; then
  IDF_SUBMODULES+=(third_party/esp-idf-s31)
fi
env GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git -C "${TOIT_ROOT}" submodule update \
  --init --recursive --depth=1 -- "${IDF_SUBMODULES[@]}"

make -C "${SOURCE_DIR}" init \
  VARIANT="${VARIANT}" \
  TOIT_ROOT="${TOIT_ROOT}" \
  INITIALIZE_SUBMODULES=false
make -C "${SOURCE_DIR}" envelope \
  VARIANT="${VARIANT}" \
  TOIT_ROOT="${TOIT_ROOT}" \
  BUILD_PATH="${BUILD_PATH}" \
  INITIALIZE_SUBMODULES=false

cp "${SOURCE_DIR}/dist/${VARIANT}.envelope" "${SOURCE_DIR}/dist/${ASSET}"
echo "Built dist/${ASSET} from ${TOIT_REF} (${VARIANT})."
