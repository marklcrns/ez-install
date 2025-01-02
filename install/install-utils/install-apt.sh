#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath $0) is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_APT_SH_INCLUDED+x}" ]] &&
	readonly INSTALL_UTILS_INSTALL_APT_SH_INCLUDED=1 ||
	return $BASH_EX_OK

source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/common/sys.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"

function apt_add_repo() {
	local forced=false
	local as_root=false
	local is_update=false
	local args=""
	local command_name=""
	local package_name=""

	OPTIND=1
	while getopts "a:c:f:n:s:u:" opt; do
		case ${opt} in
		a)
			args="${OPTARG}"
			;;
		c)
			command_name="${OPTARG}"
			;;
		n)
			package_name="${OPTARG}"
			;;
		f)
			forced=${OPTARG}
			;;
		s)
			as_root=${OPTARG}
			;;
		u)
			is_update=${OPTARG}
			;;
		*)
			error "Invalid flag option(s)"
			exit $BASH_SYS_EX_USAGE
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	if [[ -z "${@+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local repo="${@}"
	local apt_repo_dir='/etc/apt/'
	local sudo=""
	local redirect=""

	$forced && args+=' --reinstall'
	! ${VERBOSE:-false} && redirect=' &> /dev/null'
	[[ -z "${package_name}" ]] && package_name="${repo}"

	# strip_substr 'ppa:' repo

	if $as_root; then
		if command -v sudo &>/dev/null; then
			sudo="sudo "
		else
			pac_log_failed $BASH_EX_MISUSE 'Apt-add' "${package_name}" "Apt-add '${package_name}' installation failed. 'sudo' not installed"
			return $BASH_EX_MISUSE
		fi
	fi

	local res=0

	is_apt_installed
	res=$?
	if [[ $res -ne $BASH_EX_OK ]]; then
		pac_log_failed $res 'Apt-add' "${package_name}" "Apt-add '${package_name}' installation failed. apt not installed"
		return $res
	fi

	if ! $forced; then
		if find ${apt_repo_dir} -name "*.list" | xargs cat | grep -h "^[[:space:]]*deb.*${repo//ppa:/}" &>/dev/null; then
			pac_log_skip 'Apt-add' "${package_name}"
			return $BASH_EX_OK
		fi
	fi

	if $is_update; then
		apt_update -s $as_root
		res=$?
		[[ $res -ne $BASH_EX_OK ]] && return $res
	fi

	pac_pre_install -f $forced -s $as_root -- "${package_name}" 'apt-add'
	res=$?
	[[ $res -ne $BASH_EX_OK ]] && return $res

	# Execute installation
	is_wsl && set_nameserver "8.8.8.8"
	if execlog "${sudo}apt-add-repository -y ${args} -- '${repo}'${redirect}"; then
		pac_log_success 'Apt-add' "${package_name}"
		return $BASH_EX_OK
	else
		res=$?
		pac_log_failed $res 'Apt-add' "${package_name}"
		execlog "${sudo}apt-add-repository -ry -- '${repo}'${redirect}"
		return $res
	fi
	is_wsl && restore_nameserver

	pac_post_install -f $forced -s $as_root -- "${package_name}" 'apt-add'
	res=$?
	return $res
}

# Will `apt update` first before installation if $2 -eq 1
function apt_install() {
	local forced=false
	local as_root=false
	local is_update=false
	local args=""
	local command_name=""
	local package_name=""

	OPTIND=1
	while getopts "a:c:f:n:s:u:" opt; do
		case ${opt} in
		a)
			args="${OPTARG}"
			;;
		c)
			command_name="${OPTARG}"
			;;
		n)
			package_name="${OPTARG}"
			;;
		f)
			forced=${OPTARG}
			;;
		s)
			as_root=${OPTARG}
			;;
		u)
			is_update=${OPTARG}
			;;
		*)
			error "Invalid flag option(s)"
			exit $BASH_SYS_EX_USAGE
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	if [[ -z "${@+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local package="${@%.*}"
	local sudo=""

	$forced && args+=' --reinstall'
	! ${VERBOSE:-false} && args+=' -q'
	[[ -z "${package_name}" ]] && package_name="${package}"

	if $as_root; then
		if command -v "sudo" &>/dev/null; then
			sudo="sudo "
		else
			pac_log_failed $BASH_EX_MISUSE 'Apt' "${package_name}" "Apt '${package_name}' installation failed. 'sudo' not installed"
			return $BASH_EX_MISUSE
		fi
	fi

	local res=0

	is_apt_installed
	res=$?
	if [[ $res -ne $BASH_EX_OK ]]; then
		pac_log_failed $res 'Apt' "${package_name}" "Apt '${package_name}' installation failed. Apt not installed"
		return $res
	fi

	# DEPRECATED: Does not cover every package. e.g. g++-multilib.
	#             Let 'apt' throws an error if not existing.
	# # Check if package exists in apt repository
	# if ! apt-cache search --names-only "^${package}.*" | grep -F "${package}" &> /dev/null; then
	#   pac_log_failed $BASH_EZ_EX_PAC_NOTFOUND 'Apt' "${package_name}" "Apt '${package_name}' does not exists in the apt repository"
	#   return $BASH_EZ_EX_PAC_NOTFOUND
	# fi

	if ! $forced; then
		# Check if already installed
		if [[ -n "${command_name}" ]] && command -v "${command_name}" &>/dev/null || dpkg -s "${package}" &>/dev/null; then
			pac_log_skip "Apt" "${package_name}"
			return $BASH_EX_OK
		fi
	fi

	local res=0

	if $is_update; then
		apt_update -s $as_root
		res=$?
		[[ $res -ne $BASH_EX_OK ]] && return $res
	fi

	pac_pre_install -f $forced -s $as_root -- "${package_name}" 'apt'
	res=$?
	[[ $res -ne $BASH_EX_OK ]] && return $res

	# Execute installation
	if execlog "${sudo}apt install -y ${args} -- '${package}'"; then
		pac_log_success 'Apt' "${package_name}"
	else
		res=$?
		pac_log_failed $res 'Apt' "${package_name}"
		return $res
	fi

	pac_post_install -f $forced -s $as_root -- "${package_name}" 'apt'
	res=$?

	return $res
}

function apt_update() {
	local as_root=false

	OPTIND=1
	while getopts "s:" opt; do
		case ${opt} in
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

	local sudo=""

	if $as_root; then
		if command -v "sudo" &>/dev/null; then
			sudo="sudo "
		else
			return $BASH_EX_MISUSE
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

	return $res
}

function apt_upgrade() {
	local as_root=false
	local args=""

	OPTIND=1
	while getopts "s:" opt; do
		case ${opt} in
		a)
			args="${OPTARG}"
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

	local sudo=""

	if $as_root; then
		if command -v "sudo" &>/dev/null; then
			sudo="sudo "
		else
			return $BASH_EX_MISUSE
		fi
	fi

	local res=0

	is_wsl && set_nameserver '8.8.8.8'
	if execlog "${sudo}apt update -y ${args} && apt upgrade -y ${args}"; then
		ok 'Apt upgrade successful!'
	else
		res=$?
		error 'Apt upgrade failed'
	fi
	is_wsl && restore_nameserver

	return $res
}

