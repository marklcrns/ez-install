#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${INSTALL_CONST_SH_INCLUDED+x}" ]] &&
	readonly INSTALL_CONST_SH_INCLUDED=1 ||
	return 0

source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/const.sh"
include "${EZ_INSTALL_HOME}/actions.sh"

# Exit Codes
readonly BASH_EZ_EX__BASE=201            # Ez special exit codes start
readonly BASH_EZ_EX_PAC_NOTFOUND=201     # Package not found
readonly BASH_EZ_EX_PACMAN_NOTFOUND=202  # Package manager not supported
readonly BASH_EZ_EX_DEP_NOTFOUND=203     # Dependency not found
readonly BASH_EZ_EX_DEP_FAILED=204       # Package dependency failure
readonly BASH_EZ_EX_PAC_EXIST=205        # Package exist
readonly BASH_EZ_EX_PAC_GENERATED=206    # Package generated successfully
readonly BASH_EZ_EX_COMMAND_NOTFOUND=207 # Ez command not found
readonly BASH_EZ_EX__MAX=207             # Ez special exit codes end

# Exit Messages
readonly BASH_EZ_MSG_PAC_NOTFOUND='Package not found'
readonly BASH_EZ_MSG_PACMAN_NOTFOUND='Package manager not found'
readonly BASH_SYS_MSG_USAGE_MISSARG='Missing argument(s)'
readonly BASH_SYS_MSG_USAGE_INVARG='Invalid argument(s)'
readonly BASH_SYS_MSG_USAGE_INVREFVAR='Invalid reference to variable'

# Ez Install
readonly EZ_SUPPORTED_PACKAGE_MANAGER='apt-add apt npm pip pip2 pip3 pkg curl wget git local'

# Ez sub commands
readonly EZ_COMMAND_DOT="${EZ_INSTALL_HOME}/dot/dot"
readonly EZ_COMMAND_DOT_BACKUP="${EZ_INSTALL_HOME}/dot/actions/backup"
readonly EZ_COMMAND_DOT_DISTRIBUTE="${EZ_INSTALL_HOME}/dot/actions/dist"
readonly EZ_COMMAND_DOT_UPDATE="${EZ_INSTALL_HOME}/dot/actions/update"
readonly EZ_COMMAND_GEN="${EZ_INSTALL_HOME}/generate/gen"
readonly EZ_COMMAND_INSTALL="${EZ_INSTALL_HOME}/install/install"

# Ez Executables
readonly EZ_INSTALL_METADATA_PARSER="${EZ_INSTALL_HOME}/install/utils/metadata-parser"

# Dependencies
# TODO: Check for dependency version

# JSON Parser
# LINUX: wget https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -O ./jq && chmod +x ./jq
if [[ -e "${EZ_INSTALL_HOME}/lib/parser/jq" ]]; then
	readonly EZ_DEP_JQ="${EZ_INSTALL_HOME}/lib/parser/jq"
	readonly EZ_DEP_JSON_PARSER="${EZ_INSTALL_HOME}/lib/parser/jq"
elif command -v jq &>/dev/null; then
	readonly EZ_DEP_JQ="jq"
	readonly EZ_DEP_JSON_PARSER="jq"
else
	error "Missing 'jq' JSON parser dependency"
	exit $BASH_EZ_EX_DEP_NOTFOUND
fi

# YAML Parser
# LINUX: wget https://github.com/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64 -O ./yq && chmod +x ./yq
if [[ -e "${EZ_INSTALL_HOME}/lib/parser/yq" ]]; then
	readonly EZ_DEP_YQ="${EZ_INSTALL_HOME}/lib/parser/yq"
	readonly EZ_DEP_YAML_PARSER="${EZ_INSTALL_HOME}/lib/parser/yq"
elif command -v yq &>/dev/null; then
	readonly EZ_DEP_YQ="yq"
	readonly EZ_DEP_YAML_PARSER="yq"
else
	error "Missing 'yq' YAML parser dependency"
	exit $BASH_EZ_EX_DEP_NOTFOUND
fi
