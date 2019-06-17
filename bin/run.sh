#!/bin/bash

# shellcheck disable=SC2164
set -eu


#
# --==## SETTINGS ##==--
#

GITHUB_RAW_URL="https://raw.githubusercontent.com"
GITHUB_COM_URL="https://github.com"

BREW_URL="$GITHUB_RAW_URL/Homebrew/install/master/install"

BOOTSTRAP_REPO="$GITHUB_COM_URL/bradleyfrank/bootstraps.git"
DOTFILES_REPO="$GITHUB_COM_URL/bradleyfrank/dotfiles.git"

DOTFILES_DIR="$HOME/.dotfiles"
BASH_DOTFILES_SCRIPT="$HOME/.local/bin/generate-dotfiles"

LOCAL_REPO="/usr/local/srv"

#
# Local development structure
#
# ├── Development
# │   ├── Clients
# │   ├── Home
# │   └── Scratch
# ├── .config
# │   └── VSCodium
# │       └── User
# ├── .local
# │   ├── bin
# │   ├── etc
# │   ├── include
# │   ├── lib
# │   ├── opt
# │   ├── share
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
  "$HOME/Development/{Clients,Home,Scratch}"
  "$HOME/.config/VSCodium/User"
  "$HOME/.local/{bin,etc,include,lib,share,opt,var}"
  "$HOME/.local/share/{man/man{1..9}}"
  "$HOME/.ssh"
)

SYS_DIRECTORIES=(
  "/usr/local/{bin,etc,include,lib,share,var}"
  "/usr/local/share/dict"
)

LOCAL_USER="$(id -un)"
LOCAL_HOSTNAME=$(uname -n)


#
# --==## FUNCTIONS ##==--
#

bootstrap_macos() {
  if ! type xcode-select >/dev/null 2>&1; then
    xcode-select --install
  fi

  if ! type brew >/dev/null 2>&1; then
    ruby -e "$(curl -fsSL "$GITHUB_RAW_URL"/Homebrew/install/master/install)"
  fi

  brew update
  brew install git

  git_clone_repo "$LOCAL_REPO" "$BOOTSTRAP_REPO"
  pushd "$LOCAL_REPO"/assets >/dev/null 2>&1
  brew bundle install Brewfile
  popd >/dev/null 2>&1
  brew cleanup

  # shellcheck disable=SC1090
  . "$LOCAL_REPO"/bin/macos.sh
}


bootstrap_fedora() {
  local xdg_desktop os_majver
  local pkgs_full_list pkgs pkgs_dir="$LOCAL_REPO/assets/Fedora-packages"

  os_majver="$(grep -oE '([0-9]+)' /etc/redhat-release | head -n 1)"

  if ! type brew >/dev/null 2>&1; then
    sh -c "$(curl -fsSL "$GITHUB_RAW_URL"/Linuxbrew/install/master/install.sh)"
  fi

  # install git in order to clone this repo
  sudo dnf install git -y
  git_clone_repo "$LOCAL_REPO" "$BOOTSTRAP_REPO"

  # update system
  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-"$os_majver"-primary
  sudo dnf upgrade -y

  # install repos and import gpg keys
  pushd "$LOCAL_REPO"/assets/Fedora-repos >/dev/null 2>&1
  sudo command cp -rf ./yum.repos.d/* /etc/yum.repos.d/
  sudo command cp -rf ./rpm-gpg/* /etc/pki/rpm-gpg/
  sudo chmod 644 /etc/yum.repos.d/* /etc/pki/rpm-gpg/*
  sudo rpm --import ./rpm-gpg/*
  popd >/dev/null 2>&1

  # update and install packages
  sudo dnf clean all
  while ! sudo dnf makecache; do sudo dnf clean all; done

  # determine desktop environment (i.e. Gnome, KDE)
  xdg_desktop="$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')"

  # create list of appropriate packages to install
  pkgs_full_list="$(mktemp)"
  cat "$pkgs_dir"/common "$pkgs_dir"/"$xdg_desktop" > "$pkgs_full_list"

  # install packages
  readarray -t pkgs < "$pkgs_full_list"
  sudo dnf install -y --allowerasing "${pkgs[@]}"
  sudo dnf upgrade -y

  # desktop configuration
  case "$xdg_desktop" in
    gnome) dconf load /org/gnome/ < "$LOCAL_REPO"/assets/gnome.dconf ;;
    kde)   . "$LOCAL_REPO"/bin/kde.sh                                  ;;
  esac
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
  for dir in */; do
    stow -d "$DOTFILES_DIR" -t "$HOME" "$1" "$dir"
  done
}


#
# --==## MAIN ##==--
#

# make $HOME directory structure
for directory in "${HOME_DIRECTORIES[@]}"; do
  eval "mkdir -p $directory"
done


# make system directory structure
sudo chown -R "$LOCAL_USER" /usr/local
sudo chmod -R 755 /usr/local
for directory in "${SYS_DIRECTORIES[@]}"; do
  eval "mkdir -p $directory"
done


# initial bootstraps
case "$(uname -s)" in
  Darwin) bootstrap_macos ;;
   Linux) bootstrap_fedora ;;
esac


# install python packages
python3 -m pip install -U --user -r "$LOCAL_REPO"/assets/requirements.txt


# install custom dictionary
cp "$LOCAL_REPO"/assets/words /usr/local/share/dict/


# clone dotfiles repository
git_clone_repo "$DOTFILES_DIR" "$DOTFILES_REPO"


# install post-merge hook and run
cp "$LOCAL_REPO"/assets/post-merge "$DOTFILES_DIR"/.git/hooks/
chmod u+x "$DOTFILES_DIR"/.git/hooks/post-merge
pushd "$DOTFILES_DIR" >/dev/null 2>&1
# when false, executable bit changes are ignored by Git
git config core.fileMode false
./.git/hooks/post-merge
popd >/dev/null 2>&1


# stow all packages in dotfiles
pushd "$DOTFILES_DIR" >/dev/null 2>&1

if git branch -a | grep -qE "$LOCAL_HOSTNAME" >/dev/null 2>&1; then
  # local hostname branch exists: go ahead and stow
  git checkout master
  stow_packages ""
else
  # no hostname branch: create one and backup configs
  git checkout -b "$LOCAL_HOSTNAME"
  stow_packages "--adopt"
  git add -A
  if git commit --dry-run >/dev/null 2>&1; then
    # only commit if there are changes to commit
    git commit -m "Backup dotfiles for $LOCAL_HOSTNAME."
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
