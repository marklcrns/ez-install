#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_CURL_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_CURL_SH_INCLUDED=1 \
  || return $BASH_EX_OK


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function curl_install() {
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

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local from="${@}"
  local sudo=""
  [[ -z "${package_name}" ]] && package_name="${from}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed 'Curl' "${package_name}" "Curl '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  is_curl_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed 'Curl' "${package_name}" "Curl '${package_name}' installation failed. curl not installed"
    return $res
  fi

  # Check if already installed
  if [[ -n ${command_name} ]] && command -v ${command_name} &> /dev/null; then
    pac_log_skip "Curl" "${package_name}"
    return $BASH_EX_OK
  fi

  local res=0

  pac_pre_install "${package_name}" 'curl'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  # Resolve destination
  if [[ -n "${to}" ]]; then
    local filename="$(basename -- "${from}")"
    # NOTE: ~ does not expand when tested with -d
    to="${to//\~/${HOME}}/${filename}"

    if [[ -f "${to}" ]]; then
      pac_log_skip "Curl" "${package_name}"
      return $BASH_EX_OK
    fi

    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "${sudo}curl --create-dirs -o '${to}' ${args} ${from}"; then
      pac_log_success 'Curl' "${package_name}" "Curl '${from}' -> '${to}' successful"
    else
      res=$?
      pac_log_failed 'Curl' "${package_name}" "Curl '${from}' -> '${to}' failed!"
      return $res
    fi
  else
    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "${sudo}curl ${args} ${from}"; then
      pac_log_success 'Curl' "${package_name}" "Curl '${package_name}' successful"
    else
      res=$?
      pac_log_failed 'Curl' "${package_name}" "Curl '${package_name}' failed!"
      return $res
    fi
  fi

  pac_post_install "${package_name}" 'curl'
  res=$?
  return $res
}


function is_curl_installed() {
  if command -v curl &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}

