#!/usr/bin/env bash

################################################################################
# Collection of bash script functions for detailed output and debugging.
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script for efficient bash script writing.
#
################################# Functions ###################################
#
# action()   = Echo message and log ${log} into LOG_FILE_PATH.
# execlog()  = Execute string command with `eval` and log debug into
#              LOG_FILE_PATH.
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


function info()    { _action -l 'info' "${@}"; }
function ok()      { _action -l 'notice' "${@}"; }
function skip()    { _action -l 'notice' "${@}"; }
function warning() { _action -l 'warn' "${@}"; }
function error()   { _action -l 'warn' "${@}"; }
function finish()  { _action -l 'warn' -e 0 ${@}; }
function abort()   { _action -l 'warn' -e 0 ${@}; }
function crit()    { _action -l 'crit' -e ${BASH_EX_GENERAL} "${@}"; }

function _action() {
  local depth=1
  local log="info"
  local exit_code=

  OPTIND=1
  while getopts "d:e:l:" opt; do
    case ${opt} in
      d) depth=${OPTARG} ;;
      e) exit_code=${OPTARG} ;;
      l) log="${OPTARG}" ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local message="${1}"
  [[ -n "${2+x}" ]] && exit_code=${2}
  depth=$(($depth+1))   # offset wrapper functions

  if ${VERBOSE}; then
    log "${log}" "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}():${BASH_LINENO[${depth}-1]} ${message}"
  else
    log "${log}" "${message}"
  fi

  is_integer $exit_code && exit $exit_code
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
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local command="${1}"; strip_ansi_code command
  local timeout=${TIMEOUT:-15m}
  local output=""
  local res=0

  if ${VERBOSE} && ${DEBUG}; then
    log 'debug' "$(basename -- "${BASH_SOURCE[${depth}]}").${FUNCNAME[${depth}]}():${BASH_LINENO[${depth}-1]} ${command}"
  else
    log 'debug' "${command}"
  fi

  # Ref: https://stackoverflow.com/a/17382707
  # NOTE: Redirecting the output of the command as shown in stackoverflow always
  # wait for the watcher to finish regardless if the command finishes or not
  ( eval "${command}" ) & pid=$!
  ( sleep $timeout && kill -TERM $pid ) 2>/dev/null & watcher=$!
  wait $pid 2>/dev/null || res=$?
  pkill -U $watcher

  return $res
}

