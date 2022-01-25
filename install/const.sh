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


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"


# General

readonly EZ_SUPPORTED_PACKAGE_MANAGER='apt apt-add npm pip pip2 pip3 pkg curl wget git local'

# Exit Codes

readonly BASH_EZ_EX__BASE=101             # Ez special exit codes start
readonly BASH_EZ_EX_PAC_NOTFOUND=101      # Package not found
readonly BASH_EZ_EX_PACMAN_NOTFOUND=102   # Package manager not supported
readonly BASH_EZ_EX_DEP_NOTFOUND=103      # Dependency not found
readonly BASH_EZ_EX_DEP_FAILED=104        # Package dependency failure
readonly BASH_EZ_EX_PAC_EXIST=105         # Package exist
readonly BASH_EZ_EX_PAC_GENERATED=106     # Package generated successfully
readonly BASH_EZ_EX__MAX=106              # Ez special exit codes end

# Exit Messages

readonly BASH_EZ_MSG_PAC_NOTFOUND='Package not found'
readonly BASH_EZ_MSG_PACMAN_NOTFOUND='Package manager not found'
readonly BASH_SYS_MSG_USAGE_MISSARG='Missing argument'
readonly BASH_SYS_MSG_USAGE_INVREFVAR='Invalid reference to variable'

# Dependencies

if [[ -e "${EZ_INSTALL_HOME}/lib/parser/jq" ]]; then
  readonly EZ_DEP_JQ="${EZ_INSTALL_HOME}/lib/parser/jq"
elif command -v jq &> /dev/null; then
  readonly EZ_DEP_JQ="jq"
else
  error "Missing 'jq' dependency"
  exit $BASH_EZ_EX_DEP_NOTFOUND
fi

if [[ -e "${EZ_INSTALL_HOME}/install/utils/metadata-parser" ]]; then
  readonly EZ_DEP_METADATA_PARSER="${EZ_INSTALL_HOME}/install/utils/metadata-parser"
else
  error "Missing '${EZ_INSTALL_HOME}/install/utils/metadata-parser' dependency"
  exit $BASH_EZ_EX_DEP_NOTFOUND
fi

if [[ -e "${EZ_INSTALL_HOME}/generate/ez-gen" ]]; then
  readonly EZ_DEP_EZ_GEN="${EZ_INSTALL_HOME}/generate/ez-gen"
else
  error "Missing '${EZ_INSTALL_HOME}/generate/ez-gen' dependency"
  exit $BASH_EZ_EX_DEP_NOTFOUND
fi

