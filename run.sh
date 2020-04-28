#!/usr/local/env bash

homebrew_url="https://raw.githubusercontent.com/Homebrew/install/master/install"
bootstrap_repo="https://github.com/bradleyfrank/bootstraps.git"

not_supported() {
  printf '%s\n' "Unsupported OS, aborting..." >&2
  exit 1
}

bootstrap_macos() {
  xcode-select --print-path &> /dev/null || xcode-select --install
  [[ ! -x /usr/local/bin/brew ]] && /usr/bin/ruby -e "$(curl -fsSL "$homebrew_url")"
  [[ ! -x /usr/local/bin/ansible ]] && brew install ansible git
}

bootstrap_linux() {
  case "$(sed -rn 's/^ID=([a-z]+)/\1/p' /etc/os-release)" in
    fedora) sudo dnf install ansible git -y ;;
         *) not_supported                   ;;
  esac
}

case "$OSTYPE" in
  ^darwin) bootstrap_macos ;;
   ^linux) bootstrap_linux ;;
        *) not_supported   ;;
esac

tmp_repo="$(mktemp -d)"

if ansible-pull \
  --url "$bootstrap_repo" \
  --directory "$tmp_repo" \
  --purge \
  --ask-become-pass \
  --vault-id @prompt \
  playbooks/"$(echo "$OSTYPE" | grep -Eo "(darwin|linux)")".yml
then
  rm -rf "$tmp_repo"
  exit 0
else
  mv "$tmp_repo" "$HOME"
  echo "Ansible run failed; repo saved to $HOME"
  exit 1
fi
