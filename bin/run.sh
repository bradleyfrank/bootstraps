#!/bin/bash

# shellcheck disable=SC2164
set -eu


#
# --==## SETTINGS ##==--
#

GH_RAW="https://raw.githubusercontent.com"
GH_URL="https://github.com"

BREW_URL="$GH_RAW/Homebrew/install/master/install"

PUPPET_REPO="$GH_URL/bradleyfrank/puppet.git"
DOTFILES_REPO="$GH_URL/bradleyfrank/dotfiles.git"

BOOTSTRAP_SCRIPTS="$GH_RAW/bradleyfrank/puppet/master/bin"
BOOTSTRAP_ASSETS="$GH_RAW/bradleyfrank/puppet/master/files"

DICTIONARY="/usr/local/share/dict/words"
WORDS="$GH_RAW/bradleyfrank/puppet/master/modules/bmf/files/assets/words"

DOTFILES_DIR="$HOME/.dotfiles"
BASH_DOTFILES_SCRIPT="$HOME/.local/bin/generate-dotfiles"

#
# Local development structure
#
# ├── Development
# │   ├── Clients
# │   ├── Home
# │   ├── Scratch
# │   └── Snippets
# ├── .atom
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
# │   ├── srv
# │   └── var
# └── .ssh
#

HOME_DIRECTORIES=(
  "$HOME/Development/{Clients,Home,Scratch,Snippets}"
  "$HOME/.atom"
  "$HOME/.config/dotfiles/archive"
  "$HOME/.local/{bin,etc,include,lib,share,srv,opt,var}"
  "$HOME/.local/share/{bash,doc,man/man{1..9}}"
  "$HOME/.ssh"
)

SYS_DIRECTORIES=(
  "/usr/local/{bin,etc,include,lib,share,var}"
  "/usr/local/share/dict"
)


#
# --==## FUNCTIONS ##==--
#

bootstrap_macos() {
  local brewfile settings_script

  # exempt admin group from sudo password requirement
  sudo bash -c \
    "echo '%admin ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd"

  # install Xcode
  if ! type xcode-select >/dev/null 2>&1; then
    xcode-select --install
  fi

  # install Homebrew
  if ! type brew >/dev/null 2>&1; then
    ruby -e "$(curl -fsSL $BREW_URL)"
  fi

  # download Brewfile from GitHub
  brewfile="$(mktemp -d)/Brewfile"
  curl -o "$brewfile" -s -L "$BOOTSTRAP_ASSETS"/Brewfile

  # install Homebrew packages
  brew update
  pushd "$(dirname $brewfile)" >/dev/null 2>&1
  brew bundle install Brewfile
  popd >/dev/null 2>&1
  brew cleanup

  # install custom dictionary
  wget "$WORDS" -qO "$DICTIONARY"
  sudo chmod 0755 "$DICTIONARY"

  # download and run system settings script
  settings_script=$(mktemp)
  curl -o "$settings_script" -s -L "$BOOTSTRAP_SCRIPTS"/macos.sh
  # shellcheck disable=SC1090
  . "$settings_script"
}


bootstrap_linux() {
  local puppet_manifest="/srv/puppet" pkg_manager

  if type dnf >/dev/null 2>&1; then
    pkg_manager="dnf"
  else
    pkg_manager="yum"
  fi

  # install Puppet dependencies (repo + packages)
  sudo rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
  sudo "$pkg_manager" install -y epel-release
  sudo "$pkg_manager" clean all
  sudo "$pkg_manager" makecache
  sudo "$pkg_manager" install -y puppet-agent git augeas

  # clone the Puppet manifest
  sudo mkdir -p "$puppet_manifest"
  sudo chown -R root:root /srv
  sudo git clone "$PUPPET_REPO" "$puppet_manifest"

  # apply Puppet manifest
  sudo /opt/puppetlabs/bin/puppet apply $puppet_manifest/manifests/site.pp \
    --hiera_config $puppet_manifest/hiera.yaml \
    --modulepath $puppet_manifest/modules
}


dotfiles_repo_clone() {
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  pushd "$DOTFILES_DIR" >/dev/null 2>&1
  git submodule update --init --recursive
  popd >/dev/null 2>&1
}


dotfiles_repo_clone_post() {
  # when false, executable bit changes are ignored by Git
  git config core.fileMode false

  # download and install post-merge hook
  local githook_postmerge
  githook_postmerge="$DOTFILES_DIR"/.git/hooks/post-merge
  wget "$BOOTSTRAP_ASSETS"/post-merge -qO "$githook_postmerge"
  chmod u+x "$githook_postmerge"

  # run post-merge to fix permissions; hence setting fileMode
  pushd "$DOTFILES_DIR" >/dev/null 2>&1
  # shellcheck disable=SC1091
  . ./.git/hooks/post-merge
  popd >/dev/null 2>&1
}


stow_packages() {
  local stow_packages flags="$1"
  shopt -s nullglob
  stow_packages=(*/)

  echo -n "Stowing"
  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n " $_pkg"
    stow -d "$DOTFILES_DIR" -t "$HOME" "$flags" "$_pkg"
  done
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
for directory in "${SYS_DIRECTORIES[@]}"; do
  eval "sudo mkdir -p $directory"
done


# fix permissions
chmod 0700 "$HOME"/.ssh
chmod 0750 "$DOTFILES_DIR"
sudo chown $(id -un) $(dirname $DICTIONARY)


# initial bootstraps
case "$(uname -s)" in
  Darwin) bootstrap_macos ;;
   Linux) bootstrap_linux ;;
esac


# download Python requirements.txt and install packages
requirements=$(mktemp)
curl -o "$requirements" -s -L "$BOOTSTRAP_ASSETS"/requirements.txt
pip3 install -U --user -r "$requirements"


# download dotfiles repository
if [[ ! -d "$DOTFILES_DIR" ]]; then
  # brand new install
  dotfiles_repo_clone
  dotfiles_repo_clone_post
else
  pushd "$DOTFILES_DIR" >/dev/null 2>&1
  if ! git status >/dev/null 2>&1; then
    # remove any previous installation
    popd >/dev/null 2>&1
    rm -rf "$DOTFILES_DIR"
    dotfiles_repo_clone
    dotfiles_repo_clone_post
  else
    # exists so pull changes
    git checkout master
    git pull
    popd >/dev/null 2>&1
  fi
fi


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
