#!/usr/bin/env bash

################################################################################
#
# General purpose Bash Hierarchy Logging utility script.
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script.
#
########################################################### Global Variables ###
#
# LOG_TIMESTAMP_FORMAT  = Date and time format for log timestamp.
# LOG_FILELOG_ENABLE    = Enable file logging.
# LOG_FILELOG_DIR       = Directory to store file log.
# LOG_FILELOG_NAME      = File log filename (exclude file extension)
# LOG_SYSLOG_ENABLE     = Enable system logging (uses built-in `logger`)
# LOG_SYSLOG_TAG        = `logger` tag (defaults to basename)
# LOG_SYSLOG_FACILITY   = `logger` facility (defaults to local0)
# DEBUG_LEVEL           = Debug level to trigger log level. Default = CRIT.
#                         Debug > INFO > NOTICE > WARN > ERROR > CRIT
#                         ALERT, and EMERG are unused and unhandled.
#
###################################################################### Usage ###
#
# log '${log_level}'
#
################################################################################
# Author:   Mark Lucernas <https://github.com/marklcrns>
# Date:     2021-06-03
#
# Credits:  Mike Peachey <https://github.com/Zordrak/bashlog/blob/master/log.sh>
################################################################################

set -o pipefail
set -o nounset

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${COMMON_LOG_SH_INCLUDED+x}" ]] \
  && readonly COMMON_LOG_SH_INCLUDED=1 \
  || return 0


function _log_exception() {
  (
    LOG_FILELOG=false;
    LOG_SYSLOG=false;

    log 'error' "Log Exception: ${@}";
  )
}

function log() {
  local timestamp_format="${LOG_TIMESTAMP_FORMAT:-+%Y-%m-%dT%H:%M:%S}"
  local date="$(date ${timestamp_format})"

  local filelog="${LOG_FILELOG:-false}"
  local filelog_dir="${LOG_FILELOG_DIR:-/tmp}"
  local filelog_name="${LOG_FILELOG_NAME:-$(realpath -s "${0}" | sed "s,/,%,g")}"
  local filelog_path="${filelog_dir}/${filelog_name}.log"

  local syslog="${LOG_SYSLOG:-false}";
  local syslog_tag="${LOG_SYSLOG_TAG:-$(basename -- "${0}")}";
  local syslog_facility="${LOG_SYSLOG_FACILITY:-local0}";

  local pid="${$}";
  local level="$(echo "${1}" | awk '{print tolower($0)}')"
  local level_upper="$(echo "${level}" | awk '{print toupper($0)}')"

  local message="${2}"
  local no_exit="${3:-}"

  local -A severity
  severity['DEBUG']=7
  severity['INFO']=6
  severity['NOTICE']=5
  severity['WARN']=4
  severity['ERROR']=3   # Default
  severity['CRIT']=2
  severity['ALERT']=1   # Unused
  severity['EMERG']=0   # Unused
  readonly severity

  local debug_level="${LOG_DEBUG_LEVEL:-3}"
  local severity_level="${severity[${level_upper}]:-2}"

  # Log all levels
  if [[ "${debug_level}" -ge 0 ]] && [[ "${severity_level}" -le 7 ]]; then

    if ${syslog}; then
      local syslog_message="${level_upper}: ${message}";
      logger \
        --id="${pid}" \
        -t "${syslog_tag}" \
        -p "${syslog_facility}.${severity_level}" \
        "${syslog_message}" \
        || _log_exception "logger --id=\"${pid}\" -t \"${syslog_tag}\" -p \"${syslog_facility}.${level}\" \"${syslog_message}\"";
    fi;

    if ${filelog}; then
      local file_message="${date} [${level_upper}] ${message}";
      echo -e "${file_message}" >> "${filelog_path}" \
        || _log_exception "echo -e \"${file_message}\" >> \"${filelog_path}\"";
    fi;

  fi;

  if [[ "${severity_level}" -gt "${debug_level}" ]]; then
    return
  fi

  local -A colors
  colors['DEBUG']='\033[0;35m'    # Purple
  colors['INFO']=''               # Normal
  colors['NOTICE']='\033[0;34m'   # Blue
  colors['WARN']='\033[0;33m'     # Yellow
  colors['ERROR']='\033[0;31m'    # Red
  colors['CRIT']='\033[1;31m'     # Bold red
  colors['ALERT']=''
  colors['EMERG']=''
  colors['DEFAULT']='\033[0m'     # Normal
  readonly colors

  # Stdout (Pretty)
  local normal="${colors['DEFAULT']}"
  local color="${colors[${level_upper}]:-\033[0m}" # Defaults to normal

  local out="${color}[${level_upper}] ${date} ${message}${normal}"

  case "${level}" in
    'info'|'notice'|'warn'|'debug')
      echo -e "${out}"
      ;;
    'error'|'crit')
      echo -e "${out}" >&2
      if [ "${debug_level}" -ge 0 ]; then
        if [[ "${no_exit}" -ne 1 ]]; then
          echo -e "\nHere's a shell to debug with. 'exit 0' to continue. Other exit codes will abort - parent shell will terminate."
          bash || exit ${?}
        fi
      fi
      ;;
    *)
      log 'error' "Undefined log level '${level}' trying to log: '${@}'"
      ;;
  esac
}

