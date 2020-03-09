#!/bin/bash
#

set -euo pipefail
IFS=$'\n\t'

# Convenience functions
blue=`tput setaf 4`
reset=`tput sgr0`
function print_prompt_oneline() {
  local indent=${2:-}
  echo -n "${blue}${indent}${1}${reset}"
}

yes=""
function prompt_yes_no() {
  local prompt="${1:-Acknowldege}"
  local indent="${2:-}"
  while true; do
    print_prompt_oneline "$prompt [Y/n] " "$indent"
    read choice
    if [ "$choice" == "" ]; then
      yes="1"
      break
    else
      case $choice in
        [Yy]* ) yes="1"
                break;;
        [Nn]* ) yes=""
                break;;
        * ) ;;
      esac
    fi
  done
}

strVal=""
function prompt_str_val() {
  local prompt="${1:-Enter a value}"
  local indent="${2:-}"
  while true; do
    print_prompt_oneline "$prompt " "$indent"
    read choice
    tmpVal=$( echo "$choice" | xargs ) # xargs trims space
    if [ ! -z "$tmpVal" ]; then
      strVal="$tmpVal"
      break
    fi
  done
}

prompt_yes_no "Setup git name and email?"
test $yes && {
  prompt_str_val "First and last name:" "  "
  git config --global user.name "$strVal"
  prompt_str_val "Email address:" "  "
  git config --global user.email "$strVal"
}

exit 0
