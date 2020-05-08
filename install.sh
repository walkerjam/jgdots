#!/bin/bash
#
# See https://github.com/walkerjam/jgdots
#

DOTFILES_URL=${JGDOTS_DOTFILES_URL:-'https://github.com/walkerjam/jgdots/releases/latest/download/dotfiles.tar.gz'}
DOTFILES_UNPACK_PREFIX='dotfiles'
DOTFILES_BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/jgdots"

# If non-empty, the following var will output extra text
VERBOSE_OUTPUT=${JGDOTS_VERBOSE_OUTPUT:-}
# If non-empty, the following var will use the local repo for source files instead of the github asset
INSTALL_LOCAL=

# Convenience functions
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`
function print_status() {
  local indent=${2:-}
  echo "${green}${indent}${1}${reset}"
}
function print_prompt() {
  local indent=${2:-}
  echo "${blue}${indent}${1}${reset}"
}
function print_verbose() {
  local indent=${2:-}
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
  else
    exit 99
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
  echo ""
  echo "ENV vars:"
  echo "  JGDOTS_DOTFILES_URL      Overrides the URL to fetch the dotfile tarball"
  echo "  JGDOTS_VERBOSE_OUTPUT    Activates verbose output if set to anything non-empty"
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

function prompt_continue_or_abort() {
  local prompt="${1:-Acknowldege}"
  local indent="${2:-}"
  while true; do
    print_prompt "$prompt" "$indent"
    print_prompt "Continue [c], Abort [a]: " "$indent  "
    read choice
    case $choice in
      [Cc]* ) print_verbose "Continuing" "$indent    "
              break;;
      [Aa]* ) print_verbose "Aborting" "$indent    "
              exit 0;;
      * ) ;;
    esac
  done
}

# Check prerequisites
function check_prereqs() {
  print_status "Checking pre-requisites"

  print_status "Checking for oh-my-zsh" "  "
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    prompt_continue_or_abort "Not found" "    "
  fi

  print_status "Checking for powerlevel9000" "  "
  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel9k" ]; then
    prompt_continue_or_abort "Not found" "    "
  fi
}

# Get (remote or local) and then unpack the dotfiles to a temp dir.
function get_dotfiles() {
  local targetDir="$1"
  if [ -z $targetDir ]; then exit_with_error "Target dir was not provided" 10; fi

  print_status "Fetching dotfiles"
  print_verbose "Saving to $targetDir"
  if [ ! -z $INSTALL_LOCAL ]; then
    print_verbose "Operating locally"
    tar -czf "${targetDir}/dotfiles.tar.gz" dotfiles
  else
    wget -q -P $targetDir "$DOTFILES_URL" || \
      exit_with_error "Failed to download dotfiles" 11
  fi

  print_status "Unpacking dotfiles"
  local tarFile=$( find "$targetDir" -type f )
  print_verbose "Tarfile is $tarFile"
  tar -xz -C $targetDir -f $tarFile || \
    exit_with_error "Failed to unpack dotfiles" 12
}

# Iterate over the extracted dotfiles, overlaying platform-specific
# files on top of the core files.
function prepare_dotfiles() {
  local targetDir="$1"
  if [ -z $targetDir ]; then exit_with_error "Target dir was not provided" 20; fi

  print_status "Preparing dotfiles"
  local sourceDir="${targetDir}/${DOTFILES_UNPACK_PREFIX}"
  local prepareDir="${targetDir}/prepare"
  print_verbose "Preparing dotfiles in $prepareDir"
  mkdir -p "$prepareDir" || \
    exit_with_error "Failed to create prepareDir" 21

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
        || exit_with_error "Failed to create dir $newDir" 22
    fi
    cp $dotfile "${prepareDir}/${dotfileRelPath}" \
      || exit_with_error "Failed to write file ${prepareDir}/${dotfileRelPath}" 23
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
        || exit_with_error "Failed to create dir $newDir" 24
    fi
    if [ -f "${prepareDir}/${dotfileRelPath}" ]; then
      cat $dotfile >> "${prepareDir}/${dotfileRelPath}" \
      || exit_with_error "Failed to append file ${prepareDir}/${dotfileRelPath}" 25
    else
      cp $dotfile "${prepareDir}/${dotfileRelPath}" \
        || exit_with_error "Failed to write file ${prepareDir}/${dotfileRelPath}" 26
    fi
  done
}

function backup_file() {
  local absFilePath="$1"
  if [ -z $absFilePath ]; then exit_with_error "Absolute file path was not provided" 40; fi
  local backupDir="$2"
  if [ -z $backupDir ]; then exit_with_error "Backup dir was not provided" 41; fi

  print_verbose "Backing up $absFilePath" "      "
  local fileDir=$( dirname $absFilePath )
  local fileBackupDir="${backupDir}${fileDir}"
  mkdir -p $fileBackupDir \
    || exit_with_error "Unable to create backup dir $fileBackupDir" 42
  local dateSuffix=$( date "+%Y%m%d%H%M%S" )
  local backupFile="${backupDir}${absFilePath}-${dateSuffix}"
  print_verbose "Copying to $backupFile" "        "
  cp $absFilePath $backupFile \
    || exit_with_error "Unable to create backup file $backupFile" 43
}

function install_dotfiles() {
  local targetDir="$1"
  if [ -z $targetDir ]; then exit_with_error "Target dir was not provided" 30; fi

  # Ensure that we have a backup dir
  print_verbose "Using backup dir $DOTFILES_BACKUP_DIR"
  if [ ! -d "$DOTFILES_BACKUP_DIR" ]; then
    print_verbose "Creating backup dir $DOTFILES_BACKUP_DIR"
    mkdir -p $DOTFILES_BACKUP_DIR \
      || exit_with_error "Failed to create backup dir $DOTFILES_BACKUP_DIR" 31
  fi

  print_status "Installing dotfiles"
  local prepareDir="${targetDir}/prepare"
  local homeDir="$HOME"
  print_verbose "Home dir is $homeDir"
  if [ -z "$homeDir" ]; then exit_with_error "Unable to find home dir" 32; fi
  for dotfile in $( find $prepareDir -type f ); do
    print_verbose "Found $dotfile" "  "
    dotfileRelPath=$( echo "$dotfile" | sed -n "s|^$prepareDir/||p" )
    subdir=$( dirname $dotfileRelPath )
    print_verbose "Checking $dotfileRelPath" "    "
    existingFile="${homeDir}/${dotfileRelPath}"
    if [ ! -f $existingFile ]; then
      print_verbose "Installing $existingFile" "      "
      newDir=$( dirname $existingFile )
      mkdir -p $newDir \
        || exit_with_error "Failed to create $newDir" 33
      cp $dotfile $existingFile \
        || exit_with_error "Failed to install $existingFile" 34
    else
      print_verbose "File already exists as $existingFile" "      "

      # Check if the file is actually different
      if cmp --quiet $dotfile $existingFile; then
        print_verbose "Files are the same" "        "
      else
        print_verbose "Files are different" "        "
        while true; do
          print_prompt "$existingFile already exits"
          print_prompt "Overwrite [o], Append [a], Skip [s]: " "  "
          read choice
          case $choice in
            [Oo]* ) print_verbose "Overwriting" "    "
                    backup_file $existingFile $DOTFILES_BACKUP_DIR
                    cp -f $dotfile $existingFile \
                      || exit_with_error "Failed to overwrite $existingFile" 35
                    break;;
            [Aa]* ) print_verbose "Appending" "    "
                    backup_file $existingFile $DOTFILES_BACKUP_DIR
                    cat $dotfile >> $existingFile \
                      || exit_with_error "Failed to append $existingFile" 36
                    break;;
            [Ss]* ) print_verbose "Skipping" "    "
                    break;;
            * ) ;;
          esac
        done
      fi
    fi
  done
}

check_prereqs

# Start by fetching an archive of the dotfiles into a temp dir.  We'll do all our
# preparations there, and once everything is clean we'll prompt to copy and overwrite
# any existing files.
tempDir=$( mktemp -d )
get_dotfiles $tempDir
prepare_dotfiles $tempDir
install_dotfiles $tempDir

print_status "✓ Done"
print_status "Don't forget to start a new shell to activate your changes." "  "
print_status "Also, run ~/bin/personalize.sh 😃" "  "
