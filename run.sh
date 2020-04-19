#!/usr/local/env bash

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
  xcode-select --print-path &> /dev/null || xcode-select --install
  [[ ! -x /usr/local/bin/brew ]] && /usr/bin/ruby -e "$(curl -fsSL "$homebrew_url")"
  [[ ! -x /usr/local/bin/ansible ]] && brew install ansible git
elif [[ $OSTYPE =~ ^linux ]]; then
  case "$(sed -rn 's/^ID=([a-z]+)/\1/p' /etc/os-release)" in
    fedora) sudo dnf install ansible git -y ;;
         *) not_supported                   ;;
  esac
else
  not_supported
fi

ansible-pull \
  --url "$bootstrap_repo" \
  --directory "$tmp_repo" \
  --purge \
  --ask-become-pass --vault-id @prompt \
  bootstrap.yml

exit 0
