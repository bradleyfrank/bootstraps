# Bootstrapping MacOS & Fedora

*For MacOS, ensure you're signed into iCloud and the Mac App Store.*

The `run.sh` bootstraps Ansible itself before running the playbook.

* For MacOS, this includes Ansible, Git, Xcode, and Homebrew.
* For Fedora, this includes Ansible and Git.

`curl -fsSL https://bradleyfrank.github.io/bootstraps/run.sh | bash`