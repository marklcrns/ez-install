#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_PIP_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_PIP_SH_INCLUDED=1 \
  || return $BASH_EX_OK


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function pip_install() {
  local as_root=false
  local is_global=false
  local args='--'
  local command_name=""
  local package_name=""
  local pip_version=""

  OPTIND=1
  while getopts "a:c:gn:S:v:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      g)
        is_global=true
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      v)
        pip_version="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${@%.*}"
  local sudo=""
  [[ -z "${package_name}" ]] && package_name="${package}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed $BASH_EX_MISUSE "Pip${pip_version}" "${package_name}" "Pip${pip_version} '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  local res=0

  is_pip_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed $res "Pip${pip_version}" "${package_name}" "Pip${pip_version} '${package_name}' installation failed. pip${pip_version} not installed"
    return $res
  fi

  # Check pip version if not 2 or 3
  if [[ -n ${pip_version} ]]; then
    if [[ "${pip_version}" -gt 3 || ${pip_version} -lt 2 ]]; then
      pac_log_failed $BASH_EX_NOTFOUND "Pip${pip_version}" "${package_name}" "Pip${pip_version} '${package_name}' package failed. Invalid pip version"
      return $BASH_EX_NOTFOUND
    fi
  fi

  # Check if already installed
  if ${sudo}pip${pip_version} list | grep -F "${package}" &> /dev/null || command -v ${command_name} &> /dev/null; then
    pac_log_skip "Pip${pip_version}" "${package_name}"
    return $BASH_EX_OK
  fi

  pac_pre_install "${package_name}" "pip${pip_version}"
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  # Execute installation
  if $is_global; then
    if execlog "${sudo}pip${pip_version} install -g ${args} ${package}"; then
      pac_log_success "Pip${pip_version}" "${package_name}"
    else
      res=$?
      pac_log_failed $res "Pip${pip_version}" "${package_name}"
      return $res
    fi
  else
    if execlog "${sudo}pip${pip_version} install ${args} ${package}"; then
      pac_log_success "Pip${pip_version}" "${package_name}"
    else
      res=$?
      pac_log_failed $res "Pip${pip_version}" "${package_name}"
      return $res
    fi
  fi

  pac_post_install "${package_name}" "pip${pip_version}"
  res=$?

  return $res
}


function is_pip_installed() {
  local pip_version=${1:-}
  if command -v "pip${pip_version}" &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}

