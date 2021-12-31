#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_NPM_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_NPM_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


npm_install() {
  local as_root=false
  local is_local=false
  local args='--'
  local command_name=""

  OPTIND=1
  while getopts "a:c:lS:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      l)
        is_local=true
        ;;
      S)
        as_root=${OPTARG}
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
      pac_log_failed 'Npm' "${package}" "Npm '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi


  if ! is_npm_installed; then
    pac_log_failed 'Npm' "${package}" "Npm '${package}' installation failed. npm not installed"
    return 1
  fi

  # Check if package exists in npm repository
  if npm search "${package}" | grep -q '^No matches found' &> /dev/null; then
    error "'${package}' does not exists in the npm repository"
    pac_log_failed 'Npm' "${package}" "Npm '${package}' package not found in npm repository"
    return 1
  fi

  # Check if package already installed
  if ${is_local}; then
    if npm list | grep -F "${package}" &> /dev/null; then
      pac_log_skip 'Npm' "${package}" "Npm '${package}' local package already installed"
      return 0
    fi
  else
    if npm list -g | grep -F "${package}" &> /dev/null; then
      pac_log_skip 'Npm' "${package}" "Npm '${package}' global package already installed"
      return 0
    fi
  fi

  local res=0

  pac_pre_install "${package}" 'npm'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  # Execute installation
  if ${is_local}; then
    if execlog "${sudo}npm install ${args} '${package}'"; then
      pac_log_success 'Npm' "${package}" "Npm '${package}' local package installation successful"
      return 0
    else
      res=$?
      pac_log_failed 'Npm' "${package}" "Npm '${package}' local package installation failed"
      return ${res}
    fi
  else
    if execlog "${sudo}npm install -g ${args} '${package}'"; then
      pac_log_success 'Npm' "${package}" "Npm '${package}' global package installation successful"
      return 0
    else
      res=$?
      pac_log_failed 'Npm' "${package}" "Npm '${package}' global package installation failed"
      return ${res}
    fi
  fi

  pac_post_install "${package}" 'npm'
  res=$?
  return ${res}
}


is_npm_installed() {
  if command -v npm &> /dev/null; then
    return 0
  fi
  return 1
}

