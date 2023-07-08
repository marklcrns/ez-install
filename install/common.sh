#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath -s "$0") is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${PACKAGES_COMMON_SH_INCLUDED+x}" ]] &&
	readonly PACKAGES_COMMON_SH_INCLUDED=1 ||
	return 0

source "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")/../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/sys.sh"
include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/log.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/install-utils/install.sh"

#######################################
# Sets PACKAGE_ROOT_DIR, PACKAGE_DIR, LOCAL_PACKAGE_ROOT_DIR, and
# LOCAL_PACKAGE_DIR according to the linux distro.
#
# PACKAGE_ROOT_DIR        set to ${EZ_INSTALL_HOME}/generate/packages by default.
#                         This is the global package directory.
# LOCAL_PACKAGE_ROOT_DIR  set to ${HOME}/.ez-install.d/packages by default.
#                         This is the local package directory.
# PACKAGE_DIR             set to ${PACKAGE_ROOT_DIR}/${OS_DISTRIB_ID}/${OS_DISTRIB_RELEASE}.
#                         This is the global package directory according to the
#                         linux distro. Mainly used for package installation.
# LOCAL_PACKAGE_DIR       set to ${LOCAL_PACKAGE_ROOT_DIR}/${OS_DISTRIB_ID}/${OS_DISTRIB_RELEASE}.
#                         This is the local package directory according to the
#                         linux distro. Takes priority over PACKAGE_DIR. Mainly
#                         used for package installation.
# Globals:
#   EZ_INSTALL_HOME
#   HOME
#   LOCAL_PACKAGE_DIR
#   LOCAL_PACKAGE_ROOT_DIR
#   OS_DISTRIB_ID
#   OS_DISTRIB_RELEASE
#   PACKAGE_DIR
#   PACKAGE_ROOT_DIR
# Arguments:
#   None
# Returns:
#   None
# Usage:
#   resolve_package_dir
#######################################
function resolve_package_dir() {
	# TODO: If Linux distro is not found, resolve to the most similar distro if
	# possible.
	os_release
	local distrib_id="${OS_DISTRIB_ID}"
	to_lower distrib_id
	local distrib_release="${OS_DISTRIB_RELEASE}"

	if [[ -z "${PACKAGE_ROOT_DIR+x}" ]]; then
		PACKAGE_ROOT_DIR="$(realpath -s "${EZ_INSTALL_HOME}/generate/packages")"
	fi
	if [[ -z "${LOCAL_PACKAGE_ROOT_DIR+x}" ]]; then
		LOCAL_PACKAGE_ROOT_DIR="${HOME}/.ez-install.d/packages"
	fi
	# Strip trailing '/' in DIR paths
	PACKAGE_ROOT_DIR=${PACKAGE_ROOT_DIR%/}
	LOCAL_PACKAGE_ROOT_DIR=${LOCAL_PACKAGE_ROOT_DIR%/}

	PACKAGE_DIR="${PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
	LOCAL_PACKAGE_DIR="${LOCAL_PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
}

