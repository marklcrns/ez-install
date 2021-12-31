#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_APT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_APT_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/common/string.sh"
source "${EZ_INSTALL_HOME}/common/sys.sh"
source "${EZ_INSTALL_HOME}/install/utils/actions.sh"
source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


apt_add_repo() {
  local as_root=false
  local is_update=false
  local args='--'
  local command_name=""

  OPTIND=1
  while getopts "a:c:S:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      u)
        is_update=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local repo="${@}"
  local apt_repo_dir='/etc/apt/'
  local sudo=""

  strip_substr 'ppa:' repo

  if ${as_root}; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed 'Apt-add' "${repo}" "Apt-add '${repo}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  if ! is_apt_installed; then
    pac_log_failed 'Apt-add' "${repo}" "Apt-add '${repo}' installation failed. apt not installed"
    return 1
  fi

  if find ${apt_repo_dir} -name "*.list" | xargs cat | grep -h "^[[:space:]]*deb.*${repo}" &> /dev/null; then
    pac_log_skip 'Apt-add' "${repo}"
    return 0
  fi

  if ${is_update}; then
    apt_update -S ${as_root}
    res=$?; [[ ${res} -gt 0 ]] && return ${res}
  fi

  pac_pre_install "${command_name}" 'apt-add'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  # Execute installation
  is_wsl && set_nameserver "8.8.8.8"
  if execlog "apt-add-repository -y ${args} '${repo}' &> /dev/null"; then
    pac_log_success 'Apt-add' "${repo}"
    return 0
  else
    res=$?
    pac_log_failed 'Apt-add' "${repo}"
    execlog "apt-add-repository -r '${repo}'"
    return ${res}
  fi
  is_wsl && restore_nameserver

  pac_post_install "${command_name}" 'apt-add'
  res=$?
  return ${res}
}


# Will `apt update` first before installation if $2 -eq 1
apt_install() {
  local as_root=false
  local is_update=false
  local args='--'
  local command_name=""

  OPTIND=1
  while getopts "a:c:S:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      u)
        is_update=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"
  local sudo=""

  if ${as_root}; then
    if command -v "sudo" &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  if ! is_apt_installed; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. Apt not installed"
    return 1
  fi

  # Check if package exists in apt repository
  if ! apt-cache search --names-only "^${package}.*" | grep -F "${package}" &> /dev/null; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' does not exists in the apt repository"
    return 1
  fi

  # Check if already installed
  if command -v "${command_name}" &> /dev/null || dpkg -s "${package}" &> /dev/null; then
    pac_log_skip "Apt" "${package}"
    return 0
  fi

  local res=0

  if ${is_update}; then
    apt_update -S ${as_root}
    res=$?; [[ ${res} -gt 0 ]] && return ${res}
  fi

  pac_pre_install "${package}" 'apt'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  # Execute installation
  if execlog "${sudo}apt install -y ${args} '${package}'"; then
    pac_log_success 'Apt' "${package}"
  else
    res=$?
    pac_log_failed 'Apt' "${package}"
    return ${res}
  fi

  pac_post_install "${package}" 'apt'
  res=$?

  return ${res}
}


apt_update() {
  local as_root=false

  OPTIND=1
  while getopts "S:" opt; do
    case ${opt} in
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local sudo=""

  if ${as_root}; then
    if command -v "sudo" &> /dev/null; then
      sudo="sudo "
    else
      return 3
    fi
  fi

  local res=

  is_wsl && set_nameserver '8.8.8.8'
  if execlog "${sudo}apt update -y"; then
    ok 'Apt update successful!'
  else
    res=$?
    error 'Apt update failed'
  fi
  is_wsl && restore_nameserver

  return ${res}
}


apt_upgrade() {
  local as_root=false

  OPTIND=1
  while getopts "S:" opt; do
    case ${opt} in
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local sudo=""

  if ${as_root}; then
    if command -v "sudo" &> /dev/null; then
      sudo="sudo "
    else
      return 3
    fi
  fi

  local res=0

  is_wsl && set_nameserver '8.8.8.8'
  if execlog "${sudo}apt update -y && apt upgrade -y"; then
    ok 'Apt upgrade successful!'
  else
    res=$?
    error 'Apt upgrade failed'
  fi
  is_wsl && restore_nameserver

  return ${res}
}


apt_purge() {
  local as_root=false
  local args='--' command_name=
  OPTIND=1
  while getopts "a:c:u:S:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"
  local sudo=""

  if ${as_root}; then
    if command -v "sudo" &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  if ! is_apt_installed; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. apt not installed"
    return 1
  fi

  # Check if already installed
  if ! dpkg -s "${package}" &> /dev/null || ! command -v "${command_name}" &> /dev/null; then
    pac_log_skip 'Apt-purge' "${package}" "Apt purge '${package}' skipped. Package not installed."
    return 0
  fi

  local res=0

  # Execute installation
  if execlog "${sudo}apt purge --auto-remove -y ${args} '${package}'"; then
    pac_log_success 'Apt-purge' "${package}" "Apt purge '${package}' successful!"
  else
    res=$?
    pac_log_failed 'Apt-purge' "${package}" "Apt purge '${package}' failed!"
  fi

  return ${res}
}


is_apt_installed() {
  if command -v apt &> /dev/null; then
    return 0
  fi
  return 1
}

