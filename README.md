⚠ This repository is archived in favor of using Ansible to manage dotfiles. See https://github.com/bradleyfrank/dotfiles

# Bootstrapping MacOS & Fedora

The `run.sh` script bootstraps Ansible itself before running the playbook.

1. For MacOS ensure you're signed into iCloud and the Mac App Store.
2. Create vault password file: `echo "password" > ~/.ansible_vault_password`

Supports systems for work or home.

* Use `-h` to run on a personal computer.
* Use `-w` to run on a work computer.

`curl -fsSL https://raw.githubusercontent.com/bradleyfrank/bootstraps/master/run.sh | bash -s -- [-h|-w]`
