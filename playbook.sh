#!/usr/local/env bash

set -eu

homebrew_url="https://raw.githubusercontent.com/Homebrew/install/master/install"
bootstrap_repo="https://github.com/bradleyfrank/bootstraps.git"
tmp_repo="$(mktemp -d)"

case "$OSTYPE" in
  "darwin"*) __os="macos" ;;
   "linux"*) __os="linux" ;;
          *) printf '%s\n' "Unsupported OS, aborting..." >&2 ; exit 1 ;;
esac

if [[ "$__os" == "macos" ]]; then
  xcode-select --install
  [[ ! type brew >/dev/null 2>&1 ]] && /usr/bin/ruby -e "$(curl -fsSL "$homebrew_url")"
  brew update
  brew upgrade
  brew install ansible git
elif [[ "$__os" == "linux" ]]; then
  sudo dnf install ansible git -y
fi

git clone "$bootstrap_repo" "$tmp_repo"

pushd "$tmp_repo" >/dev/null 2>&1 || exit 1
git checkout ansible || exit 1
ansible-playbook site.yml --ask-vault-pass --ask-become-pass
popd >/dev/null 2>&1 || exit 1

exit 0