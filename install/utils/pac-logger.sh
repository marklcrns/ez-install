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


source "${EZ_INSTALL_HOME}/install/utils/actions.sh"
source "${EZ_INSTALL_HOME}/common/colors.sh"
source "${EZ_INSTALL_HOME}/common/stack.sh"


[[ -z "${SUCCESSFUL_PACKAGES+x}" ]] && declare -a SUCCESSFUL_PACKAGES=()
[[ -z "${SKIPPED_PACKAGES+x}" ]]    && declare -a SKIPPED_PACKAGES=()
[[ -z "${FAILED_PACKAGES+x}" ]]     && declare -a FAILED_PACKAGES=()


pac_log_success() {
  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    ok -d 2 "${message}"
  else
    ok -d 2 "${manager} '${package}' package installation successful"
  fi

  local log="${package}-SUCCESSFUL"
  if ! has_pac_log_duplicate "${log}" "${SUCCESSFUL_PACKAGES[@]}"; then
    SUCCESSFUL_PACKAGES=( ${SUCCESSFUL_PACKAGES[@]} "${manager}-${log}" )
  fi
}


pac_log_skip() {
  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    ok -d 2 "${message}"
  else
    ok -d 2 "${manager} '${package}' package already installed"
  fi

  local log="${package}-SKIPPED"
  if ! has_pac_log_duplicate "${log}" "${SKIPPED_PACKAGES[@]}"; then
    SKIPPED_PACKAGES=( ${SKIPPED_PACKAGES[@]} "${manager}-${log}" )
  fi
}


pac_log_failed() {
  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    error -d 2 "${message}"
  else
    error -d 2 "${manager} '${package}' package installation failed"
  fi

  local log="${package}-FAILED"
  if ! has_pac_log_duplicate "${log}" "${FAILED_PACKAGES[@]}"; then
    FAILED_PACKAGES=( ${FAILED_PACKAGES[@]} "${manager}-${log}" )
  fi
}


has_pac_log_duplicate() {
  local new_log=${1:-}
  shift 1
  local log=( "${@}" )

  for package in ${log[@]}; do
    if [[ "${package}" =~ .*${new_log}.* ]]; then
      return 0
    fi
  done
  return 1
}


# TODO: Excluded duplicates
pac_report() {
  local total_count=0
  local successful_count=0
  local skipped_count=0
  local failed_count=0

  echo -e "\n${COLOR_UL_NC}Successful Installations${COLOR_NC}\n"
  for package in ${SUCCESSFUL_PACKAGES[@]}; do
    echo -e "${COLOR_GREEN}${package}${COLOR_NC}"
    total_count=$(expr ${total_count} + 1)
    successful_count=$(expr ${successful_count} + 1)
  done

  echo -e "\n${COLOR_UL_NC}Skipped Installations${COLOR_NC}\n"
  for package in ${SKIPPED_PACKAGES[@]}; do
    echo -e "${COLOR_YELLOW}${package}${COLOR_NC}"
    total_count=$(expr ${total_count} + 1)
    successful_count=$(expr ${successful_count} + 1)
  done

  echo -e "\n${COLOR_UL_NC}Failed Installations${COLOR_NC}\n"
  for package in ${FAILED_PACKAGES[@]}; do
    echo -e "${COLOR_RED}${package}${COLOR_NC}"
    total_count=$(expr ${total_count} + 1)
    successful_count=$(expr ${successful_count} + 1)
  done

  cat << EOF

Successful │ ${successful_count}
Skipped    │ ${skipped_count}
Failed     │ ${failed_count}
———————————│—————
TOTAL      │ ${total_count}

EOF
}

