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


source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


curl_install() {
  local as_root=false
  local args='-sSL --'
  local to=""
  local command_name=""
  local package_name=""

  OPTIND=1
  while getopts "a:c:o:n:S:" opt; do
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
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local from="${@}"
  local sudo=""

  if ${as_root}; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed 'Curl' "${package}" "Curl '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  if ! is_curl_installed; then
    pac_log_failed 'Curl' "${from}" "Curl '${from}' installation failed. curl not installed"
    return 1
  fi

  # Check if already installed
  if [[ -n ${command_name} ]]; then
    if command -v ${command_name} &> /dev/null; then
      pac_log_skip "Curl" "${package_name}"
      return 0
    fi
  fi

  local res=0

  pac_pre_install "${package_name}" 'curl'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

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
    if execlog "${sudo}curl --create-dirs -o '${to}' ${args} ${from}"; then
      pac_log_success 'Curl' "${from}" "Curl '${from}' -> '${to}' successful"
    else
      res=$?
      pac_log_failed 'Curl' "${from}" "Curl '${from}' -> '${to}' failed!"
      return ${res}
    fi
  else
    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "${sudo}curl ${args} ${from}"; then
      pac_log_success 'Curl' "${from}" "Curl '${from}' successful"
    else
      res=$?
      pac_log_failed 'Curl' "${from}" "Curl '${from}' failed!"
      return ${res}
    fi
  fi

  pac_post_install "${package_name}" 'curl'
  res=$?
  return ${res}
}


is_curl_installed() {
  if command -v curl &> /dev/null; then
    return 0
  fi
  return 1
}

