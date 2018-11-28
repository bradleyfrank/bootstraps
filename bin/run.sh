#!/bin/bash

# shellcheck disable=SC2164
set -eu


#
# --==## SETTINGS ##==--
#

GH_RAW="https://raw.githubusercontent.com"
GH_URL="https://github.com"

BREW_URL="$GH_RAW/Homebrew/install/master/install"

BOOTSTRAP_REPO="$GH_URL/bradleyfrank/bootstraps.git"
DOTFILES_REPO="$GH_URL/bradleyfrank/dotfiles.git"

DOTFILES_DIR="$HOME/.dotfiles"
BASH_DOTFILES_SCRIPT="$HOME/.local/bin/generate-dotfiles"

LOCAL_REPO="/usr/local/srv"

#
# Local development structure
#
# ├── Development
# │   ├── Clients
# │   ├── Home
# │   ├── Scratch
# │   └── Snippets
# ├── .config
# │   └── dotfiles
# ├── .local
# │   ├── bin
# │   ├── etc
# │   ├── include
# │   ├── lib
# │   ├── opt
# │   ├── share
# │   │   ├── dict
# │   │   │   └── doc
# │   │   ├── doc
# │   │   └── man
# │   │       ├── man1
# │   │       ├── man2
# │   │       ├── man3
# │   │       ├── man4
# │   │       ├── man5
# │   │       ├── man6
# │   │       ├── man7
# │   │       ├── man8
# │   │       └── man9
# │   └── var
# └── .ssh
#

HOME_DIRECTORIES=(
  "$HOME/Development/{Clients,Home,Scratch,Snippets}"
  "$HOME/.config/dotfiles/archive"
  "$HOME/.local/{bin,etc,include,lib,share,opt,var}"
  "$HOME/.local/share/{bash,doc,man/man{1..9}}"
  "$HOME/.ssh"
)

SYS_DIRECTORIES=(
  "/usr/local/{bin,etc,include,lib,share,var}"
  "/usr/local/share/dict"
)

A_USER="$(id -un)"
OS_NAME=""
OS_MAJVER=""


#
# --==## FUNCTIONS ##==--
#

bootstrap_macos() {
  # exempt admin group from sudo password requirement
  sudo bash -c \
    "echo '%admin ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"

  if ! type xcode-select >/dev/null 2>&1; then
    xcode-select --install
  fi

  if ! type brew >/dev/null 2>&1; then
    ruby -e "$(curl -fsSL $BREW_URL)"
  fi

  brew update
  brew install git

  git clone "$BOOTSTRAP_REPO" "$LOCAL_REPO"
  pushd "$LOCAL_REPO"/files >/dev/null 2>&1
  brew bundle install Brewfile
  popd >/dev/null 2>&1
  brew cleanup

  cp "$LOCAL_REPO"/puppet/modules/bmf/files/assets/words /usr/local/share/dict/
  # shellcheck disable=SC1090
  . "$LOCAL_REPO"/bin/macos.sh
}


bootstrap_linux() {
  OS_NAME="$(awk '{print $1}' /etc/redhat-release)"
  OS_MAJVER="$(grep -oE '([0-9]+)' /etc/redhat-release | head -n 1)"

  sudo yum install -y git
  git_clone_repo "$LOCAL_REPO" "$BOOTSTRAP_REPO"

  case "$OS_NAME" in
    Fedora) bootstrap_linux_fedora ;;
         *) bootstrap_linux_centos ;;
  esac
}


bootstrap_linux_centos() {
  local rpm puppet_apply="/usr/local/bin/puppet-apply"

  if [[ "$(sudo rpm -qa 'puppet6-release' | wc -l)" -eq 0 ]]; then
    rpm=$(mktemp)
    curl -o "$rpm" -s -L "https://yum.puppetlabs.com/puppet6/\
      puppet6-release-el-${OS_MAJVER}.noarch.rpm"
    sudo rpm -ivh "$rpm"
  fi

  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-puppet6-release

  sudo yum install -y epel-release
  sudo yum clean all
  sudo yum makecache
  sudo yum install -y puppet-agent augeas
  sudo yum update -y

  # install Puppet apply script
  sudo cp "$LOCAL_REPO"/files/puppet-apply "$puppet_apply"
  sudo chown "$A_USER" "$puppet_apply"
  sudo chmod 0755 "$puppet_apply"

  # apply Puppet manifest
  "$puppet_apply"
}


bootstrap_linux_fedora() {
  sudo dnf install -y ansible
  sudo dnf upgrade -y
  sudo ansible-playbook 
}


git_clone_repo() {
  local destdir="$1" gitrepo="$2"

  pushd "$HOME" >/dev/null 2>&1
  if [[ -d "$destdir" ]]; then sudo rm -rf "$destdir"; fi
  git clone "$gitrepo" "$destdir"

  pushd "$destdir" >/dev/null 2>&1
  git submodule update --init --recursive
  popd >/dev/null 2>&1

  chmod -R 0750 "$destdir"
  popd >/dev/null 2>&1
}


stow_packages() {
  local stow_packages flags="$1"
  shopt -s nullglob
  stow_packages=(*/)

  echo -n "Stowing..."
  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n " $_pkg"
    stow -d "$DOTFILES_DIR" -t "$HOME" "$flags" "$_pkg"
  done
  echo
}


#
# --==## MAIN ##==--
#

# trigger sudo timeout
sudo -v


# make $HOME directory structure
for directory in "${HOME_DIRECTORIES[@]}"; do
  eval "mkdir -p $directory"
done


# make system directory structure
sudo chown "$A_USER" /usr/local
sudo chmod 755 /usr/local
for directory in "${SYS_DIRECTORIES[@]}"; do
  eval "mkdir -p $directory"
done


# initial bootstraps
case "$(uname -s)" in
  Darwin) bootstrap_macos ;;
   Linux) bootstrap_linux ;;
esac


# fix permissions
chmod 0700 "$HOME"/.ssh
sudo chown -R "$A_USER" "$(dirname "$DICTIONARY")"


# install python packages
pip3 install -U --user -r "$LOCAL_REPO"/files/requirements.txt


# clone dotfiles repository
git_clone_repo "$DOTFILES_DIR" "$DOTFILES_REPO"


# install post-merge hook and run
cp "$LOCAL_REPO"/files/post-merge "$DOTFILES_DIR"/.git/hooks/
chmod u+x "$DOTFILES_DIR"/.git/hooks/post-merge
pushd "$DOTFILES_DIR" >/dev/null 2>&1
# when false, executable bit changes are ignored by Git
git config core.fileMode false
# shellcheck disable=SC1091
. ./.git/hooks/post-merge
popd >/dev/null 2>&1


# stow all packages in dotfiles
pushd "$DOTFILES_DIR" >/dev/null 2>&1
HOST_NAME=$(uname -n)

if git branch -a | grep -qE "$HOST_NAME" >/dev/null 2>&1; then
  # local hostname branch exists: go ahead and stow
  git checkout master
  stow_packages ""
else
  # no hostname branch: create one and backup configs
  git checkout -b "$HOST_NAME"
  stow_packages "--adopt"
  git add -A
  if git commit --dry-run >/dev/null 2>&1; then
    # only commit if there are changes to commit
    git commit -m "Backup dotfiles for $HOST_NAME."
  fi
  git checkout master
  # reset any submodules to dotfiles-specified commit
  git submodule foreach git checkout . >/dev/null 2>&1
fi

popd >/dev/null 2>&1


# Generate .bashrc and .bash_profile
$BASH_DOTFILES_SCRIPT
# shellcheck disable=SC1090
. "$HOME/.bash_profile"
