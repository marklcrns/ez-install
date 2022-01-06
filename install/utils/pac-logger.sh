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


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"


[[ -z "${SUCCESSFUL_PACKAGES+x}" ]] && declare -a SUCCESSFUL_PACKAGES=()
[[ -z "${SKIPPED_PACKAGES+x}" ]]    && declare -a SKIPPED_PACKAGES=()
[[ -z "${FAILED_PACKAGES+x}" ]]     && declare -a FAILED_PACKAGES=()


function pac_log_success() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi
  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    ok -d 2 "${message}"
  else
    ok -d 2 "${manager} '${package}' package installation successful"
  fi

  local log="'${package}' SUCCESSFUL"

  [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
  if ! has_pac_log_duplicate "${log}" "${SUCCESSFUL_PACKAGES[@]}"; then
    SUCCESSFUL_PACKAGES=( "${SUCCESSFUL_PACKAGES[@]}" "${log}" )
  fi
}


function pac_log_skip() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi
  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local exit_code=$1
  local has_exit_code=false
  if [[ $exit_code =~ ^[0-9]+$ ]]; then
    has_exit_code=true
    shift
  fi

  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    skip -d 2 "${message}"
  else
    skip -d 2 "${manager} '${package}' package already installed"
  fi

  local log=""
  if $has_exit_code; then
    log="'${package}' SKIPPED"
  else
    log="'${package}' SKIPPED ($exit_code)"
  fi

  [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
  if ! has_pac_log_duplicate "${log}" "${SKIPPED_PACKAGES[@]}"; then
    SKIPPED_PACKAGES=( "${SKIPPED_PACKAGES[@]}" "${log}" )
  fi
}


function pac_log_failed() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi
  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local exit_code=$1
  local has_exit_code=false
  if [[ $exit_code =~ ^[0-9]+$ ]]; then
    has_exit_code=true
    shift
  fi

  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    error -d 2 "${message}"
  else
    error -d 2 "${manager} '${package}' package installation failed"
  fi

  local log=""
  if $has_exit_code; then
    log="'${package}' FAILED"
  else
    log="'${package}' FAILED ($exit_code)"
  fi

  [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
  if ! has_pac_log_duplicate "${log}" "${FAILED_PACKAGES[@]}"; then
    FAILED_PACKAGES=( "${FAILED_PACKAGES[@]}" "${log}" )
  fi
}


function has_pac_log_duplicate() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local new_log="${1}"
  shift 1
  local log=( "${@}" )

  local i=
  for ((i = 0; i < ${#log[@]}; ++i)); do
    if has_substr "${new_log}" "${log[$i]}"; then
      return $BASH_EX_OK
    fi
  done

  return $BASH_EX_GENERAL
}


# TODO: Excluded duplicates
function pac_report() {
  local total_count=0
  local successful_count=0
  local skipped_count=0
  local failed_count=0

  local i=

  if [[ -n ${SUCCESSFUL_PACKAGES[@]} ]]; then
    echo -e "\n${COLOR_UL_NC}Successful Installations${COLOR_NC}\n"
    for ((i = 0; i < ${#SUCCESSFUL_PACKAGES[@]}; ++i)); do
      echo -e "${COLOR_GREEN}${SUCCESSFUL_PACKAGES[$i]}${COLOR_NC}"
      total_count=$(expr ${total_count} + 1)
      successful_count=$(expr ${successful_count} + 1)
    done
  fi

  if [[ -n ${SKIPPED_PACKAGES[@]} ]]; then
    echo -e "\n${COLOR_UL_NC}Skipped Installations${COLOR_NC}\n"
    for ((i = 0; i < ${#SKIPPED_PACKAGES[@]}; ++i)); do
      echo -e "${COLOR_BLUE}${SKIPPED_PACKAGES[$i]}${COLOR_NC}"
      total_count=$(expr ${total_count} + 1)
      skipped_count=$(expr ${skipped_count} + 1)
    done
  fi

  if [[ -n ${FAILED_PACKAGES[@]} ]]; then
    echo -e "\n${COLOR_UL_NC}Failed Installations${COLOR_NC}\n"
    for ((i = 0; i < ${#FAILED_PACKAGES[@]}; ++i)); do
      echo -e "${COLOR_RED}${FAILED_PACKAGES[$i]}${COLOR_NC}"
      total_count=$(expr ${total_count} + 1)
      failed_count=$(expr ${failed_count} + 1)
    done
  fi

  cat << EOF

Successful │ ${successful_count}
Skipped    │ ${skipped_count}
Failed     │ ${failed_count}
———————————│—————
TOTAL      │ ${total_count}

EOF
}

