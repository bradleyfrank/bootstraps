#!/bin/sh

homebrew_url="https://raw.githubusercontent.com/Homebrew/install/master/install"
bootstrap_repo="https://github.com/bradleyfrank/bootstraps.git"
dotfiles_dir="$HOME"/.config/dotfiles
system_os="$(uname -s | tr '[:upper:]' '[:lower:]')"

not_supported() {
  printf '%s\n' "Unsupported OS, aborting..." >&2
  exit 1
}

bootstrap_macos() {
  xcode-select --print-path >/dev/null 2>&1 || xcode-select --install
  [ ! -x /usr/local/bin/brew ] && /usr/bin/ruby -e "$(curl -fsSL "$homebrew_url")"
  [ ! -x /usr/local/bin/ansible ] && brew install ansible git
}

bootstrap_linux() {
  case "$(sed -rn 's/^ID=([a-z]+)/\1/p' /etc/os-release)" in
    fedora) sudo dnf install -y ansible git ;;
         *) not_supported ;;
  esac
}

main() {
  while getopts ':wh' flag; do
    case "${flag}" in
      w) skip_tags="home_only" ;;
      h) skip_tags="work_only" ;;
      *) printf '%s\n' "Requires [-w|-h], aborting..." >&2 ; exit 1 ;;
    esac
  done

  case "$system_os" in
    darwin) bootstrap_macos ;;
     linux) bootstrap_linux ;;
         *) not_supported   ;;
  esac

  [ ! -d "$dotfiles_dir" ] && mkdir -p "$dotfiles_dir"

  if ansible-pull \
    --url "$bootstrap_repo" \
    --directory "$dotfiles_dir" \
    --purge \
    --ask-become-pass \
    --vault-id @prompt \
    --skip-tags "$skip_tags" \
    playbooks/"$system_os".yml
  then
    exit 0
  else
    rm -rf "$dotfiles_dir"
    printf '%s\n' "Ansible run failed" >&2
    exit 1
  fi
}

main