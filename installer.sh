#!/usr/bin/env bash

function fail {
  typeset msg="$1"
  echo "$msg" 1>&2
  echo "Exiting..."
  exit 1
}

function checkLink {
  typeset -r LOCATION="$1"

  [[ -L $LOCATION ]] && return 1 # check for link first, because it's not an error if it's a link
  [[ -e $LOCATION ]] && fail "System file $LOCATION already exists.  This script will not overwrite it.  Please remove it and re-run this script."
  return 0
}

cd "$(dirname "$0")"

typeset -r BASE_DIR="$PWD"
typeset -r DOT_FILE_DIR="$BASE_DIR/dot-files"
typeset -r DOT_FILE_DESTINATION_DIR="$HOME"
typeset -r BIN_DIR="$BASE_DIR/bin"
typeset -r USER_BIN_DIR="$HOME/bin"
typeset -r BREW_DIR="$BASE_DIR/brew"
typeset -r SSHRC_DIR="$BASE_DIR/sshrc.d"
typeset -r SSHRC_DESTINATION_DIR="$HOME/.sshrc.d"
typeset -r BREW_INSTALLER="$BREW_DIR/installer.sh"
typeset -r PATHOGEN_BUNDLE_DIR=~/.vim/bundle

command "$BREW_INSTALLER"

if ! [[ -L $USER_BIN_DIR  ]]; then
  if [[ -e $USER_BIN_DIR ]] || ls "$USER_BIN_DIR"/* > /dev/null 2>&1; then
    fail "$USER_BIN_DIR is not empty.  This script will not replace it.  Please remove it to continue."
  else
    ln -s "$BIN_DIR" "$USER_BIN_DIR"
  fi
else
  rm -f "$USER_BIN_DIR"
  ln -s "$BIN_DIR" "$USER_BIN_DIR"
fi

for file in "$DOT_FILE_DIR"/*; do
  destination="$DOT_FILE_DESTINATION_DIR"/."${file##*/}"
  if ! checkLink "$destination"; then # checklink will exit if it's not a link
    rm -f "$destination"
  fi

  ln -s "$file" "$destination"
done

mkdir -p "$PATHOGEN_BUNDLE_DIR"
cd "$PATHOGEN_BUNDLE_DIR"

while read repo; do
  repoShort="${repo##*/}"
  repoShort="${repoShort%%.git}"

  if ! [[ -d $repoShort ]]; then
    git clone "$repo"
  fi
done < "$BASE_DIR"/vim-plugins

if ! [[ -d $SSHRC_DESTINATION_DIR ]]; then
  mkdir "$SSHRC_DESTINATION_DIR"
fi

for file in "$SSHRC_DIR"/*; do
  destination="$SSHRC_DESTINATION_DIR/${file##*/}"
  if ! checkLink "$destination"; then
    rm -f "$destination"
  fi

  ln -s "$file" "$destination"
done