#######################################
# Fetches the package path from the global or local package directory.
# Globals:
#   PACKAGE_DIR
#   LOCAL_PACKAGE_DIR
# Arguments:
#   package_var_name   Variable containing the package name. Also the variable
#                      that will be set to the package path.
#                      e.g., package_var_name="test-package". Then after calling
#                      this function, package_var_name will be set to
#                      package_var_name="/path/to/test-package".
# Returns:
#   BASH_EX_OK                If the package is found.
#   BASH_EZ_EX_PAC_NOTFOUND   If the package is not found.
#   BASH_SYS_EX_USAGE         If the package variable is not set.
# Usage:
#   fetch_package package_var_name
#######################################
function fetch_package() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local package_var_name="${1:-}"
	eval "local package=\"\$${package_var_name}\""

	if [[ -z "${package+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_INVREFVAR}"
		return "$BASH_SYS_EX_USAGE"
	fi

	# Strip trailing '/' in DIR paths
	PACKAGE_DIR="${PACKAGE_DIR%/}"
	LOCAL_PACKAGE_DIR="${LOCAL_PACKAGE_DIR%/}"

	if [[ -e "${LOCAL_PACKAGE_DIR}/${package}" ]]; then
		info "Package '${package}' found in '${LOCAL_PACKAGE_DIR}'"
		eval "${package_var_name}='${LOCAL_PACKAGE_DIR}/${package}'"
		return "$BASH_EX_OK"
	elif [[ -e "${PACKAGE_DIR}/${package}" ]]; then
		info "Package '${package}' found in '${PACKAGE_DIR}'"
		eval "${package_var_name}='${PACKAGE_DIR}/${package}'"
		return "$BASH_EX_OK"
	else
		skip "Package '${package}' not found"
		return "$BASH_EZ_EX_PAC_NOTFOUND"
	fi
}

#######################################
# Checks if the package exists in the global or local package directory.
# Globals:
#   LOCAL_PACKAGE_DIR
#   PACKAGE_DIR
# Arguments:
#   package   The package name.
# Returns:
#   BASH_EX_OK                If the package is found.
#   BASH_EZ_EX_PAC_NOTFOUND   If the package is not found.
# Usage:
#   has_package "$package"
#######################################
function has_package() {
	if [[ ! -e "${LOCAL_PACKAGE_DIR}/${1:?}" ]] && [[ ! -e "${PACKAGE_DIR}/${1}" ]]; then
		return "$BASH_EZ_EX_PAC_NOTFOUND" || return "$BASH_EX_OK"
	fi
}

#######################################
# Selects an item from a list.
# Warning, This function uses `eval` to set the selected item to the variable
# name. Make sure the variable name is not named '_selected_item'
# Globals:
#   None
# Arguments:
#   $1   The variable name to store the selected item.
#   $@   The list of items to select from.
# Returns:
#  BASH_SYS_EX_USAGE         If the variable name or list of items is not set.
#  BASH_EX_OK                If an item is selected.
#  BASH_EX_GENERAL           If no item is selected.
# Usage:
#      list_selector var_name "item1" "item2" "item3"
#######################################
function list_selector() {
	local timeout=
	local prompt=

	OPTIND=1
	while getopts "t:p:" opt; do
		case ${opt} in
		t)
			timeout=${OPTARG}
			;;
		p)
			prompt=${OPTARG}
			;;
		*)
			error "Invalid flag option(s)"
			exit "$BASH_SYS_EX_USAGE"
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local selected_var_name="${1}"
	shift

	if [[ -z "${*}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local list=("$@")
	local _selected_item=""

	if [[ -z "${prompt}" ]]; then
		prompt="Select an item (1-${#list[@]}) from list, or 0 to skip: "
	fi

	if [[ -n "${list[*]}" ]]; then
		if [[ "${#list[@]}" -eq 1 ]]; then
			_selected_item="${list[0]}"
			info "Defaulting to '${_selected_item}'"
		else
			local i=
			while true; do
				# List items
				for i in "${!list[@]}"; do
					printf "%d) %s\n" "$((i + 1))" "${list[$i]}"
				done
				printf "\n"
				# Read input
				if [[ -z "${timeout}" ]]; then
					read -r -p "${prompt}"
				else
					if ! read -r -t "${timeout}" -p "${prompt}"; then
						# Catch possible errors, mainly for timeouts
						printf "Aborted!\n"
						return "$BASH_EX_TIMEOUT"
					fi
				fi
				# Check input
				if [[ "${REPLY}" =~ ^-?[0-9]+$ ]]; then
					if [[ "${REPLY}" -le "${#list[@]}" ]]; then
						[[ "${REPLY}" -eq 0 ]] && return "$BASH_EX_OK" # Skip
						_selected_item="${list[$((REPLY - 1))]}"
						break
					fi
				fi
			done
		fi
	fi

	if [[ -n "${_selected_item}" ]]; then
		eval "${selected_var_name}=${_selected_item}"
		return "$BASH_EX_OK"
	fi
	return "$BASH_EX_GENERAL"
}

#######################################
# Print installer packages in the global or local package directory. Excludes
# pre- and post- installer hooks.
# Globals:
#   PACKAGE_DIR
#   LOCAL_PACKAGE_DIR
# Arguments:
#   $1              String to match in the package name
#   $2 (optional)   String to exclude in the package name
# Returns:
#   BASH_SYS_EX_USAGE   If the string to match is not set.
# Usage:
#   print_packages "$package" "$exclude"
#   print_packages "python" "dev"
#######################################
function print_packages() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local package="${1%.*}"                                  # Strip extension
	local package_ext="${1##*.}"                             # Get extension
	[[ "${package_ext}" == "${package}" ]] && package_ext="" # No extension
	local excluded=${2:-}

	local package_dirs=()
	[[ -d "${PACKAGE_DIR}" ]] && package_dirs=("${package_dirs[@]}" "${PACKAGE_DIR}")
	[[ -d "${LOCAL_PACKAGE_DIR}" ]] && package_dirs=("${package_dirs[@]}" "${LOCAL_PACKAGE_DIR}")

	if [[ -z "${excluded}" ]]; then
		find "${package_dirs[@]}" -type f \
			! -name "*${package}*.pre" \
			! -name "*${package}*.post" \
			! -name "*${package}.${package_ext}.*" \
			-name "*${package}*" |
			sort
	else
		find "${package_dirs[@]}" -type f \
			! -name "*${excluded}*" \
			! -name "*${package}*.pre" \
			! -name "*${package}*.post" \
			! -name "*${package}.${package_ext}.*" \
			-name "*${package}*" |
			sort
	fi
}

