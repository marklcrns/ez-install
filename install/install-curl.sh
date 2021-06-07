#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_INSTALL_CURL_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INSTALL_CURL_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/pac-logger.sh"


_is_curl_installed() {
  if eval "command -v curl &> /dev/null"; then
    return 0
  fi
  return 1
}

curl_install() {
  local default_args='-sSL'
  local args="${default_args}"
  local from= to=
  OPTIND=1

  # Handle flags
  while getopts "a:o:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      o)
        to="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  from="${@}"

  if ! _is_curl_installed; then
    pac_log_failed 'Curl' "${from}" "Curl '${from}' installation failed. curl not installed"
    return 1
  fi

  if [[ -n "${to}" ]]; then
    # Resolve destination
    local filename="$(basename -- "${from}")"
    to="${to}/${filename}"

    # Execute installation
    if execlog "curl '${args}' '${from}' --create-dirs -o '${to}'"; then
      pac_log_success 'Curl' "${from}" "Curl '${from}' -> '${to}' successful"
      return 0
    else
      pac_log_failed 'Curl' "${from}" "Curl '${from}' -> '${to}' failed!"
      return 1
    fi
  else
    # Execute installation
    if execlog "curl ${args} ${from}"; then
      pac_log_success 'Curl' "${from}" "Curl '${from}' successful"
      return 0
    else
      pac_log_failed 'Curl' "${from}" "Curl '${from}' failed!"
      return 1
    fi
  fi
}

