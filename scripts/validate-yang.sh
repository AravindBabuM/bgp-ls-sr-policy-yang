#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pyang=${PYANG:-pyang}
model="$repo_root/src/yang/ietf-bgp-ls-sr-policy.yang"
build_dir="$repo_root/build"
tree="$build_dir/ietf-bgp-ls-sr-policy-tree.txt"
normalized_base_dir="$build_dir/dependencies/bgp-ls"

dependency_paths=$("$repo_root/scripts/fetch-yang-dependencies.sh")
base_dir=$(printf '%s\n' "$dependency_paths" | tail -2 | head -1)
dependency_dir=$(printf '%s\n' "$dependency_paths" | tail -1)

mkdir -p "$build_dir" "$normalized_base_dir"
cp "$base_dir"/src/yang/*.yang "$normalized_base_dir"/
base_revision=$(git -C "$base_dir" show -s --format=%cs HEAD)
for module in "$normalized_base_dir"/*.yang; do
  sed "s/revision YYYY-MM-DD/revision $base_revision/" "$module" \
    >"$module.tmp"
  mv "$module.tmp" "$module"
done

search_path="$normalized_base_dir:$dependency_dir"
pyang_executable=$(command -v "$pyang")
pyang_prefix=$(CDPATH= cd -- "$(dirname -- "$pyang_executable")/.." && pwd)
pyang_ietf_dir="$pyang_prefix/share/yang/modules/ietf"
pyang_iana_dir="$pyang_prefix/share/yang/modules/iana"

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
  yanglint \
    -p "$normalized_base_dir" \
    -p "$dependency_dir" \
    -p "$pyang_ietf_dir" \
    -p "$pyang_iana_dir" \
    "$model"
else
  echo "yanglint not found; pyang validation completed"
fi

"$repo_root/scripts/sync-draft-yang.py" --check
echo "YANG validation completed; tree written to $tree"
