#!/usr/bin/env bash

function fail {
  declare msg="$1"
  echo "$msg" 1>&2
  echo "Exiting..."
  exit 1
}

set -exuo pipefail

# check for xcode
# not sure if com.apple.pkg.XcodeMAS_iOSSDK_6_1 is universal, but that's what it is on my machine right now
#pkgutil --pkg-info=com.apple.pkg.XcodeMAS_iOSSDK_6_1 > /dev/null 2>&1 || fail "Xcode not insalled.  See README.md."
# check for xcode cli
#pkgutil --pkg-info=com.apple.pkg.DeveloperToolsCLI   > /dev/null 2>&1 || fail "Xcode CLI not insalled.  See README.md."
# check for brew
type brew > /dev/null 2>&1 || fail "brew is not installed!  See README.md."

cd "$(dirname "$0")"

declare -r BASEDIR="$PWD"
declare -r FILE_FORMULA="$BASEDIR"/formulae
declare -r FILE_FORCE_LINK="$BASEDIR"/force-link
declare -r FILE_TAP="$BASEDIR"/tap
declare -r MY_ETC="$BASEDIR"/etc
declare -r MY_BREW_BASE="$BASEDIR"/brew-base
declare -r BREW_BASE="$(brew --prefix)"

function installFormula {
  comm -13 <(brew tap | sort) <(sort "$FILE_TAP") |
  while read tap; do
    brew tap "$tap" || fail "Unable to add tap: $tap"
  done

  comm -13 <(brew list) "$FILE_FORMULA" |
  while read formula; do
    brew install "$formula" || fail "Unable to complete installation of formula: $formula"

    # find any keg-only formulae
    if brew info "$formula" | grep 'formula is keg-only' > /dev/null 2>&1; then
      brew link --force "$formula" || fail "Unable to force linking of force-link formula: $formula"
    fi
  done
}

function linkEtc {
  for file in "$MY_ETC"/*; do
    typeset filebase="${file##*/}"
    [[ -L /etc/$filebase ]] && sudo rm -f "/etc/$filebase"
    [[ -e /etc/$filebase ]] && fail "System file /etc/$filebase already exists.  This script will not overwrite it.  Please save it off or remove it and re-run this script"
    sudo ln -s "$file" /etc/
  done
}

function linkBrewBase {
  # Right now all I have is the etc dir.  I'll add more if it's needed
  find "$MY_BREW_BASE" -type f |
  while read -r file; do
    file="${file#$MY_BREW_BASE/}"

    [[ -L $BREW_BASE/$file ]] && rm -f "$BREW_BASE/$file"
    [[ -e $BREW_BASE/$file ]] && fail "Homebrew file '$BREW_BASE/$file' already exists.  This script will not overwrite it.  Please save it off or remove it and re-run this script"
    ln -s "$MY_BREW_BASE"/"$file" "$BREW_BASE"/"${file%/*}"
  done
}

installFormula
linkEtc
linkBrewBase
