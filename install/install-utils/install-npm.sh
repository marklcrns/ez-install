#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_NPM_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_NPM_SH_INCLUDED=1 \
  || return $BASH_EX_OK


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function npm_install() {
  local as_root=false
  local is_local=false
  local args=""
  local command_name=""
  local package_name=""

  OPTIND=1
  while getopts "a:c:n:lS:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      l)
        is_local=true
        ;;
      S)
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

  local package="${@}"
  local sudo=""
  ! ${VERBOSE:-false}        && args+=' --silent'
  [[ -z "${package_name}" ]] && package_name="${package}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed $BASH_EX_MISUSE 'Npm' "${package_name}" "Npm '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  local res=0

  is_npm_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed $res 'Npm' "${package_name}" "Npm '${package_name}' installation failed. npm not installed"
    return $res
  fi

  # Check if package exists in npm repository
  if npm search "${package}" | grep -q '^No matches found' &> /dev/null; then
    error "'${package}' does not exists in the npm repository"
    pac_log_failed $BASH_EZ_EX_PAC_NOTFOUND 'Npm' "${package_name}" "Npm '${package_name}' package not found in npm repository"
    return $BASH_EZ_EX_PAC_NOTFOUND
  fi

  # Check if package already installed
  if $is_local; then
    if npm list | grep -F "${package}" &> /dev/null; then
      pac_log_skip 'Npm' "${package_name}" "Npm '${package_name}' local package already installed"
      return $BASH_EX_OK
    fi
  else
    if npm list -g | grep -F "${package}" &> /dev/null; then
      pac_log_skip 'Npm' "${package_name}" "Npm '${package_name}' global package already installed"
      return $BASH_EX_OK
    fi
  fi

  pac_pre_install -S ${as_root} "${package_name}" 'npm'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  # Execute installation
  if $is_local; then
    if execlog "${sudo}npm install ${args} -- '${package}'"; then
      pac_log_success 'Npm' "${package_name}" "Npm '${package_name}' local package installation successful"
      return $BASH_EX_OK
    else
      res=$?
      pac_log_failed $res 'Npm' "${package_name}" "Npm '${package_name}' local package installation failed"
      return $res
    fi
  else
    if execlog "${sudo}npm install -g ${args} -- '${package}'"; then
      pac_log_success 'Npm' "${package_name}" "Npm '${package_name}' global package installation successful"
      return $BASH_EX_OK
    else
      res=$?
      pac_log_failed $res 'Npm' "${package_name}" "Npm '${package_name}' global package installation failed"
      return $res
    fi
  fi

  pac_post_install -S ${as_root} "${package_name}" 'npm'
  res=$?
  return $res
}


function is_npm_installed() {
  if command -v npm &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}

