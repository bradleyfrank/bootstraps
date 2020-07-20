case "$_OSTYPE" in
  darwin) _kc_args="--inherit any" ;;
   linux) _kc_args=""               ;;
esac

eval "$(keychain --eval --ignore-missing --quiet "$_kc_args" id_rsa id_develop id_home)"