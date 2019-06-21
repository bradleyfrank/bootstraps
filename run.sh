#!/bin/bash

# shellcheck disable=SC2164
set -eu


#
# --==## SETTINGS ##==--
#

__github_raw_url="https://raw.githubusercontent.com"

__bootstrap_repo="https://github.com/bradleyfrank/bootstraps.git"
__dotfiles_repo="https://github.com/bradleyfrank/dotfiles.git"

__dotfiles_dir="$HOME/.dotfiles"
__tmp_repo="$(mktemp -d)"

__user="$(id -un)"
__localhost=$(uname -n)

#
# Home directory structure
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

__home_dir_struct=(
  "$HOME/Development/{Clients,Home,Scratch}"
  "$HOME/.config/VSCodium/User"
  "$HOME/.local/{bin,etc,include,lib,share,opt,var}"
  "$HOME/.local/share/{man/man{1..9}}"
  "$HOME/.ssh"
)

__sys_dir_struct=(
  "/usr/local/{bin,etc,include,lib,share,var}"
  "/usr/local/share/dict"
)


#
# --==## FUNCTIONS ##==--
#

bootstrap_macos() {
  if ! type xcode-select >/dev/null 2>&1; then
    xcode-select --install
  fi

  if ! type brew >/dev/null 2>&1; then
    ruby -e "$(curl -fsSL "$__github_raw_url"/Homebrew/install/master/install)"
  fi

  brew update
  brew install git

  git_clone_repo "$__tmp_repo" "$__bootstrap_repo"
  pushd "$__tmp_repo"/packages/MacOS >/dev/null 2>&1
  brew bundle install Brewfile
  popd >/dev/null 2>&1
  brew cleanup

  # shellcheck disable=SC1090
  . "$__tmp_repo"/confs/macos.sh
}


bootstrap_fedora() {
  local xdg_desktop os_majver
  local pkgs_dir="$__tmp_repo/packages/Fedora" pkgs_common pkgs_desktop

  os_majver="$(rpm -E %fedora)"

  # install Git in order to clone this repo
  sudo dnf install git -y
  git_clone_repo "$__tmp_repo" "$__bootstrap_repo"

  # update system
  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-"$os_majver"-primary
  sudo dnf upgrade -y

  if ! type brew >/dev/null 2>&1; then
    sh -c "$(curl -fsSL "$__github_raw_url"/Linuxbrew/install/master/install.sh)"
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
    export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
    export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
  fi

  # install repositories
  sudo dnf install -y \
    fedora-workstation-repositories \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$os_majver".noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$os_majver".noarch.rpm
  sudo dnf config-manager --add-repo=https://negativo17.org/repos/fedora-spotify.repo
  sudo dnf config-manager --set-enabled google-chrome

  # update and install packages
  sudo dnf clean all
  while ! sudo dnf makecache; do sudo dnf clean all; done

  # determine desktop environment (i.e. Gnome, KDE)
  xdg_desktop="$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')"

  # create list of appropriate packages to install
  readarray -t pkgs_common < "$pkgs_dir"/common
  readarray -t pkgs_desktop < "$pkgs_dir"/"$xdg_desktop"

  # install packages from DNF
  sudo dnf install -y --allowerasing "${pkgs_common[@]}" "${pkgs_desktop[@]}"
  sudo dnf upgrade -y

  # install packages from Homebrew
  pushd "$__tmp_repo"/packages/Fedora >/dev/null 2>&1
  brew bundle install Brewfile
  popd >/dev/null 2>&1
  brew cleanup

  # desktop configuration
  case "$xdg_desktop" in
    gnome)
      dconf load /org/gnome/ < "$__tmp_repo"/confs/gnome.dconf
      ;;
    kde)
      # shellcheck disable=SC1090
      . "$__tmp_repo"/confs/kde.sh
      ;;
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
    stow -d "$__dotfiles_dir" -t "$HOME" "$1" "$dir"
  done
}


#
# --==## MAIN ##==--
#

# make home directory structure
for directory in "${__home_dir_struct[@]}"; do
  eval "mkdir -p $directory"
done


# make system directory structure
sudo chown -R "$__user" /usr/local
sudo chmod -R 755 /usr/local
for directory in "${__sys_dir_struct[@]}"; do
  eval "mkdir -p $directory"
done


# initial bootstraps
case "$(uname -s)" in
  Darwin) bootstrap_macos ;;
   Linux) bootstrap_fedora ;;
esac


# install python packages
python3 -m pip install -U --user -r "$__tmp_repo"/packages/requirements.txt


# install custom dictionary
command cp -f "$__tmp_repo"/assets/words /usr/local/share/dict/


# clone dotfiles repository
git_clone_repo "$__dotfiles_dir" "$__dotfiles_repo"


# install post-merge hook and run
command cp -f "$__tmp_repo"/assets/post-merge "$__dotfiles_dir"/.git/hooks/
chmod u+x "$__dotfiles_dir"/.git/hooks/post-merge
pushd "$__dotfiles_dir" >/dev/null 2>&1
# when false, executable bit changes are ignored by Git
git config core.fileMode false
./.git/hooks/post-merge
popd >/dev/null 2>&1


# stow all packages in dotfiles
pushd "$__dotfiles_dir" >/dev/null 2>&1

if git branch -a | grep -qE "$__localhost" >/dev/null 2>&1; then
  # local hostname branch exists: go ahead and stow
  git checkout master
  stow_packages ""
else
  # no hostname branch: create one and backup configs
  git checkout -b "$__localhost"
  stow_packages "--adopt"
  git add -A
  if git commit --dry-run >/dev/null 2>&1; then
    # only commit if there are changes to commit
    git commit -m "Backup dotfiles for $__localhost."
  fi
  git checkout master
  # reset any submodules to dotfiles-specified commit
  git submodule foreach git checkout . >/dev/null 2>&1
fi

popd >/dev/null 2>&1


# Generate .bashrc and .bash_profile
"$HOME"/.local/bin/generate-dotfiles
# shellcheck disable=SC1090
. "$HOME/.bash_profile"
