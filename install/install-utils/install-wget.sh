#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_WGET_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_WGET_SH_INCLUDED=1 \
  || return $BASH_EX_OK


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function wget_install() {
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
  ! ${VERBOSE:-false}        && args+=' -q'
  [[ -z "${package_name}" ]] && package_name="${from}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed $BASH_EX_MISUSE 'Wget' "${package_name}" "Wget '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  local res=0

  is_wget_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed $res 'Wget' "${package_name}" "Wget '${package_name}' installation failed. wget not installed"
    return $res
  fi

  if ! $forced; then
    # Check if already installed
    if [[ -n ${command_name} ]] && command -v ${command_name} &> /dev/null; then
      pac_log_skip "Wget" "${package_name}"
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
    pac_log_skip "Wget" "${package_name}" "Wget '${package_name}' ${output_path} already exist"
    return $BASH_EX_OK
  fi

  pac_pre_install -o "${output_path}" -f $forced -s $as_root -- "${package_name}" 'wget'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  if $execute; then
    # Execute installation
    if execlog "wget -O - ${args} -- '${from}' | ${sudo}bash"; then
      pac_log_success 'Wget' "${package_name}" "Wget '${package_name}' successful"
    else
      res=$?
      pac_log_failed $res 'Wget' "${package_name}" "Wget '${package_name}' failed!"
      return $res
    fi
  else
    # Create output_path directory
    if [[ ! -d "$(dirname -- "${output_path}")" ]]; then
      warning "Creating destination directory of '${output_path}'"
      execlog "mkdir -p $(basename -- ${output_path})"
    fi

    # Execute installation
    if execlog "wget -O '${output_path}' ${args} -- '${from}'"; then
      pac_log_success 'Wget' "${package_name}" "Wget '${from}' -> '${output_path}' successful"
    else
      res=$?
      pac_log_failed $res 'Wget' "${package_name}" "Wget '${from}' -> '${output_path}' failed!"
      return $res
    fi
  fi

  pac_post_install -o "${output_path}" -f $forced -s ${as_root} -- "${package_name}" 'wget'
  res=$?
  return $res
}


function is_wget_installed() {
  if command -v wget &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}

