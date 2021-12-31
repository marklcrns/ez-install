#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_PIP_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_PIP_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


pip_install() {
  local as_root=false
  local is_global=false
  local args='--'
  local command_name=""
  local pip_version=""

  OPTIND=1
  while getopts "a:c:gS:v:" opt; do
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
      S)
        as_root=${OPTARG}
        ;;
      v)
        pip_version="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"
  local sudo=""

  if ${as_root}; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed "Pip${pip_version}" "${package}" "Pip${pip_version} '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  if ! is_pip_installed ${pip_version}; then
    pac_log_failed "Pip${pip_version}" "${package}" "Pip${pip_version} '${package}' installation failed. pip${pip_version} not installed"
    return 1
  fi

  # Check pip version if not 2 or 3
  if [[ -n ${pip_version} ]]; then
    if [[ "${pip_version}" -gt 3 || ${pip_version} -lt 2 ]]; then
      pac_log_failed "Pip${pip_version}" "${package}" "Pip${pip_version} '${package}' package failed. Invalid pip version"
      return 1
    fi
  fi

  # Check if already installed
  if ${sudo}pip${pip_version} list | grep -F "${package}" &> /dev/null || command -v ${command_name} &> /dev/null; then
    pac_log_skip "Pip${pip_version}" "${package}"
    return 0
  fi

  local res=0

  pac_pre_install "${package}" "pip${pip_version}"
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  # Execute installation
  if ${is_global}; then
    if execlog "${sudo}pip${pip_version} install -g ${args} ${package}"; then
      pac_log_success "Pip${pip_version}" "${package}"
    else
      res=$?
      pac_log_failed "Pip${pip_version}" "${package}"
      return ${res}
    fi
  else
    if execlog "${sudo}pip${pip_version} install ${args} ${package}"; then
      pac_log_success "Pip${pip_version}" "${package}"
    else
      res=$?
      pac_log_failed "Pip${pip_version}" "${package}"
      return ${res}
    fi
  fi

  pac_post_install "${package}" "pip${pip_version}"
  res=$?

  return ${res}
}


is_pip_installed() {
  local pip_version=${1:-}
  if command -v "pip${pip_version}" &> /dev/null; then
    return 0
  fi
  return 1
}

