#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_file="$repo_dir/bashrc"
target_file="$HOME/.bashrc"
begin_marker='# >>> dotfiles >>>'
end_marker='# <<< dotfiles <<<'

if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
  printf '%s\n' "$target_file already loads $source_file directly"
  exit 0
fi

if grep -Fqx "$begin_marker" "$target_file" 2> /dev/null; then
  printf '%s\n' "$target_file already loads the dotfiles bashrc"
  exit 0
fi

if [ -e "$target_file" ]; then
  backup_file="$target_file.backup-$(date +%Y%m%d-%H%M%S)"
  while [ -e "$backup_file" ] || [ -L "$backup_file" ]; do
    backup_file="$backup_file-1"
  done
  cp "$target_file" "$backup_file"
  printf '%s\n' "Backed up $target_file to $backup_file"
elif [ -L "$target_file" ]; then
  printf '%s\n' "Cannot update dangling symbolic link: $target_file" >&2
  exit 1
fi

{
  printf '\n%s\n' "$begin_marker"
  printf 'if [ -r "%s" ]; then\n' "$source_file"
  printf '  . "%s"\n' "$source_file"
  printf 'fi\n%s\n' "$end_marker"
} >> "$target_file"

printf '%s\n' "Updated $target_file to load $source_file"

