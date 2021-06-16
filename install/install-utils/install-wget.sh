#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_WGET_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_WGET_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


_is_wget_installed() {
  if eval "command -v wget &> /dev/null"; then
    return 0
  fi
  return 1
}


# Specify destination directory
wget_install() {
  local default_flags='-c'
  local args="${default_flags}"
  local from= to=
  OPTIND=1

  # Handle flags
  local opt=
  while getopts "a:O:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      O)
        to="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  from="${@}"

  if ! _is_wget_installed; then
    pac_log_failed 'Wget' "${from}" "Wget '${from}' installation failed. wget not installed"
    return 1
  fi

  if [[ -n "${to}" ]]; then
    # Create destination directory
    if [[ ! -d "${to}" ]]; then
      warning "Creating destination directory '${to}'"
      execlog "mkdir -p ${to}"
    fi

    # Resolve destination
    local filename="$(basename -- "${from}")"
    to="${to}/${filename}"

    # Execute installation
    if execlog "wget ${args} '${from}' -O '${to}'"; then
      pac_log_success 'Wget' "${from}" "Wget '${from}' -> '${to}' successful"
      return 0
    else
      pac_log_failed 'Wget' "${from}" "Wget '${from}' -> '${to}' failed!"
      return 1
    fi
  else
    # Execute installation
    if execlog "wget '${args}' '${from}'"; then
      pac_log_success 'Wget' "${from}" "Wget '${from}' successful"
      return 0
    else
      pac_log_failed 'Wget' "${from}" "Wget '${from}' failed!"
      return 1
    fi
  fi
}

