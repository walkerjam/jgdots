#!/bin/bash
#
# See https://github.com/walkerjam/jgdots
#

# If non-empty, the following var will output extra text
DEBUG_OUTPUT=1
# If non-empty, the following var will use the local repo for source files instead of the github asset
DEBUG_LOCAL=1
DOTFILES_URL='https://github.com/walkerjam/jgdots/releases/latest/download/dotfiles.tar.gz'
DOTFILES_UNPACK_PREFIX='dotfiles'

# Convenience functions
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
function print_status() {
  echo "${green}${1}${reset}"
}
function print_debug() {
  if [ ! -z $DEBUG_OUTPUT ]; then
    echo "${yellow}${1}${reset}"
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

# Start by fetching an archive of the dotfiles into a temp dir.  We'll do all our
# preparations there, and once everything is clean we'll prompt to copy and overwrite
# any existing files.
print_status "Fetching dotfiles"
tempDir=$( mktemp -d )
print_debug "Saving to $tempDir"
if [ ! -z $DEBUG_LOCAL ]; then
  print_debug "Operating locally"
  tar -czvf "${tempDir}/dotfiles.tar.gz" dotfiles
else
  wget -q -P $tempDir "$DOTFILES_URL" || \
    exit_with_error "Failed to download dotfiles" 1
fi

print_status "Unpacking dotfiles"
tarFile=$( find "$tempDir" -type f )
print_debug "Tarfile is $tarFile"
tar -xz -C $tempDir -f $tarFile || \
  exit_with_error "Failed to unpack dotfiles" 2

print_status "Preparing dotfiles"
sourceDir="${tempDir}/${DOTFILES_UNPACK_PREFIX}"
prepareDir="${tempDir}/prepare"
print_debug "Preparing dotfiles in $prepareDir"
mkdir -p "$prepareDir" || \
  exit_with_error "Failed to create prepareDir" 3

# First copy any common files into the prepare directory
commonDir="${sourceDir}/common"
platformDir="${sourceDir}/$( uname )"
print_debug "Common dir is $commonDir"
print_debug "Platform dir is $platformDir"
for dotfile in $( find $commonDir -type f ); do
  print_debug "Found common $dotfile"
  dotfileRelPath=$( echo "$dotfile" | sed -n "s|^$commonDir/||p" )
  print_debug "Preparing $dotfileRelPath"
  subdir=$( dirname $dotfileRelPath )
  if [ "." != $subdir ]; then
    newDir="${prepareDir}/${subdir}"
    print_debug "Creating $newDir"
    mkdir -p $newDir \
      || exit_with_error "Failed to create dir $newDir" 4
  fi
  cp $dotfile "${prepareDir}/${dotfileRelPath}" \
    || exit_with_error "Failed to write file ${prepareDir}/${dotfileRelPath}" 4
done

# Now copy any platform-specific files into the prepare directory. If a file already
# exists (since it's also a core file), then simply concatenate the content onto
# the existing file.
for dotfile in $( find $platformDir -type f ); do
  print_debug "Found platform $dotfile"
  dotfileRelPath=$( echo "$dotfile" | sed -n "s|^$platformDir/||p" )
  print_debug "Preparing $dotfileRelPath"
  subdir=$( dirname $dotfileRelPath )
  if [ "." != $subdir ]; then
    newDir="${prepareDir}/${subdir}"
    print_debug "Creating $newDir"
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
