#!/bin/bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_INSTALL_PIP_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INSTALL_PIP_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/pac-logger.sh"


_is_pip_installed() {
  local pip_version=${1:-}
  if eval "command -v pip${pip_version} &> /dev/null"; then
    return 0
  fi
  return 1
}

pip_install() {
  local pip_version=
  OPTIND=1

  while getopts "v:" opt; do
    case ${opt} in
      v)
        pip_version="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@}"

  if ! _is_pip_installed ${pip_version}; then
    pac_log_failed "Pip${pip_version}" "${package}" "Pip${pip_version} '${package}' installation failed. pip${pip_version} not installed"
    return 1
  fi

  # Check pip version if not 2 or 3
  if [[ -n ${pip_version} ]]; then
    if [[ "${pip_version}" -gt 3 || ${pip_version} -lt 2 ]]; then
      pac_log_failed "Pip${pip_version}" "${package}" "Pip${pip_version} '${package}' package failed. Invalid pip version"
      return 1
    fi
  fi

  # Check if already installed
  if eval "pip${pip_version} list | grep -F '${package}' &> /dev/null"; then
    pac_log_skip "Pip${pip_version}" "${package}"
    return 0
  fi
  # Execute installation
  if execlog "pip${pip_version} install ${package}"; then
    pac_log_success "Pip${pip_version}" "${package}"
    return 0
  else
    pac_log_failed "Pip${pip_version}" "${package}"
    return 1
  fi
}


pip_bulk_install() {
  local pip_version=
  OPTIND=1

  # Handle flags
  while getopts "v:" opt; do
    case ${opt} in
      v)
        pip_version="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local packages=("$@")

  if ! _is_pip_installed ${pip_version}; then
    pac_log_failed "Pip${pip_version}" "${package}" "Pip${pip_version} '${package}' installation failed. pip${pip_version} not installed"
    return 1
  fi

  if [[ -n "${packages}" ]]; then
    for package in ${packages[@]}; do
      if [[ -n "${pip_version}" ]]; then
        pip_install -v ${pip_version} "${package}"
      else 
        pip_install "${package}"
      fi
    done
  else
    error "${FUNCNAME[0]}: Array not found" 1
  fi
}


