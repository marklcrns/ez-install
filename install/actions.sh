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
# NOTE: All functions has force_silent local variable to disable function
# outputs.
#
################################# DEPENDENCIES #################################
#
# ./colors  Pre-defined global variables for colorful string
#           outputs.
#
########################### Script Global Variables ############################
#
# DEBUG           = Enables logging of all log functions.
# LOG_FILE_DIR    = Log file directory path
# LOG_FILE_PATH   = Log file destination path.
# IS_SILENT       = Disables output of all functions.
# IS_VERY_VERBOSE = Enables output of log() function.
# SCRIPTPATH      = Script absolute path `realpath -s $0`.
# COLOR_RED       = ANSI red color code.
# COLOR_GREEN     = ANSI green color code.
# COLOR_YELLOW    = ANSI yellow color code.
# COLOR_PURPLE    = ANSI purple color code.
# COLOR_BO_NC     = ANSI bold color code.
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
[[ -z "${INSTALL_LOGGER_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_LOGGER_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/../common/log.sh"
source "${BASH_SOURCE%/*}/../common/string.sh"


# Logs NOTICE message on VERBOSE.
function ok() {
  if [[ -t 0 ]]; then
    local message="${1:-}"
    log 'notice' "${message}"
  else
    read IN
    log 'notice' "${IN}"
  fi
}

# Logs WARN message on VERBOSE.
function warning() {
  if [[ -t 0 ]]; then
    local message="${1:-}"
    log 'warn' "${message}"
  else
    read IN
    log 'warn' "${IN}"
  fi
}

# Logs WARN message on VERBOSE then exit 0.
function abort() {
  if [[ -t 0 ]]; then
    local message="${1:-}"
    log 'warn' "${message}"
  else
    read IN
    log 'warn' "${IN}"
  fi
  exit 0
}

# Logs NOTICE message on VERBOSE then exit 0.
function finish() {
  if [[ -t 0 ]]; then
    local message="${1:-}"
    log 'notice' "${message}"
  else
    read IN
    log 'notice' "${IN}"
  fi
  exit 0
}

# $2 argument accepts integer to exit with exit code.
# Logs ERROR message on VERBOSE then exit $2.
function error() {
  if [[ -t 0 ]]; then
    local message="${1:-}"
    log 'error' "${message}" 1
    shift 1
  else
    read IN
    log 'error' "${IN}" 1
  fi

  [[ "${1:-0}" -gt 0 ]] && exit ${1}
}

# Execute message then log DEBUG on VERBOSE.
function execlog() {
  local command=
  if [[ -t 0 ]]; then
    command="${1:-}"
  else
    read IN
    command="${IN:-}"
  fi

  strip_ansi_codes command
  log 'debug' "${command}"

  if "${VERBOSE}"; then
    eval "${command}"
  else
    eval "${command}" >/dev/null 2>&1
  fi

  return ${?}
}

