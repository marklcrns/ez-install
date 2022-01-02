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


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function local_install() {
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

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${@%.*}"

  # Check if already installed
  if command -v ${command_name} &> /dev/null; then
    pac_log_skip "Local" "${package}"
    return $BASH_EX_OK
  fi

  local res=0

  pac_pre_install "${package}" 'local'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  pac_post_install "${package}" 'local'
  res=$?
  return $res
}