#######################################
# Selects a package from the global or local package directory interactively.
# Warning, This function uses `eval` to set the selected package to the variable
# name. Make sure the variable name is not named '_selected_package'
# Globals:
#   PACKAGE_DIR
#   LOCAL_PACKAGE_DIR
# Arguments:
#   $1              Variable to set the selected package path to.
#   $2              String to match in the package name
#   $3 (optional)   String to exclude in the package name.
# Returns:
#   BASH_EX_OK                If the package is found.
#   BASH_EZ_EX_PAC_NOTFOUND   If the package is not found.
#   BASH_SYS_EX_USAGE         If the package variable is not set.
# Usage:
#   select_package "$package" selected_var_name
#######################################
function select_package() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi
	if [[ -z "${2+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local selected_var_name="${1}"
	local package_file="${2}"
	local package="${package_file%.*}" # Strip extension
	local excluded=${3:-}

	readarray -t matches < <(print_packages "${package_file}" "${excluded}")

	local _selected_package=""

	if [[ -n "${matches[*]}" ]]; then
		if [[ "${#matches[@]}" -eq 1 ]]; then
			_selected_package="${matches[0]}"
			warning "Defaulting: ${package} -> $(basename -- "${_selected_package}")"
		else
			printf "\nMultiple '%s' package detected\n\n" "${package}"
			list_selector _selected_package "${matches[@]}"
		fi
	fi

	if [[ -n "${_selected_package}" ]]; then
		eval "${selected_var_name}=${_selected_package}"
		return "$BASH_EX_OK"
	else
		skip "No matching package for '${package}'"
		return "$BASH_EZ_EX_PAC_NOTFOUND"
	fi
}

# WARN: Prepare to deprecate this function. Use print_packages instead.
#######################################
# Checks if a package exists in the global or local package directory.
# Globals:
#   PACKAGE_DIR
#   LOCAL_PACKAGE_DIR
# Arguments:
#   package   The package name to search for.
# Returns:
#   BASH_EX_OK                If the package is found.
#   BASH_EZ_EX_PAC_NOTFOUND   If the package is not found.
#   BASH_SYS_EX_USAGE         If the package variable is not set.
# Usage:
#   select_package "$package" selected_var_name
#######################################
function has_alternate_package() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local package="${1%.*}"                                  # Strip extension
	local package_ext="${1##*.}"                             # Get extension
	[[ "${package_ext}" == "${package}" ]] && package_ext="" # No extension

	local package_dirs=()
	[[ -d "${PACKAGE_DIR}" ]] && package_dirs=("${package_dirs[@]}" "${PACKAGE_DIR}")
	[[ -d "${LOCAL_PACKAGE_DIR}" ]] && package_dirs=("${package_dirs[@]}" "${LOCAL_PACKAGE_DIR}")

	local matches=()

	readarray -t matches < <(
		find "${package_dirs[@]}" -type f \
			! -name "${excluded}" \
			! -name "*${package}*.pre" \
			! -name "*${package}*.post" \
			! -name "*${package}.${package_ext}.*" \
			-name "*${package}*" |
			sort
	)

	if [[ -n "${matches[*]}" ]]; then
		info "Alternate package found for '${package}'"
		return "$BASH_EX_OK"
	fi

	local res=0
	if ! $INSTALL_SKIP_GENERATE; then
		! $DEBUG && printf "\n"
		warning "Generating ${package}"
		${EZ_COMMAND_GEN} -i "${package}"
		res=$?
		[[ $res -eq $BASH_EX_OK ]] && return "$BASH_EZ_EX_PAC_GENERATED" || return $res
	fi

	info "Alternate package NOT found for '${package}'"
	return "$BASH_EZ_EX_PAC_NOTFOUND"
}

