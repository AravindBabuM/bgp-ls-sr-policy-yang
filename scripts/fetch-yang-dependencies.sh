#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cache_dir=${YANG_CACHE_DIR:-"$repo_root/.cache/yang"}
base_ref=${BGP_LS_BASE_REF:-3d9fd9a6ca98498b5cabd69c74fbfeafbbbe6db7}
base_dir="$cache_dir/bgp-ls-$base_ref"
dependency_dir="$cache_dir/dependencies"
download_dir="$cache_dir/downloads"
xym=${XYM:-xym}

mkdir -p "$cache_dir" "$dependency_dir" "$download_dir"

if [ ! -f "$base_dir/src/yang/ietf-bgp-ls.yang" ]; then
  mkdir -p "$base_dir"
  git -C "$base_dir" init -q
  git -C "$base_dir" remote add origin \
    https://github.com/mjethanandani/bgp-ls.git
  git -C "$base_dir" fetch -q --depth 1 origin "$base_ref"
  git -C "$base_dir" checkout -q --detach FETCH_HEAD
fi

extract_document() {
  name=$1
  url=$2
  sentinel=$3
  document="$download_dir/$name"
  if [ ! -f "$dependency_dir/$sentinel" ]; then
    if [ ! -f "$document" ]; then
      curl -fsSL "$url" -o "$document"
    fi
    "$xym" --dstdir "$dependency_dir" "$document" >/dev/null
  fi
}

extract_document \
  draft-ietf-idr-bgp-model-22.txt \
  https://www.ietf.org/archive/id/draft-ietf-idr-bgp-model-22.txt \
  ietf-bgp@2026-10-16.yang
extract_document \
  rfc9130.txt \
  https://www.rfc-editor.org/rfc/rfc9130.txt \
  ietf-isis@2022-10-19.yang
extract_document \
  rfc9129.txt \
  https://www.rfc-editor.org/rfc/rfc9129.txt \
  ietf-ospf@2022-10-19.yang
extract_document \
  rfc8294.txt \
  https://www.rfc-editor.org/rfc/rfc8294.txt \
  ietf-routing-types@2017-12-04.yang
extract_document \
  rfc9911.txt \
  https://www.rfc-editor.org/rfc/rfc9911.txt \
  ietf-inet-types@2025-12-22.yang
extract_document \
  rfc9067.txt \
  https://www.rfc-editor.org/rfc/rfc9067.txt \
  ietf-routing-policy@2021-10-11.yang
extract_document \
  draft-ietf-netmod-yang-semver-29.txt \
  https://www.ietf.org/archive/id/draft-ietf-netmod-yang-semver-29.txt \
  ietf-yang-semver@2026-03-03.yang
extract_document \
  rfc9127.txt \
  https://www.rfc-editor.org/rfc/rfc9127.txt \
  ietf-bfd-types@2021-10-21.yang
extract_document \
  rfc9643.txt \
  https://www.rfc-editor.org/rfc/rfc9643.txt \
  ietf-tcp-common@2024-10-10.yang
extract_document \
  rfc9648.txt \
  https://www.rfc-editor.org/rfc/rfc9648.txt \
  ietf-tcp@2024-10-10.yang

printf '%s\n' "$base_dir" "$dependency_dir"
