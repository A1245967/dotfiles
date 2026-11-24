#!/bin/bash

## Custom Settings for bashrc
export TZ='Asia/Taipei'

# Add the paths of repositories whose branches should always be shown in PS1.
# Empty, missing, and non-Git paths are ignored.
CUSTOM_GIT_REPOS=(
  # "$HOME/path/to/another/repo"
)

##

## Apply Git completion from the current platform, or download a local copy.
load_git_completion() {
  local file developer_dir brew_prefix

  developer_dir=$(xcode-select -p 2> /dev/null) || developer_dir=''

  if command -v brew > /dev/null 2>&1; then
    brew_prefix=$(brew --prefix 2> /dev/null) || brew_prefix=''
  else
    brew_prefix=''
  fi

  for file in \
    "$HOME/.git-completion.bash" \
    "/usr/share/bash-completion/completions/git" \
    "${brew_prefix:+$brew_prefix/etc/bash_completion.d/git-completion.bash}" \
    "/opt/homebrew/etc/bash_completion.d/git-completion.bash" \
    "/usr/local/etc/bash_completion.d/git-completion.bash" \
    "${developer_dir:+$developer_dir/usr/share/git-core/git-completion.bash}"
  do
    if [ -r "$file" ]; then
      . "$file"
      return
    fi
  done

  # Download only when no installed completion script is available.
  if command -v curl > /dev/null 2>&1 &&
     curl --fail --location --silent --show-error \
       --output "$HOME/.git-completion.bash" \
       https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash; then
    . "$HOME/.git-completion.bash"
  fi
}

load_git_completion
unset -f load_git_completion

# Enable platform-appropriate color support and handy aliases.
case "$(uname -s)" in
  Darwin)
    export CLICOLOR=1
    alias ls='ls -G'
    ;;
  Linux)
    if command -v dircolors > /dev/null 2>&1; then
      test -r "$HOME/.dircolors" &&
        eval "$(dircolors -b "$HOME/.dircolors")" ||
        eval "$(dircolors -b)"
    fi

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    ;;
esac

get_directory_warning() {
  local owner

  case "$PWD" in
    /bin|/bin/*|/boot|/boot/*|/dev|/dev/*|/etc|/etc/*|\
    /lib|/lib/*|/lib32|/lib32/*|/lib64|/lib64/*|/libx32|/libx32/*|\
    /proc|/proc/*|/root|/root/*|/run|/run/*|/sbin|/sbin/*|\
    /sys|/sys/*|/usr|/usr/*|/var|/var/*|\
    /Applications|/Applications/*|/Library|/Library/*|\
    /System|/System/*|/private|/private/*)
      printf '[WARNING: system directory] '
      return
      ;;
  esac

  if [ ! -O "$PWD" ]; then
    case "$(uname -s)" in
      Darwin)
        owner=$(stat -f '%Su' "$PWD" 2> /dev/null)
        ;;
      *)
        owner=$(stat -Lc '%U' -- "$PWD" 2> /dev/null)
        ;;
    esac
    printf '[WARNING: owned by %s] ' "${owner:-another user}"
  fi
}

parse_git_branch() {
  local branch

  branch=$(git symbolic-ref --quiet --short HEAD 2> /dev/null)
  if [ -z "$branch" ]; then
    git rev-parse --is-inside-work-tree > /dev/null 2>&1 || return
    branch="detached@$(git rev-parse --short HEAD 2> /dev/null)"
  fi

  printf '(%s)' "$branch"
}

get_repo_branches() {
  local repo repo_name branch
  local output=''

  for repo in "${CUSTOM_GIT_REPOS[@]}"; do
    [ -n "$repo" ] || continue
    git -C "$repo" rev-parse --is-inside-work-tree > /dev/null 2>&1 || continue

    repo_name=$(basename "$(git -C "$repo" rev-parse --show-toplevel 2> /dev/null)")
    branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD 2> /dev/null)
    if [ -z "$branch" ]; then
      branch="detached@$(git -C "$repo" rev-parse --short HEAD 2> /dev/null)"
    fi

    output+="[${repo_name}: ${branch}] "
  done

  printf '%s' "${output% }"
}

export PS1="\[\e[0;35m\][\t] \[\e[1;31m\]\$(get_directory_warning)\[\033[33m\][git branch: \$(parse_git_branch)] [repos: \$(get_repo_branches)] \n\[\e[32;1m\][\u@\h \W] \[\033[33m\]\[\033[01;31m\]$ \[\033[00m\]"

# apply clang-format to all source files in the current directory and subdirectories
# clang-formatter -i --style=file $FILES

# apply patch from github pull request
# eg: curl -L https://github.com/user/repo/pull/pr_num.diff | patch -p1 -N -d .
# usage: apply_github_pr PR_URL
function apply_github_pr() {
    if [ $# -ne 1 ]; then
        echo "Usage: apply_github_pr PR_URL"
        return 1
    fi

    local pr_url="$1"
    local pr_diff_url="${pr_url}.diff"
    local patch_file patch_status

    patch_file=$(mktemp) || {
        echo "Failed to create a temporary file" >&2
        return 1
    }

    # Download the complete diff before modifying the working tree.
    if ! curl --fail --location --silent --show-error \
        --output "$patch_file" "$pr_diff_url"; then
        rm -f -- "$patch_file"
        return 1
    fi

    patch -p1 -N -d . < "$patch_file"
    patch_status=$?
    rm -f -- "$patch_file"
    return "$patch_status"
}

# make a release tarball of the current git repository
# usage: make_release_tarball tarball_name
function make_release_tarball() {
    if [ $# -ne 1 ]; then
        echo "Usage: make_release_tarball tarball_name"
        return 1
    fi

    local tarball_name="$1"

    git archive --format tar.gz \
    --prefix="${tarball_name}/" \
    --output "../${tarball_name}.tar.gz" \
    HEAD
}

# make a shared git repository for the current git repository
# usage: make_shared_git_repo shared_repo_path
function make_shared_git_repo() {
    if [ $# -ne 1 ]; then
        echo "Usage: make_shared_git_repo shared_repo_path"
        return 1
    fi

    local shared_repo_path="$1"

    git clone --shared . "$shared_repo_path"
}
