#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pyang=${PYANG:-pyang}
model="$repo_root/src/yang/ietf-bgp-ls-sr-policy.yang"
build_dir="$repo_root/build"
tree="$build_dir/ietf-bgp-ls-sr-policy-tree.txt"

dependency_paths=$("$repo_root/scripts/fetch-yang-dependencies.sh")
base_dir=$(printf '%s\n' "$dependency_paths" | tail -2 | head -1)
dependency_dir=$(printf '%s\n' "$dependency_paths" | tail -1)
search_path="$base_dir/src/yang:$dependency_dir"

mkdir -p "$build_dir"

"$pyang" \
  --ietf \
  --lint \
  --strict \
  --canonical \
  -p "$search_path" \
  "$model"

"$pyang" \
  -f tree \
  --tree-line-length 69 \
  -p "$search_path" \
  "$model" >"$tree"

if command -v yanglint >/dev/null 2>&1; then
  yanglint -p "$base_dir/src/yang" -p "$dependency_dir" "$model"
else
  echo "yanglint not found; pyang validation completed"
fi

"$repo_root/scripts/sync-draft-yang.py" --check
echo "YANG validation completed; tree written to $tree"
