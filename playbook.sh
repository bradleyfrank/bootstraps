#!/usr/local/env bash

set -eu

bootstrap_repo="https://github.com/bradleyfrank/bootstraps.git"
tmp_repo="$(mktemp -d)"

sudo dnf install ansible git -y
git_clone_repo "$tmp_repo" "$bootstrap_repo"
pushd "$tmp_repo" >/dev/null 2>&1 || exit 1
git checkout ansible || exit 1
ansible-playbook site.yml --ask-vault-pass --ask-become-pass
popd >/dev/null 2>&1 || exit 1

exit 0