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
  local command_name=""
  local package_name=""

  OPTIND=1
  while getopts "c:n:S:" opt; do
    case ${opt} in
      c)
        command_name="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${@%.*}"
  [[ -z "${package_name}" ]] && package_name="${package}"

  # Check if already installed
  if [[ -n "${command_name}" ]] && command -v ${command_name} &> /dev/null; then
    pac_log_skip "Local" "${package_name}"
    return $BASH_EX_OK
  fi

  local res=0

  pac_pre_install -S ${as_root} "${package_name}" 'local'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  pac_post_install -S ${as_root} "${package_name}" 'local'
  res=$?
  return $res
}

