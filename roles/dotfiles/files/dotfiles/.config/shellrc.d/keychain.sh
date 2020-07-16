keys="id_develop id_home"

if [[ "$_OSTYPE" == "darwin" ]]; then
  eval "$(keychain --eval --ignore-missing --quiet --inherit any "${keys}")"
else
  eval "$(keychain --eval --ignore-missing --quiet "${keys}")"
fi