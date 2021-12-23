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


source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


_is_pkg_installed() {
  if eval "command -v pkg &> /dev/null"; then
    return 0
  fi
  return 1
}

pkg_install() {
  local is_update=false
  OPTIND=1

  # Handle flags
  while getopts "u" opt; do
    case ${opt} in
      u)
        is_update=true
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"

  if ! _is_pkg_installed; then
    pac_log_failed 'Pkg' "${package}" "Pkg '${package}' installation failed. pkg not installed"
    return 1
  fi

  # Check if already installed
  if eval "pkg search '${package}' | grep 'installed' &> /dev/null" || eval "command -v '${package}' &> /dev/null"; then
    pac_log_skip 'Pkg' "${package}"
    return 0
  fi

  # pkg upgrade if is_update
  ${is_update} && pkg_update

  # Execute installation
  if execlog "pkg install '${package}' -y"; then
    pac_log_success 'Pkg' "${package}"
    return 0
  else
    pac_log_failed 'Pkg' "${package}"
    return 1
  fi
}


# if apt package is appended with ';update', will `apt update` first before
# installation
pkg_batch_install() {
  local packages=("$@")

  if ! _is_pkg_installed; then
    pac_log_failed 'Pkg' "${packages}" "Pkg installation failed. pkg not installed"
    return 1
  fi

  # Loop over packages array and apt_install
  if [[ -n "${packages}" ]]; then
    for package in ${packages[@]}; do
      if has_substr ";update" "${package}"; then
        strip_substr ";update" package
        pkg_install 1 "${package}"
      else
        pkg_install "${package}"
      fi
    done
  else
    error "${FUNCNAME[0]}: Array not found" 1
  fi
}


pkg_update() {
  if execlog 'pkg upgrade -y'; then
    ok 'Pkg upgrade successful!'
  else
    error 'Pkg upgrade failed'
  fi
}
