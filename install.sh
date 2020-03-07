#!/bin/bash
#
# See https://github.com/walkerjam/jgdots
#

SCRIPT_PATH="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
DOTFILES_URL='https://github.com/walkerjam/jgdots/releases/latest/download/dotfiles.tar.gz'
DOTFILES_UNPACK_PREFIX='dotfiles'

# If non-empty, the following var will output extra text
VERBOSE_OUTPUT=
# If non-empty, the following var will use the local repo for source files instead of the github asset
INSTALL_LOCAL=

# Convenience functions
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
function print_status() {
  echo "${green}${1}${reset}"
}
function print_verbose() {
  local indent=${2-}
  if [ ! -z $VERBOSE_OUTPUT ]; then
    echo "${yellow}${indent}${1}${reset}"
  fi
}
function print_error() {
  echo "${red}${1}${reset}"
}
function exit_with_error() {
  print_error "$1"
  if [[ $2 > 0 ]]; then
    exit $2
  fi
}
function usage() {
  echo "Usage: $( basename $0 ) [-l] [-v]"
  echo ""
  echo "Options:"
  echo "  -l             Install from local files (instead of downloading from source"
  echo "                 repo). This is helpful for debugging or if you've cloned the"
  echo "                 repo already."
  echo "  -v             Verbose output."
}

# Parse command line options
while getopts ":lv" opt; do
  case ${opt} in
    l) INSTALL_LOCAL=1
      ;;
    v) VERBOSE_OUTPUT=1
      ;;
    \?) usage
        exit 0
      ;;
  esac
done

# Get (remote or local) and then unpack the dotfiles to a temp dir.
function get_dotfiles() {
  local targetDir="$1"
  if [ -z $targetDir ]; then exit_with_error "Target dir was not provided"; fi

  print_status "Fetching dotfiles"
  print_verbose "Saving to $targetDir"
  if [ ! -z $INSTALL_LOCAL ]; then
    print_verbose "Operating locally"
    tar -czvf "${targetDir}/dotfiles.tar.gz" dotfiles
  else
    wget -q -P $targetDir "$DOTFILES_URL" || \
      exit_with_error "Failed to download dotfiles" 1
  fi

  print_status "Unpacking dotfiles"
  local tarFile=$( find "$targetDir" -type f )
  print_verbose "Tarfile is $tarFile"
  tar -xz -C $targetDir -f $tarFile || \
    exit_with_error "Failed to unpack dotfiles" 2
}

# Iterate over the extracted dotfiles, overlaying platform-specific
# files on top of the core files.
function prepare_dotfiles() {
  local targetDir="$1"
  if [ -z $targetDir ]; then exit_with_error "Target dir was not provided"; fi

  print_status "Preparing dotfiles"
  local sourceDir="${targetDir}/${DOTFILES_UNPACK_PREFIX}"
  local prepareDir="${targetDir}/prepare"
  print_verbose "Preparing dotfiles in $prepareDir"
  mkdir -p "$prepareDir" || \
    exit_with_error "Failed to create prepareDir" 3

  # First copy any common files into the prepare directory
  local commonDir="${sourceDir}/common"
  print_verbose "Common dir is $commonDir" "  "
  for dotfile in $( find $commonDir -type f ); do
    print_verbose "Found $dotfile" "    "
    dotfileRelPath=$( echo "$dotfile" | sed -n "s|^$commonDir/||p" )
    print_verbose "Preparing $dotfileRelPath" "      "
    subdir=$( dirname $dotfileRelPath )
    if [ "." != $subdir ]; then
      newDir="${prepareDir}/${subdir}"
      print_verbose "Creating $newDir" "      "
      mkdir -p $newDir \
        || exit_with_error "Failed to create dir $newDir" 4
    fi
    cp $dotfile "${prepareDir}/${dotfileRelPath}" \
      || exit_with_error "Failed to write file ${prepareDir}/${dotfileRelPath}" 4
  done

  # Now copy any platform-specific files into the prepare directory. If a file already
  # exists (since it's also a core file), then simply concatenate the content onto
  # the existing file.
  local platformDir="${sourceDir}/$( uname )"
  print_verbose "Platform dir is $platformDir" "  "
  for dotfile in $( find $platformDir -type f ); do
    print_verbose "Found $dotfile" "    "
    dotfileRelPath=$( echo "$dotfile" | sed -n "s|^$platformDir/||p" )
    print_verbose "Preparing $dotfileRelPath" "      "
    subdir=$( dirname $dotfileRelPath )
    if [ "." != $subdir ]; then
      newDir="${prepareDir}/${subdir}"
      print_verbose "Creating $newDir" "      "
      mkdir -p $newDir \
        || exit_with_error "Failed to create dir $newDir" 4
    fi
    if [ -f "${prepareDir}/${dotfileRelPath}" ]; then
      cat $dotfile >> "${prepareDir}/${dotfileRelPath}" \
      || exit_with_error "Failed to append file ${prepareDir}/${dotfileRelPath}" 5
    else
      cp $dotfile "${prepareDir}/${dotfileRelPath}" \
        || exit_with_error "Failed to write file ${prepareDir}/${dotfileRelPath}" 6
    fi
  done
}

# Start by fetching an archive of the dotfiles into a temp dir.  We'll do all our
# preparations there, and once everything is clean we'll prompt to copy and overwrite
# any existing files.
tempDir=$( mktemp -d )
get_dotfiles $tempDir
prepare_dotfiles $tempDir
