#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_CURL_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_CURL_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


_is_curl_installed() {
  if eval "command -v curl &> /dev/null"; then
    return 0
  fi
  return 1
}

curl_install() {
  local args='-sSL --'
  local from= to= command_name= package_name=

  OPTIND=1
  while getopts "a:c:o:n:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      o)
        to="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  from="${@}"

  if ! _is_curl_installed; then
    pac_log_failed 'Curl' "${from}" "Curl '${from}' installation failed. curl not installed"
    return 1
  fi

  # Check if already installed
  if eval "command -v '${command_name}' &> /dev/null"; then
    pac_log_skip "Curl" "${package_name}"
    return 0
  fi

  # Resolve destination
  if [[ -n "${to}" ]]; then
    local filename="$(basename -- "${from}")"
    to="${to}/${filename}"

    if [[ -f "${to}" ]]; then
      pac_log_skip "Curl" "${to}"
      return 0
    fi

    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "curl --create-dirs -o '${to}' ${args} ${from}"; then
      pac_log_success 'Curl' "${from}" "Curl '${from}' -> '${to}' successful"
      return 0
    else
      pac_log_failed 'Curl' "${from}" "Curl '${from}' -> '${to}' failed!"
      return 1
    fi
  else
    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "curl ${args} ${from}"; then
      pac_log_success 'Curl' "${from}" "Curl '${from}' successful"
      return 0
    else
      pac_log_failed 'Curl' "${from}" "Curl '${from}' failed!"
      return 1
    fi
  fi
}

