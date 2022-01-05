#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_PKG_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_PKG_SH_INCLUDED=1 \
  || return $BASH_EX_OK


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function pkg_install() {
  local as_root=false
  local is_update=false
  local args=""
  local command_name=""
  local package_name=""

  OPTIND=1
  while getopts "a:c:n:S:u" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      u)
        is_update=true
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${@%.*}"
  local sudo=""
  ! ${VERBOSE:-false}        && args+=' -q'
  [[ -z "${package_name}" ]] && package_name="${package}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed $BASH_EX_MISUSE 'Pkg' "${package_name}" "Pkg '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  local res=0

  is_pkg_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed $res 'Pkg' "${package_name}" "Pkg '${package_name}' installation failed. pkg not installed"
    return $res
  fi

  # Check if already installed
  if pkg search "${package}" | grep 'installed' &> /dev/null || command -v ${command_name} &> /dev/null; then
    pac_log_skip 'Pkg' "${package_name}"
    return $BASH_EX_OK
  fi

  if $is_update; then
    pkg_update -a "${args}" -S $as_root
    res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res
  fi

  pac_pre_install "${package_name}" 'pkg'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  # Execute installation
  if execlog "${sudo}pkg install -y ${args} -- '${package}'"; then
    pac_log_success 'Pkg' "${package_name}"
  else
    res=$?
    pac_log_failed $res 'Pkg' "${package_name}"
    return $res
  fi

  pac_post_install "${package_name}" 'pkg'
  res=$?

  return $res
}


function pkg_update() {
  local as_root=false
  local args=""

  OPTIND=1
  while getopts "a:S:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local sudo=""

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      return $BASH_EX_MISUSE
    fi
  fi

  local res=

  if execlog "${sudo}pkg upgrade -y ${args}"; then
    ok 'Pkg upgrade successful!'
  else
    res=$?
    error 'Pkg upgrade failed'
  fi

  return $res
}


function is_pkg_installed() {
  if command -v pkg &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}

