#!/bin/bash

BOOTURL="https://bradleyfrank.github.io/bootstrap/bootstrap.sh"

while getopts 'u:' flag; do
  case "${flag}" in
    u ) USER_ACCOUNT="$OPTARG" ;;
    \?) exit 1 ;;
  esac
done

useradd -g wheel "$USER_ACCOUNT"

cat << EOF > /etc/sudoers.d/100-custom-users
# Created by $USER_ACCOUNT on $(date --rfc-2822)

# Group rules
%wheel ALL=(ALL) NOPASSWD: ALL

# User rules
Defaults:$USER_ACCOUNT    !authenticate
EOF

sudo su - "$USER_ACCOUNT" -c "curl -fsSL $BOOTURL | bash -s -- -x gs"