# # Test DEBUG trap
# declare prev_cmd="null"
# declare this_cmd="null"
# trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG \
#   && log 'debug' 'DEBUG trap set' \
#   || log 'error' 'DEBUG trap failed to set'

# # This is an option if you want to log every single command executed,
# # but it will significantly impact script performance and unit tests will fail
# declare prev_cmd="null"
# declare this_cmd="null"
# trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND; log debug $this_cmd' DEBUG \
#  && log 'debug' 'DEBUG trap set' \
#  || log 'error' 'DEBUG trap failed to set'



######################################### BOILERPLATE TO INTEGRATE INTO SCRIPT ###


# ################################################## CONSTANT GLOBAL VARIABLES ###
#
# LOG_FILE_DIR="${HOME}/log"
# LOG_FILE="$(date +"%Y-%m-%dT%H:%M:%S")_$(basename -- $0).log"
#
# SCRIPTPATH="$(realpath -s $0)"
# SCRIPTDIR=$(dirname ${SCRIPTPATH})
#
# ############################################## EXTERNAL DEPENDENCIES SCRIPTS ###
#
# # Ansi color code variables
# if [[ -e "${SCRIPTDIR}/../../scripting-utils/colors" ]]; then
#   source "${SCRIPTDIR}/../../scripting-utils/colors"
# else
#   echo "${SCRIPTPATH} WARNING: Failed to source '../../scripting-utils/colors' dependency"
#   echo
# fi
# # Utility functions
# if [[ -e "${SCRIPTDIR}/../../scripting-utils/utils" ]]; then
#   source "${SCRIPTDIR}/../../scripting-utils/utils"
# else
#   echo "${SCRIPTPATH} ERROR: Failed to source '../../scripting-utils/utils' dependency"
#   exit 1
# fi
#
# ############################################################### FLAG OPTIONS ###
#
# # Display help
# usage() {
#   cat << EOF
# USAGE:
#
# Command description.
#
#   command [ -DsvVy ]
#
# OPTIONS:
#
#   -D  debug mode (redirect output in log file)
#   -s  silent output
#   -v  verbose output
#   -V  very verbose output
#   -y  skip confirmation
#   -h  help
#
# EOF
# }
#
# # Set flag options
# while getopts "DsvVyh" opt; do
#   case "$opt" in
#     D) [[ -n "$DEBUG"           ]] && unset DEBUG                      || DEBUG=true;;
#     s) [[ -n "$IS_SILENT"       ]] && unset IS_SILENT                  || IS_SILENT=true;;
#     v) [[ -n "$IS_VERBOSE"      ]] && unset IS_VERBOSE                 || IS_VERBOSE=true;;
#     V) [[ -n "$IS_VERY_VERBOSE" ]] && unset IS_VERBOSE IS_VERY_VERBOSE || IS_VERBOSE=true; IS_VERY_VERBOSE=true;;
#     y) [[ -n "$SKIP_CONFIRM"    ]] && unset SKIP_CONFIRM               || SKIP_CONFIRM=true;;
#     h) usage && exit 0;;
#     *) usage && echo -e "${SCRIPTPATH}:\n${COLOR_RED}ERROR: Invalid flag.${COLOR_NC}"
#       exit 1
#   esac
# done 2>/dev/null
# shift "$((OPTIND-1))"
#
# ####################################################### PRE-EXECUTION SET UP ###
#
# # Strip trailing '/' in DIR path variables
# LOG_FILE_DIR=$(echo ${LOG_FILE_DIR} | sed 's,/*$,,')
#
# # Log stdout and stderr to $LOG_FILE in $LOG_FILE_DIR
# if [[ -n "${DEBUG}" ]]; then
#   # Append LOG_FILE
#   LOG_FILE_PATH="${LOG_FILE_DIR}/${LOG_FILE}"
#   # Create log directory if not existing
#   if [[ ! -d "${LOG_FILE_DIR}" ]]; then
#     mkdir -p "${LOG_FILE_DIR}"
#   fi
#   # Initialize log file
#   echo -e "${SCRIPTPATH} log outputs\n" > ${LOG_FILE_PATH}
# fi
#
# ################################################## SCRIPT ARGUMENTS HANDLING ###
#
# ##################################################### SCRIPT MAIN EXECUTIONS ###
#
# #################################################################### WRAP UP ###