function apt_purge() {
	local as_root=false
	local args=""
	local command_name=""
	local package_name=""

	OPTIND=1
	while getopts "a:c:n:u:s:" opt; do
		case ${opt} in
		a)
			args="${OPTARG}"
			;;
		c)
			command_name="${OPTARG}"
			;;
		n)
			package_name="${OPTARG}"
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

	if [[ -z "${@+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local package="${@%.*}"
	local sudo=""
	! ${VERBOSE:-false} && args+=' -q'
	[[ -z "${package_name}" ]] && package_name="${package}"

	if $as_root; then
		if command -v "sudo" &>/dev/null; then
			sudo="sudo "
		else
			pac_log_failed $BASH_EX_MISUSE 'Apt' "${package_name}" "Apt '${package_name}' installation failed. 'sudo' not installed"
			return $BASH_EX_MISUSE
		fi
	fi

	local res=0

	is_apt_installed
	res=$?
	if [[ $res -ne $BASH_EX_OK ]]; then
		pac_log_failed $res 'Apt' "${package_name}" "Apt '${package_name}' installation failed. apt not installed"
		return $res
	fi

	# Check if already installed
	if ! dpkg -s "${package}" &>/dev/null || [[ -n "${command_name}" ]] && ! command -v "${command_name}" &>/dev/null; then
		pac_log_skip 'Apt-purge' "${package_name}" "Apt purge '${package_name}' skipped. Package not installed."
		return $BASH_EX_OK
	fi

	# Execute installation
	if execlog "${sudo}apt purge --auto-remove -y ${args} -- '${package}'"; then
		pac_log_success 'Apt-purge' "${package_name}" "Apt purge '${package_name}' successful!"
	else
		res=$?
		pac_log_failed $res 'Apt-purge' "${package_name}" "Apt purge '${package_name}' failed!"
	fi

	return $res
}

function is_apt_installed() {
	if command -v apt &>/dev/null; then
		return $BASH_EX_OK
	fi
	return $BASH_EX_NOTFOUND
}
