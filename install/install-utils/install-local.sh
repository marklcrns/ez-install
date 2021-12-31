#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_LOCAL_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_LOCAL_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/install/utils/actions.sh"
source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


local_install() {
  local command_name=

  OPTIND=1
  while getopts "c:" opt; do
    case ${opt} in
      c)
        command_name="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"

  # Check if already installed
  if command -v ${command_name} &> /dev/null; then
    pac_log_skip "Local" "${package}"
    return 2
  fi

  pac_pre_install "${package}" 'local'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  pac_post_install "${package}" 'local'
  res=$?
  return ${res}
}

