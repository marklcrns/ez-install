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


source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/log.sh"
include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"


# Logs INFO message on VERBOSE.
function info() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"

  if ${VERBOSE}; then
    log 'info' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'info' "${message}"
  fi
}

# Logs NOTICE message on VERBOSE.
function ok() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"

  if ${VERBOSE} && ${DEBUG}; then
    log 'notice' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'notice' "${message}"
  fi
}


# Logs NOTICE message on VERBOSE.
function skip() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"

  if ${VERBOSE} && ${DEBUG}; then
    log 'notice' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'notice' "${message}"
  fi
}


# Logs WARN message on VERBOSE then exit 0.
function finish() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"

  if ${VERBOSE} && ${DEBUG}; then
    log 'warn' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'warn' "${message}"
  fi
  exit 0
}

# Logs WARN message on VERBOSE.
function warning() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"

  if ${VERBOSE} && ${DEBUG}; then
    log 'warn' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'warn' "${message}"
  fi
}

# Logs WARN message on VERBOSE then exit 0.
function abort() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"

  if ${VERBOSE} && ${DEBUG}; then
    log 'warn' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'warn' "${message}"
  fi
  exit 0
}

# Logs ERROR message to stderr on VERBOSE then exit $2.
function error() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"
  local exit_code=${2:-$BASH_EX_GENERAL}

  if ${VERBOSE} && ${DEBUG}; then
    log 'error' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${message}"
  else
    log 'error' "${message}"
  fi
  return $exit_code
}


# Execute message then log DEBUG on VERBOSE.
function execlog() {
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local command="${1}"; strip_ansi_code command
  local timeout=${TIMEOUT:-60s}
  local output=""
  local res=0

  if ${VERBOSE} && ${DEBUG}; then
    log 'debug' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}(): ${command}"
  else
    log 'debug' "${command}"
  fi

  # Ref: https://stackoverflow.com/a/17382707
  # NOTE: Redirecting the output of the command as shown in stackoverflow always
  # wait for the watcher to finish regardless if the command finishes or not
  ( ${command} ) & pid=$!
  ( sleep $timeout && kill -TERM $pid ) 2>/dev/null & watcher=$!
  wait $pid 2>/dev/null || res=$?
  pkill -U $watcher

  return $res
}

