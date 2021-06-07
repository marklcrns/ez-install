#!/usr/bin/env bash

################################################################################
#
# Bash string manipulation utility functions
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script for efficient bash script writing.
#
################################# Functions ###################################
#
# strip_trailing_forwardslash()
# strip_trailing_backslash()
# strip_extra_whitespace()
# strip_first_of()
# strip_substr()
# has_substr()
# replace_first_of()
# replace_substr()
# to_upper()
# to_lower()
# capitalize()
#
# Sample usage:
#
# # Replace "123" from $var by "321"
# var="some string 123"
# replace_first_of "123" "321" var
# echo $var
#
################################################################################
# Author:   Mark Lucernas <https://github.com/marklcrns>
# Date:     2021-05-31
################################################################################


if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${COMMON_STRING_SH_INCLUDED+x}" ]] \
  && readonly COMMON_STRING_SH_INCLUDED=1 \
  || return 0


# @param $1   String variable reference to strip
# @return     Stripped string variable of trailing forwardslashes
strip_trailing_forwardslash() {
  local __stripped=$(eval "echo \$$1" | sed 's,/*$,,')
  eval "$1='$__stripped'"
}

# @param $1   String variable reference to strip
# @return     Stripped string variable of trailing backslashes
strip_trailing_backslash() {
  local __stripped=$(eval "echo \$$1" | sed 's,\\*$,,')
  eval "$1='$__stripped'"
}

# @param $1   String variable reference to strip
# @return     Stripped string variable of extra whitespaces
strip_extra_whitespace() {
  local __stripped=$(eval "echo \$$1" | xargs)
  eval "$1='$__stripped'"
}

# @param $1   String variable reference to strip
# @return     Stripped string variable of ANSI color codes
# Ref: https://stackoverflow.com/a/18000433
# Also works with '\x1b', '\e' or '\033' escape special character ANSI prefix
# from string literals. e.g. '\x1b[0;31mThis is a test' -> 'This is a test'
strip_ansi_codes() {
  local __stripped=$(eval "echo \"\$$1\"" | sed -r 's/(\x1b|\\x1b|\\e|\\033)\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g')
  eval "$1='$__stripped'"
}

# @param $1   Substring to be stripped from
# @param $2   String variable reference to strip
# @return     Stripped string variable of first match of $2
strip_first_of() {
  local __stripped=$(eval "echo \"\${$2/$1/}\"")
  eval "$2='$__stripped'"
}

# @param $1   Substring to be stripped from
# @param $2   String variable reference to strip
# @return     Stripped string variable of all matches of $2
strip_substr() {
  local __stripped=$(eval "echo -e \"\${$2//$1/}\"")
  eval "$2='$__stripped'"
}

# @param $1   Substring to be find
# @param $2   String variable reference to search
# @return     Return 0 if string variable matches of $2, else 1
has_substr() {
  if [[ "${2}" == *"${1}"* ]]; then
    return 0
  fi
  return 1
}

# @param $1   Pattern to match
# @param $2   Substring to be replace matched substring
# @param $3   String variable reference to replace
# @return     Replaced string variable of matching $1 by $2
replace_first_of() {
  local __replaced=$(eval "echo \${$3/$1/$2}")
  eval "$3='$__replaced'"
}

# @param $1   Pattern to match
# @param $2   Substring to be replace matched substring
# @param $3   String variable reference to replace
# @return     Replaced string variable of all matching $1 by $2
replace_substr() {
  local __replaced=$(eval "echo \${$3//$1/$2}")
  eval "$3='$__replaced'"
}

# @param $1   String variable reference to uppercase
# @return     Uppercased string variable
to_upper() {
  local __upper=$(eval "echo \$$1" | tr '/a-z/' '/A-Z/')
  eval "$1='$__upper'"
}

# @param $1   String variable reference to lowercase
# @return     Lowercased string variable
to_lower() {
  local __lower=$(eval "echo \$$1" | tr '/A-Z/' '/a-z/')
  eval "$1='$__lower'"
}

# @param $1   String variable reference to capitalize
# @return     Capitalized string variable
capitalize() {
  local __lower=$(eval "echo \$$1" | tr '/A-Z/' '/a-z/')
  local __capitalize=$(echo "$__lower" | sed -r 's/\<./\U&/g')
  eval "$1='$__capitalize'"
}

