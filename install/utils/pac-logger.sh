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


source "${BASH_SOURCE%/*}/actions.sh"
source "${BASH_SOURCE%/*}/../../common/colors.sh"


SUCCESSFUL_PACKAGES=
SKIPPED_PACKAGES=
FAILED_PACKAGES=

pac_log_success() {
  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    ok -d 2 "${message}"
  else
    ok -d 2 "${manager} '${package}' package installation successful"
  fi

  SUCCESSFUL_PACKAGES="${SUCCESSFUL_PACKAGES:-}\n${manager} '${package}' SUCCESSFUL"
}


pac_log_skip() {
  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  if [[ -n "${message}" ]]; then
    ok -d 2 "${message}"
  else
    ok -d 2 "${manager} '${package}' package already exists"
  fi

  SKIPPED_PACKAGES="${SKIPPED_PACKAGES:-}\n${manager} '${package}' SKIPPED"
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

  FAILED_PACKAGES="${FAILED_PACKAGES:-}\n${manager} '${package}' FAILED"
}


pac_report() {
  local total_count=0
  local successful_count=0
  local skipped_count=0
  local failed_count=0

  echo -e "\n${COLOR_UL_NC}Successful Installations${COLOR_NC}\n"
  while IFS= read -r package; do
    if [[ -n "${package}" ]]; then
      echo -e "${COLOR_GREEN}${package}${COLOR_NC}"
      total_count=$(expr ${total_count} + 1)
      successful_count=$(expr ${successful_count} + 1)
    fi
  done < <(echo -e "${SUCCESSFUL_PACKAGES}")

  echo -e "\n${COLOR_UL_NC}Skipped Installations${COLOR_NC}\n"
  while IFS= read -r package; do
    if [[ -n "${package}" ]]; then
      echo -e "${COLOR_YELLOW}${package}${COLOR_NC}"
      total_count=$(expr ${total_count} + 1)
      skipped_count=$(expr ${skipped_count} + 1)
    fi
  done < <(echo -e "${SKIPPED_PACKAGES}")

  echo -e "\n${COLOR_UL_NC}Failed Installations${COLOR_NC}\n"
  while IFS= read -r package; do
    if [[ -n "${package}" ]]; then
      echo -e "${COLOR_RED}${package}${COLOR_NC}"
      total_count=$(expr ${total_count} + 1)
      failed_count=$(expr ${failed_count} + 1)
    fi
  done < <(echo -e "${FAILED_PACKAGES}")

  echo
  echo -e "Successful │ ${successful_count}"
  echo -e "Skipped    │ ${skipped_count}"
  echo -e "Failed     │ ${failed_count}"
  echo -e "———————————│————"
  echo -e "TOTAL      │ ${total_count}"
}

