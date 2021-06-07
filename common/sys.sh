#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${COMMON_SYSTEM_SH_INCLUDED+x}" ]] \
  && readonly COMMON_SYSTEM_SH_INCLUDED=1 \
  || return 0


is_wsl() {
  (grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null) \
    && return 0 \
    || return 1
}


# Set nameserver to $1 after backing up resolve.conf to ~/nameserver.bak
# Setting nameserver to "8.8.8.8" fixes connection issue when updating apt packages
set_nameserver() {
  if ! is_wsl; then
    echo "ERROR: Not running in Microsoft WSL" >&2;
    exit 1
  fi

  local nameserver="${1:-8.8.8.8}"
  cat /etc/resolv.conf > ~/nameserver.bak
  echo "nameserver ${nameserver}" | sudo tee /etc/resolv.conf &> /dev/null
}

restore_nameserver() {
  [[ -e "$HOME/nameserver.bak" ]] && cat ~/nameserver.bak | sudo tee /etc/resolv.conf &> /dev/null
}
