#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi


# Header guard
[[ -z "${INSTALL_CONST_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_CONST_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/common/const.sh"


readonly BASH_EZ_EX__BASE=101
readonly BASH_EZ_EX_PAC_NOTFOUND=101      # Package not found
readonly BASH_EZ_EX_PACMAN_NOTFOUND=102   # Package manager not supported
readonly BASH_EZ_EX_DEP_NOTFOUND=103      # Dependency not found
readonly BASH_EZ_EX_PAC_EXIST=104         # Package exist

readonly BASH_EZ_MSG_PAC_NOTFOUND='Package not found'
readonly BASH_EZ_MSG_PACMAN_NOTFOUND='Package manager not found'
readonly BASH_SYS_MSG_USAGE_MISSARG='Missing argument'
readonly BASH_SYS_MSG_USAGE_INVREFVAR='Invalid reference to variable'


