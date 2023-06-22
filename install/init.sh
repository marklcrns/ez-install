#!/usr/bin/env bash
#
# Init script for generated package install scripts. This script is meant to be
# sourced by the generated package install scripts during package installation.

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${INSTALL_INIT_SH_INCLUDED+x}" ]] &&
	readonly INSTALL_INIT_SH_INCLUDED=1 ||
	return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"
include "${EZ_INSTALL_HOME}/install/install-utils/install.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-install.sh"
include "${EZ_INSTALL_HOME}/common/sys.sh"

[[ -z "${RUN_AS_SU+x}" ]] && RUN_AS_SU=false

#######################################
# Updates the following local variables: output_path, execute, force, as_root.
# Used in the generated package install scripts for handling script arguments
# using flags. The purpose of this function is to create a generic script
# argument handler for the generated package install scripts.
# Arguments:
#   -e <true/false>    Execute the package after installation (default=inherit).
#   -f <true/false>    Force installation (default=inherit).
#   -o </path/to>      Output path for the package installation
#                      (default=inherit). Mostly used in pre/post install script
#                      hooks.
#   -s <true/false>    Run package installation with root (sudo) privileges
#                      (default=inherit).
#######################################
function handle_package_args() {
	OPTIND=1
	while getopts "e:f:o:s:" opt; do
		case ${opt} in
		o)
			# TODO: Verfiy the use case for output_path
			output_path="${OPTARG}"
			;;
		e)
			execute=${OPTARG}
			;;
		f)
			force=${OPTARG}
			;;
		s)
			as_root=${OPTARG}
			;;
		*)
			error "Invalid flag option(s)"
			exit $BASH_SYS_EX_USAGE
			;;
		esac
	done
	shift "$((OPTIND - 1))"
}
