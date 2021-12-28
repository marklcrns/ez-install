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


source "${BASH_SOURCE%/*}/../../common/string.sh"
source "${BASH_SOURCE%/*}/../../common/sys.sh"
source "${BASH_SOURCE%/*}/../utils/actions.sh"
source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


_is_apt_installed() {
  if eval "command -v apt &> /dev/null"; then
    return 0
  fi
  return 1
}


apt_add_repo() {
  local is_update=false
  local args='--' command_name=
  OPTIND=1
  while getopts "a:c:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      u)
        is_update=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local repo="${@}"
  local apt_repo_dir='/etc/apt/'

  if ! _is_apt_installed; then
    pac_log_failed 'Add apt' "${repo}" "Add apt '${repo}' installation failed. apt not installed"
    return 1
  fi

  strip_substr 'ppa:' repo
  if eval "find ${apt_repo_dir} -name \"*.list\" | xargs cat | grep -h \"^[[:space:]]*deb.*${repo}\" &> /dev/null"; then
    pac_log_skip 'Add apt' "${repo}"
    return 0
  fi

  # sudo apt update if is_update
  ${is_update} && apt_update

  # Execute installation
  is_wsl && set_nameserver "8.8.8.8"
  if execlog "sudo add-apt-repository -y ${args} '${repo}' &> /dev/null"; then
    pac_log_success 'Add apt' "${repo}"
    return 0
  else
    pac_log_failed 'Add apt' "${repo}"
    execlog "sudo add-apt-repository -r '${repo}'"
    return 1
  fi
  is_wsl && restore_nameserver
}


# Will `apt update` first before installation if $2 -eq 1
apt_install() {
  local is_update=false
  local args='--' command_name=
  OPTIND=1
  while getopts "a:c:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      u)
        is_update=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"

  if ! _is_apt_installed; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. apt not installed"
    return 1
  fi

  # Check if package exists in apt repository
  if ! eval "apt-cache search --names-only '^${package}.*' | grep -F '${package}' &> /dev/null"; then
    error "'${package}' does not exists in the apt repository"
    pac_log_failed 'Apt' "${package}"
    return 1
  fi

  # Check if already installed
  if eval "command -v '${command_name}' &> /dev/null" || eval "dpkg -s '${package}' &> /dev/null"; then
    pac_log_skip "Apt" "${package}"
    return 0
  fi

  # sudo apt update if is_update
  ${is_update} && apt_update

  # Execute installation
  if execlog "sudo apt install -y ${args} '${package}'"; then
    pac_log_success 'Apt' "${package}"
    return 0
  else
    pac_log_failed 'Apt' "${package}"
    return 1
  fi
}


apt_update() {
  is_wsl && set_nameserver '8.8.8.8'
  if execlog 'sudo apt update -y'; then
    ok 'Apt update successful!'
  else
    error 'Apt update failed'
  fi
  is_wsl && restore_nameserver
}


apt_upgrade() {
  is_wsl && set_nameserver '8.8.8.8'
  if execlog 'sudo apt update -y && sudo apt upgrade -y'; then
    ok 'Apt upgrade successful!'
  else
    error 'Apt upgrade failed'
  fi
  is_wsl && restore_nameserver
}


apt_purge() {
  local args='--' command_name=
  OPTIND=1
  while getopts "a:c:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG} --"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${@%.*}"

  if ! _is_apt_installed; then
    pac_log_failed 'Apt' "${package}" "Apt '${package}' installation failed. apt not installed"
    return 1
  fi

  # Check if already installed
  if ! eval "dpkg -s '${package}' &> /dev/null" || ! eval "command -v '${command_name}' &> /dev/null"; then
    pac_log_skip 'Apt-purge' "${package}" "Apt purge '${package}' skipped. Package not installed."
    return 0
  fi

  # Execute installation
  if execlog "sudo purge --auto-remove -y ${args} '${package}'"; then
    pac_log_success 'Apt-purge' "${package}" "Apt purge '${package}' successful!"
    return 0
  else
    pac_log_failed 'Apt-purge' "${package}" "Apt purge '${package}' failed!"
    return 1
  fi
}
