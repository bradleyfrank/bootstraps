#!/usr/local/env bash

set -eu

homebrew_url="https://raw.githubusercontent.com/Homebrew/install/master/install"
bootstrap_repo="https://github.com/bradleyfrank/bootstraps.git"
tmp_repo="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_repo"
}

not_supported() {
  printf '%s\n' "Unsupported OS, aborting..." >&2
  exit 1
}

trap cleanup EXIT

if [[ $OSTYPE =~ ^darwin ]]; then
  xcode-select --install
  [[ ! -x /usr/local/bin/brew ]] && /usr/bin/ruby -e "$(curl -fsSL "$homebrew_url")"
  brew install ansible git
elif [[ $OSTYPE =~ ^linux ]]; then
  case "$(sed -rn 's/^ID=([a-z]+)/\1/p' /etc/os-release)" in
    fedora) sudo dnf install ansible git -y ;;
         *) not_supported                   ;;
  esac
else
  not_supported
fi

git clone "$bootstrap_repo" "$tmp_repo"

pushd "$tmp_repo" >/dev/null 2>&1 || exit 1
git checkout ansible || exit 1
ansible-playbook site.yml --ask-become-pass --vault-id @prompt
popd >/dev/null 2>&1 || exit 1

exit 0