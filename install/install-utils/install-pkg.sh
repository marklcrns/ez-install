#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_PKG_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_PKG_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


pkg_install() {
  local as_root=false
  local is_update=false
  local args='--'
  local command_name=""

  OPTIND=1
  while getopts "a:c:S:u" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
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

  local package="${@%.*}"
  local sudo=""

  if ${as_root}; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed 'Pkg' "${package}" "Pkg '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  if ! is_pkg_installed; then
    pac_log_failed 'Pkg' "${package}" "Pkg '${package}' installation failed. pkg not installed"
    return 1
  fi

  # Check if already installed
  if pkg search "${package}" | grep 'installed' &> /dev/null || command -v ${command_name} &> /dev/null; then
    pac_log_skip 'Pkg' "${package}"
    return 0
  fi

  local res=0

  if ${is_update}; then
    pkg_update -S ${as_root}
    res=$?; [[ ${res} -gt 0 ]] && return ${res}
  fi

  pac_pre_install "${package}" 'pkg'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  # Execute installation
  if execlog "${sudo}pkg install -y ${args} '${package}'"; then
    pac_log_success 'Pkg' "${package}"
  else
    res=$?
    pac_log_failed 'Pkg' "${package}"
    return ${res}
  fi

  pac_post_install "${package}" 'pkg'
  res=$?

  return ${res}
}


pkg_update() {
  local as_root=false

  OPTIND=1
  while getopts "S:" opt; do
    case ${opt} in
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local sudo=""

  if ${as_root}; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      return 3
    fi
  fi

  local res=

  if execlog 'pkg upgrade -y'; then
    ok 'Pkg upgrade successful!'
  else
    res=$?
    error 'Pkg upgrade failed'
  fi

  return ${res}
}


is_pkg_installed() {
  if command -v pkg &> /dev/null; then
    return 0
  fi
  return 1
}

