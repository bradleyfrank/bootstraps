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
__xdg_desktop=""


#
# --==## SETUP ##==--
#

cleanup() {
  rm -rf "$__tmp_repo"
}

trap cleanup EXIT

case "$OSTYPE" in
  "darwin"*) __os="macos" ;;
   "linux"*) __os="linux" ;;
          *) printf '%s\n' "Unknown OS detected, aborting..." >&2 ; exit 1 ;;
esac


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
  local os_majver pkgs_common pkgs_desktop

  os_majver="$(rpm -E %fedora)"

  # install Git in order to clone this repo
  sudo dnf install git -y
  git_clone_repo "$__tmp_repo" "$__bootstrap_repo"

  # update system
  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-"$os_majver"-primary
  sudo dnf upgrade -y

  # install repositories
  sudo dnf install -y \
    fedora-workstation-repositories \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$os_majver".noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$os_majver".noarch.rpm
  sudo dnf config-manager --add-repo="$__tmp_repo"/assets/repos/vscodium.repo
  sudo dnf config-manager --add-repo=https://negativo17.org/repos/fedora-multimedia.repo
  sudo sed -i "/^baseurl=/a includepkgs=spotify\*,makemkv\*,ccextractor\*" \
    /etc/yum.repos.d/fedora-multimedia.repo
  sudo dnf config-manager --set-enabled google-chrome
  sudo dnf copr enable -y dawid/better_fonts
  sudo dnf copr enable -y taw/joplin

  # update and install packages
  while ! sudo dnf makecache; do sudo dnf clean all; done

  # determine desktop environment (e.g. Gnome, KDE)
  __xdg_desktop="$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')"

  # create list of appropriate packages to install
  readarray -t pkgs_common < "$__tmp_repo"/packages/Fedora/common
  readarray -t pkgs_desktop < "$__tmp_repo"/packages/Fedora/"$__xdg_desktop"

  # install packages from DNF
  sudo dnf install -y --allowerasing "${pkgs_common[@]}" "${pkgs_desktop[@]}"
  sudo dnf upgrade -y

  # copy wallpaper to home directory
  command cp -f "$__tmp_repo"/assets/f22.jpg "$HOME"/Pictures/

  # desktop configuration
  case "$__xdg_desktop" in
         gnome) dconf load / < "$__tmp_repo"/confs/"$__xdg_desktop".dconf ;;
           kde) . "$__tmp_repo"/confs/"$__xdg_desktop".sh ;;
    x-cinnamon) dconf load / < "$__tmp_repo"/confs/"$__xdg_desktop".dconf ;;
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

install_gnome_extensions() {
  # make the output an array to correctly pass params to install script
  while read -r line || [[ -n "$line" ]]; do
    extensions+=( "$(echo "$line" | grep -Eo '^[0-9]+')" )
  done < "$__tmp_repo"/packages/gnome-extensions
  "$HOME"/.local/bin/install_gnome_extension "${extensions[@]}"
}

install_vscode_extensions() {
  vscode_binary="$1"
  while read -r vs_extension || [[ -n "$vs_extension" ]]; do
    "$vscode_binary" --install-extension "$vs_extension"
  done < "$__tmp_repo"/packages/vscode-extensions
}

stow_packages() {
  for dir in */; do
    [[ "$dir" =~ ^\. ]] && continue
    stow -d "$__dotfiles_dir" -t "$HOME" --no-folding "$1" "$dir"
  done
}


#
# --==## MAIN ##==--
#

# prep home directory structure
mkdir -p "$HOME"/Development/Home

# initial bootstraps
case "$__os" in
  macos) bootstrap_macos ;;
  linux) bootstrap_fedora ;;
esac

# install python packages
python3 -m pip install -U --user -r "$__tmp_repo"/packages/requirements.txt

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

# install root user configs
sudo rsync -r "$__tmp_repo"/assets/root/ /root/

# extra steps if a Linux system
if [[ "$__os" == "linux" ]]; then
  # install gnome extensions
  [[ "$__xdg_desktop" == "gnome" ]] && install_gnome_extensions
fi

# install vscode extensions
case "$__os" in
  macos) install_vscode_extensions "/usr/bin/local/code" ;;
  linux) install_vscode_extensions "/usr/bin/codium" ;;
esac
