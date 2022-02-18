#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${UTILS_PAC_LOGGER_SH_INCLUDED+x}" ]] \
  && readonly UTILS_PAC_LOGGER_SH_INCLUDED=1 \
  || return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/actions.sh"


[[ -z "${SUCCESSFUL_PACKAGES+x}" ]] && declare -a SUCCESSFUL_PACKAGES=()
[[ -z "${SKIPPED_PACKAGES+x}" ]]    && declare -a SKIPPED_PACKAGES=()
[[ -z "${FAILED_PACKAGES+x}" ]]     && declare -a FAILED_PACKAGES=()


function pac_log_success() { _pac_log -a 'SUCCESSFUL_PACKAGES' -s 'SUCCESS' -m 'ok' "${@}"; }
function pac_log_skip()    { _pac_log -a 'SKIPPED_PACKAGES' -s 'SKIPPED' -m 'skip' "${@}"; }
function pac_log_failed()  { _pac_log -a 'FAILED_PACKAGES' -s 'FAILED' -m 'error' "${@}"; }

function _pac_log() {
  local status_array=""
  local message_command=""
  local status=""
  local skip_tally=false

  OPTIND=1
  while getopts "a:m:s:x" opt; do
    case ${opt} in
      a) status_array="${OPTARG}" ;;
      m) message_command="${OPTARG}" ;;
      s) status="${OPTARG}" ;;
      x) skip_tally=true ;;
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
  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local exit_code=${1}
  local has_exit_code=false
  if is_integer $exit_code; then
    has_exit_code=true
    shift
  fi

  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  # '-d 3' offsets _pac_log() and its wrapper functions
  if [[ -n "${message}" ]]; then
    ${message_command} -d 3 "${message}"
  else
    ${message_command} -d 3 "${manager} '${package}' package installation ${status}"
  fi

  local log=""
  if $has_exit_code; then
    log="'${package}' ${status} [$exit_code]"
  else
    log="'${package}' ${status}"
  fi

  [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
  ! $skip_tally && handle_duplicates -s "${log}" "${status_array}"
}


function handle_duplicates() {
  local stack=false

  OPTIND=1
  while getopts "s" opt; do
    case ${opt} in
      s) stack=true ;;
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

  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local new_log="${1}"
  local array_name="${2}"

  local log=()
  eval "log=( \"\${${array_name}[@]}\" )"

  local i=
  local repeat=
  local stripped=
  for ((i = 0; i < ${#log[@]}; ++i)); do
    if has_substr "${new_log}" "${log[$i]}"; then
      # Prepend '($repeat)' to new_log
      if $stack; then
        repeat="$(echo "${log[$i]}" | sed -e 's/^(\(.*\)).*/\1/')"    # extract repeat
        stripped="$(echo "${log[$i]}" | sed -e 's/^(\(.*\))\s*//')"   # strip (repeat)
        if is_integer "${repeat}"; then
          eval "${array_name}[$i]=\"($(($repeat+1))) ${stripped}\""
        else
          eval "${array_name}[$i]=\"(2) ${stripped}\""
        fi
      fi
      return $BASH_EX_OK
    fi
  done

  # Add new_log to report
  eval "${array_name}=( \"\${${array_name}[@]}\" \"${new_log}\" )"
}


function pac_report() {
  local successful_count=0
  local skipped_count=0
  local failed_count=0

  if [[ -n ${SUCCESSFUL_PACKAGES[@]} ]]; then
    echo -e "\nSUCCESS:"
    for ((i = 0; i < ${#SUCCESSFUL_PACKAGES[@]}; ++i)); do
      echo -e "${COLOR_GREEN}${SUCCESSFUL_PACKAGES[$i]}${COLOR_NC}"
      successful_count=$(expr ${successful_count} + 1)
    done
  fi

  if [[ -n ${SKIPPED_PACKAGES[@]} ]]; then
    echo -e "\nSKIPPED:"
    for ((i = 0; i < ${#SKIPPED_PACKAGES[@]}; ++i)); do
      echo -e "${COLOR_BLUE}${SKIPPED_PACKAGES[$i]}${COLOR_NC}"
      skipped_count=$(expr ${skipped_count} + 1)
    done
  fi

  if [[ -n ${FAILED_PACKAGES[@]} ]]; then
    echo -e "\nFAILED:"
    for ((i = 0; i < ${#FAILED_PACKAGES[@]}; ++i)); do
      echo -e "${COLOR_RED}${FAILED_PACKAGES[$i]}${COLOR_NC}"
      failed_count=$(expr ${failed_count} + 1)
    done
  fi

  echo -e "\nSUCCESS: ${successful_count}, SKIPPED: ${skipped_count}, FAILED: ${failed_count}"
  echo -e "TOTAL: $((${successful_count}+${skipped_count}+${failed_count}))\n"
}

