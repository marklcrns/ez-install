#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_WGET_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_WGET_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


# Specify destination directory
wget_install() {
  local as_root=false
  local args='-c --'
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
      pac_log_failed 'Wget' "${package}" "Wget '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi


  if ! is_wget_installed; then
    pac_log_failed 'Wget' "${from}" "Wget '${from}' installation failed. wget not installed"
    return 1
  fi

  # Check if already installed
  if [[ -n ${command_name} ]]; then
    if command -v ${command_name} &> /dev/null; then
      pac_log_skip "Wget" "${package_name}"
      return 0
    fi
  fi

  local res=0

  pac_pre_install "${package_name}" 'wget'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  if [[ -n "${to}" ]]; then
    # Create destination directory
    if [[ ! -d "${to}" ]]; then
      warning "Creating destination directory '${to}'"
      execlog "mkdir -p ${to}"
    fi

    # Resolve destination
    local filename="$(basename -- "${from}")"
    to="${to}/${filename}"

    if [[ -f "${to}" ]]; then
      pac_log_skip "Wget" "${to}"
      return 0
    fi

    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "${sudo}wget -O '${to}' ${args} ${from}"; then
      pac_log_success 'Wget' "${from}" "Wget '${from}' -> '${to}' successful"
    else
      res=$?
      pac_log_failed 'Wget' "${from}" "Wget '${from}' -> '${to}' failed!"
      return ${res}
    fi
  else
    # Execute installation
    # NOTE: DO NOT SURROUND $from to permit shell command piping
    if execlog "${sudo}wget ${args} ${from}"; then
      pac_log_success 'Wget' "${from}" "Wget '${from}' successful"
    else
      res=$?
      pac_log_failed 'Wget' "${from}" "Wget '${from}' failed!"
      return ${res}
    fi
  fi

  pac_post_install "${package_name}" 'wget'
  res=$?
  return ${res}
}


is_wget_installed() {
  if command -v wget &> /dev/null; then
    return 0
  fi
  return 1
}

