#!/usr/bin/env bash

set -euo pipefail

readonly ZOLA_VERSION="0.23.6"
readonly INSTALL_DIR="${HOME}/.local/zola"

current_version=""
if command -v zola >/dev/null 2>&1; then
  current_version="$(zola --version)"
fi

if [[ "$current_version" != "zola ${ZOLA_VERSION}" ]]; then
  temp_dir="$(mktemp -d)"
  trap 'rm -rf -- "$temp_dir"' EXIT

  release_url="https://github.com/getzola/zola/releases/download"
  archive="zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
  curl --fail --silent --show-error --location \
    --output "${temp_dir}/zola.tar.gz" \
    "${release_url}/v${ZOLA_VERSION}/${archive}"
  mkdir -p "$INSTALL_DIR"
  tar -C "$INSTALL_DIR" -xf "${temp_dir}/zola.tar.gz"
  export PATH="${INSTALL_DIR}:${PATH}"
fi

[[ "$(zola --version)" == "zola ${ZOLA_VERSION}" ]]
git submodule update --init --recursive

if [ "$WORKERS_CI_BRANCH" = "main" ] || [ -z "$WORKERS_CI_BRANCH" ]; then
  zola build
else
  zola build --base-url "/"
fi
