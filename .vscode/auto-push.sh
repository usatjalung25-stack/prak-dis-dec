#!/bin/sh
set -eu

file_path=${1:?A saved file path is required}
file_name=${file_path##*/}
file_dir=$(cd "$(dirname "$file_path")" && pwd -P)
file_path=$file_dir/$file_name
repo_root=$(git -C "$file_dir" rev-parse --show-toplevel)

case "$file_path" in
  "$repo_root"/*) ;;
  *)
    printf 'Saved file is outside the Git repository: %s\n' "$file_path" >&2
    exit 1
    ;;
esac

if [ -z "$(git -C "$repo_root" status --short -- "$file_path")" ]; then
  exit 0
fi

git -C "$repo_root" add -- "$file_path"
git -C "$repo_root" commit --only -m "Auto-sync: $file_name" -- "$file_path"
git -C "$repo_root" push
