#!/bin/bash

[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

alias glances='glances --theme-white'
alias groot='cd $(git rev-parse --show-toplevel)'
alias ll='ls -lAhF --color=auto'
alias lsmnt='mount | column -t'
alias nbl='grep -Erv "(^#|^$)"'
alias proc='ps -e --forest -o pid,ppid,user,cmd'
alias sane='stty sane'
alias wget='wget -c'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

shopt -s checkwinsize
shopt -s cdspell
shopt -s histappend

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set show-all-if-ambiguous on"
bind "set mark-symlinked-directories on"
bind "set visible-stats on"

export HISTFILESIZE=
export HISTSIZE=
export HISTCONTROL="erasedups:ignoreboth:ignorespace"
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
export HISTTIMEFORMAT='%F %T '

# quick and dirty docker-compose linter
clint() {
  docker-compose -f "$1" config --quiet
}

# decrypt a file using openssl
decrypt() {
  openssl enc -d -aes-256-cbc -in "$1" -out "$1.decrypted"
}

# encrypt a file using openssl
encrypt() {
  openssl enc -aes-256-cbc -salt -in "$1" -out "$1.encrypted"
}

# show website http headers; follow redirects
httptrace() {
  curl -s -L -D - "$1" -o /dev/null -w "%{url_effective}\n"
}

# tar and gzip a given directory
tardir() {
  tar -czf "${1%/}".tar.gz "$1"
}

export_ps1() {
  reset="\[\e[0;0m\]" blue="\[\e[38;5;33m\]" red="[\[\e[38;5;160m\]" orange="\[\e[38;5;208m\]"
  case "$(type -t __git_ps1)" in
    function) git_branch="${orange}$(__git_ps1)${reset}" ;;
    *)        git_branch="" ;;
  esac
  PS1="${red}\h${reset}:${blue}\W${reset}]${git_branch}# "
}

PROMPT_COMMAND="export_ps1; history -a; history -n"