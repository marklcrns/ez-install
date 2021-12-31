#!/usr/bin/env bash

################################################################################
# Collection of bash script functions for detailed output and debugging.
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script for efficient bash script writing.
#
################################# Functions ###################################
# TODO: Update me
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


[[ -z "${VERBOSE+x}" ]] && VERBOSE=false

# Logs INFO message on VERBOSE.
info() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local message="${1:-}"

  if ${VERBOSE}; then
    log 'info' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'info' "${message}"
  fi
}

# Logs NOTICE message on VERBOSE.
ok() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local message="${1:-}"

  if ${VERBOSE}; then
    log 'notice' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'notice' "${message}"
  fi
}

# Logs NOTICE message on VERBOSE then exit 0.
finish() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local message="${1:-}"

  if ${VERBOSE}; then
    log 'notice' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'notice' "${message}"
  fi
  exit 0
}

# Logs WARN message on VERBOSE.
warning() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local message="${1:-}"

  if ${VERBOSE}; then
    log 'warn' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'warn' "${message}"
  fi
}

# Logs WARN message on VERBOSE then exit 0.
abort() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local message="${1:-}"

  if ${VERBOSE}; then
    log 'warn' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'warn' "${message}"
  fi
  exit 0
}

# Logs ERROR message to stderr on VERBOSE then exit $2.
error() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local message="${1:-}"

  if ${VERBOSE}; then
    log 'error' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}" ${2:-0}
  else
    log 'error' "${message}" ${2:-0}
  fi
}

# Execute message then log DEBUG on VERBOSE.
execlog() {
  local depth=1
  OPTIND=1
  while getopts "d:" opt; do
    case ${opt} in
      d)
        depth=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local command="${1:-}"
  strip_ansi_code command

  if ${VERBOSE}; then
    log 'debug' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${command}"
    eval "${command}"
  else
    log 'debug' "${command}"
    eval "${command}" >/dev/null 2>&1
  fi

  return ${?}
}

