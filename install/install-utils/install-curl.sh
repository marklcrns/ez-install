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

include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function curl_install() {
  local execute=false
  local forced=false
  local as_root=false
  local args=""
  local command_name=""
  local package_name=""
  local output_path=""

  OPTIND=1
  while getopts "a:c:e:f:o:n:s:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      e)
        execute=${OPTARG}
        ;;
      f)
        forced=${OPTARG}
        ;;
      o)
        output_path="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      s)
        as_root=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local from="${@}"
  local sudo=""

  [[ -z "${args}" ]]         && args='-fSL'
  ! ${VERBOSE:-false}        && args+=' -s'
  [[ -z "${package_name}" ]] && package_name="${from}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed $BASH_EX_MISUSE 'Curl' "${package_name}" "Curl '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  is_curl_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed $res 'Curl' "${package_name}" "Curl '${package_name}' installation failed. curl not installed"
    return $res
  fi

  if ! $forced; then
    # Check if already installed
    if [[ -n ${command_name} ]] && command -v ${command_name} &> /dev/null; then
      pac_log_skip "Curl" "${package_name}"
      return $BASH_EX_OK
    fi
  fi

  # Resolve output_path
  local filename="$(basename -- "${from}")"
  if [[ -z "${output_path}" ]]; then
    output_path="${EZ_DOWNLOADS_DIR}/${filename}"
  fi
  # NOTE: ~ does not expand when `test -d`, i.e., [[ -d "${output_path}" ]]
  output_path=${output_path//\~/${HOME}}
  if [[ -d "${output_path}" ]]; then
    output_path="${output_path}/${filename}"
  fi

  # Replace existing if forced
  if [[ -e "${output_path}" ]] && ! $forced; then
    pac_log_skip "Curl" "${package_name}" "Curl '${package_name}' ${output_path} already exist"
    return $BASH_EX_OK
  fi

  local res=0

  pac_pre_install -o "${output_path}" -f $forced -s $as_root -- "${package_name}" 'curl'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  if $execute; then
    # Execute installation
    if execlog "curl ${args} -- '${from}' | ${sudo}bash"; then
      pac_log_success 'Curl' "${package_name}" "Curl '${package_name}' successful"
    else
      res=$?
      pac_log_failed $res 'Curl' "${package_name}" "Curl '${package_name}' failed!"
      return $res
    fi
  else
    # Execute installation
    if execlog "curl --create-dirs -o '${output_path}' ${args} -- '${from}'"; then
      pac_log_success 'Curl' "${package_name}" "Curl '${from}' -> '${output_path}' successful"
    else
      res=$?
      pac_log_failed $res 'Curl' "${package_name}" "Curl '${from}' -> '${output_path}' failed!"
      return $res
    fi
  fi

  pac_post_install -o "${output_path}" -f $forced -s $as_root -- "${package_name}" 'curl'
  res=$?
  return $res
}


function is_curl_installed() {
  if command -v curl &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}

