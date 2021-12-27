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


source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


_is_npm_installed() {
  if eval "command -v npm &> /dev/null"; then
    return 0
  fi
  return 1
}

npm_install() {
  local is_local=false
  local args='--' command_name=

  OPTIND=1
  while getopts "a:c:l" opt; do
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
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"

  if ! _is_npm_installed; then
    pac_log_failed 'Npm' "${package}" "Npm '${package}' installation failed. npm not installed"
    return 1
  fi

  # Check if package exists in npm repository
  if eval "npm search '${package}' | grep -q '^No matches found' &> /dev/null"; then
    error "'${package}' does not exists in the npm repository"
    pac_log_failed 'Npm' "${package}" "Npm '${package}' package not found in npm repository"
    return 1
  fi

  # Check if package already installed
  if ${is_local}; then
    if eval "npm list | grep -F '${package}' &> /dev/null"; then
      pac_log_skip 'Npm' "${package}" "Npm '${package}' local package already installed"
      return 0
    fi
  else
    if eval "npm list -g | grep -F '${package}' &> /dev/null"; then
      pac_log_skip 'Npm' "${package}" "Npm '${package}' global package already installed"
      return 0
    fi
  fi

  # Execute installation
  if ${is_local}; then
    if execlog "npm install ${args} '${package}'"; then
      pac_log_success 'Npm' "${package}" "Npm '${package}' local package installation successful"
      return 0
    else
      pac_log_failed 'Npm' "${package}" "Npm '${package}' local package installation failed"
      return 1
    fi
  else
    if execlog "npm install -g ${args} '${package}'"; then
      pac_log_success 'Npm' "${package}" "Npm '${package}' global package installation successful"
      return 0
    else
      pac_log_failed 'Npm' "${package}" "Npm '${package}' global package installation failed"
      return 1
    fi
  fi
}

