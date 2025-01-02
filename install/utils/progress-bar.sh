#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath $0) is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${UTILS_PROGRESS_BAR_SH_INCLUDED+x}" ]] &&
	readonly UTILS_PROGRESS_BAR_SH_INCLUDED=1 ||
	return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"

# TODO: fix 100% overflow
prog_bar() {
	local w=50 p="${1}"
	shift
	local width=$(("${p}*${w}/100"))

	# create a string of spaces, then change them to dots
	printf -v dots "%*s" "${width}" ""
	dots="${dots// /#}"
	# print those dots on a fixed-width space plus the percentage etc.
	printf "\r\e[K[%-*s] %3d%% %s" "${w}" "${dots}" "${p}" "${*}"
}
