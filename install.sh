#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_file="$repo_dir/bashrc"
target_file="$HOME/.bashrc"

if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
  printf '%s\n' "$target_file is already linked to $source_file"
  exit 0
fi

if [ -e "$target_file" ] || [ -L "$target_file" ]; then
  backup_file="$target_file.backup-$(date +%Y%m%d-%H%M%S)"
  while [ -e "$backup_file" ] || [ -L "$backup_file" ]; do
    backup_file="$backup_file-1"
  done
  mv "$target_file" "$backup_file"
  printf '%s\n' "Backed up $target_file to $backup_file"
fi

ln -s "$source_file" "$target_file"
printf '%s\n' "Linked $target_file to $source_file"