# Requires $recursive and $as_root to be defined outside of function
function parse_inline_opts() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local __package="${1%#*}" # Strip #opts
	local __opts="${1##*#}"   # Strip package

	[[ -z ${config+x} ]] && config=""

	if [[ "${__opts}" != "${__package}" ]]; then
		for __opt in ${__opts//,/ }; do
			case ${__opt} in
			force)
				force=true
				strip_substr ' -F' config
				config="${config} -f"
				;;
			noforce)
				force=false
				strip_substr ' -f' config
				config="${config} -F"
				;;
			dep)
				recursive=true
				strip_substr ' -R' config
				config="${config} -r"
				;;
			nodep)
				recursive=false
				strip_substr ' -r' config
				config="${config} -R"
				;;
			root)
				as_root=true
				strip_substr ' -S' config
				config="${config} -s"
				;;
			noroot)
				as_root=false
				strip_substr ' -s' config
				config="${config} -S"
				;;
			allowdepfail)
				allow_dep_fail=true
				strip_substr ' -W' config
				config="${config} -w"
				;;
			nodepfail)
				allow_dep_fail=false
				strip_substr ' -w' config
				config="${config} -W"
				;;
			esac
		done
	fi
}

function get_user_input() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	if [[ -z "${2+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	echo -ne "${2}"
	read -r "${1}"
}

function get_sys_package_manager() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return "$BASH_SYS_EX_USAGE"
	fi

	local manager=""

	if is_darwin; then
		manager='brew'
	elif is_linux; then
		if [[ -x "$(command -v 'apk')" ]]; then
			manager='apk'
		elif [[ -x "$(command -v 'pkg')" ]]; then
			manager='pkg'
		elif [[ -x "$(command -v 'packman')" ]]; then
			manager='packman'
		elif [[ -x "$(command -v 'apt')" ]]; then
			manager='apt'
		elif [[ -x "$(command -v 'dnf')" ]]; then
			manager='dnf'
		elif [[ -x "$(command -v 'zypper')" ]]; then
			manager='zypper'
		fi
	else
		error "${BASH_EZ_MSG_PACMAN_NOTFOUND}"
		return "$BASH_EZ_EX_PACMAN_NOTFOUND"
	fi

	eval "${1}='${manager}'"
}
