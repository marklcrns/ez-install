#!/usr/bin/env bash

################################################################################
# Bash array manipulation utility functions
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script for efficient bash script writing.
#
################################# Functions ###################################
#
# array_has_element()
#
################################################################################
# Author : Mark Lucernas <https://github.com/marklcrns>
# Date   : 2021-06-01
################################################################################


if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${COMMON_ARRAY_SH_INCLUDED+x}" ]] \
  && readonly COMMON_ARRAY_SH_INCLUDED=1 \
  || return 0


# Check if an element is in array
# @param $1   Element to find
# @param $2   Array variable to search from
# @return     Return 0 if the element is in array, else 1
array_has_element() {
  local match="$1"
  shift 1

  local arr=
  for arr; do
    [[ "$arr" == "$match" ]] && return 0
  done
  return 1
}
