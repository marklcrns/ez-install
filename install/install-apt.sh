#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_INSTALL_APT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INSTALL_APT_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/../common/string.sh"
source "${BASH_SOURCE%/*}/../common/sys.sh"
source "${BASH_SOURCE%/*}/actions.sh"
source "${BASH_SOURCE%/*}/pac-logger.sh"


_is_apt_installed() {
  if eval "command -v apt &> /dev/null"; then
    return 0
  fi
  return 1
}


add_apt_repo() {
  local repo="${@}"
  local apt_repo='/etc/apt/'

  if ! _is_apt_installed; then
    pac_log_failed 'Add apt' "${repo}" "Add apt '${repo}' installation failed. apt not installed"
    return 1
  fi

  strip_substr 'ppa:' repo
  if eval "find $apt_repo -name \"*.list\" | xargs cat | grep -h \"^[[:space:]]*deb.*${repo}\" &> /dev/null"; then
    pac_log_skip 'Add apt' "${repo}"
    return 0
  fi

  [[ is_wsl ]] && set_nameserver "8.8.8.8"
  warning "Adding ppa:${repo}..."
  if execlog "sudo add-apt-repository '${repo}' -y &> /dev/null"; then
    pac_log_success 'Add apt' "${repo}"
    return 0
  else
    pac_log_failed 'Add apt' "${repo}"
    execlog "sudo add-apt-repository -r '${repo}'"
    return 1
  fi
  [[ is_wsl ]] && restore_nameserver
}


# Will `apt update` first before installation if $2 -eq 1
apt_install() {
  local is_update=false
  OPTIND=1

  while getopts "u" opt; do
    case ${opt} in
      u)
        is_update=true
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@}"

  if ! _is_apt_installed; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. apt not installed"
    return 1
  fi

  # Check if package exists in apt repository
  if ! eval "apt-cache search --names-only '${package}' | grep -F '${package}' &> /dev/null"; then
    pac_log_failed 'Apt' "${package}"
    return 1
  fi

  # Check if already installed
  if eval "dpkg -s '${package}' &> /dev/null"; then
    pac_log_skip "Apt" "${package}"
    return 0
  fi

  # sudo apt update if is_update
  ${is_update} && apt_update

  # Execute installation
  if execlog "sudo apt install '${package}' -y"; then
    pac_log_success 'Apt' "${package}"
    return 0
  else
    pac_log_failed 'Apt' "${package}"
    return 1
  fi
}


# if apt package is appended with ';update', will `apt update` first before
# installation
apt_bulk_install() {
  local packages=("$@")

  if ! _is_apt_installed; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. apt not installed"
    return 1
  fi

  # Loop over packages array and apt_install
  if [[ -n "${packages}" ]]; then
    for package in ${packages[@]}; do
      if has_substr ";update" "${package}"; then
        strip_substr ";update" package
        apt_install -u "${package}"
      else
        apt_install "${package}"
      fi
    done
  else
    error "${FUNCNAME[0]}: Array not found"
  fi
}


apt_update() {
  [[ is_wsl ]] && set_nameserver '8.8.8.8'
  if execlog 'sudo apt update -y'; then
    ok 'Apt update successful!'
  else
    error 'Apt update failed'
  fi
  [[ is_wsl ]] && restore_nameserver
}


apt_upgrade() {
  [[ is_wsl ]] && set_nameserver '8.8.8.8'
  if execlog 'sudo apt update -y && sudo apt upgrade -y'; then
    ok 'Apt upgrade successful!'
  else
    error 'Apt upgrade failed'
  fi
  [[ is_wsl ]] && restore_nameserver
}

