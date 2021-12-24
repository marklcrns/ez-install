#!/usr/bin/env bash

################################################################################
# Collection of bash script functions for detailed output and debugging.
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script for efficient bash script writing.
#
################################# Functions ###################################
#
# ok()       = Echo message in COLOR_GREEN characters.
# finish()   = Echo message in COLOR_GREEN characters and exit with 0 exit code.
# warning()  = Echo message in COLOR_YELLOW characters.
# abort()    = Echo message in COLOR_YELLOW characters and exit with 0 exit code.
# error()    = Echo message in COLOR_RED characters and exit with 1 exit code by
#              default. Also accepts integer to override default exit code.
# execlog()  = Execute string command with `eval` and log into LOG_FILE_PATH.
#
################################################################################
# Author : Mark Lucernas <https://github.com/marklcrns>
# Date   : 2020-08-13
################################################################################


if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${UTILS_ACTIONS_SH_INCLUDED+x}" ]] \
  && readonly UTILS_ACTIONS_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/../../common/log.sh"
source "${BASH_SOURCE%/*}/../../common/string.sh"


# Logs NOTICE message on VERBOSE.
ok() {
  local message="${1:-}"
  log 'notice' "${message}"
}

# Logs WARN message on VERBOSE.
warning() {
  local message="${1:-}"
  log 'warn' "${message}"
}

# Logs WARN message on VERBOSE then exit 0.
abort() {
  local message="${1:-}"
  log 'warn' "${message}"
  exit 0
}

# Logs NOTICE message on VERBOSE then exit 0.
finish() {
  local message="${1:-}"
  log 'notice' "${message}"
  exit 0
}

# $2 argument accepts integer to exit with exit code.
# Logs ERROR message on VERBOSE then exit $2.
error() {
  local message="${1:-}"
  log 'error' "${message}" ${2:-0}
}

# Execute message then log DEBUG on VERBOSE.
execlog() {
  local command="${1:-}"

  strip_ansi_codes command
  log 'debug' "${command}"

  if "${VERBOSE}"; then
    eval "${command}"
  else
    eval "${command}" >/dev/null 2>&1
  fi

  return ${?}
}

