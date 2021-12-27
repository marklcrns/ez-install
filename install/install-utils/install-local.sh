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


source "${BASH_SOURCE%/*}/../utils/actions.sh"
source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


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
  if eval "command -v '${command_name}' &> /dev/null"; then
    pac_log_skip "Local" "${package}"
    return 2
  fi
}

