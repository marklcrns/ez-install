#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${GENERATE_GENERATE_SH_INCLUDED+x}" ]] &&
	readonly GENERATE_GENERATE_SH_INCLUDED=1 ||
	return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"
include "${EZ_INSTALL_HOME}/actions.sh"

function generate_template_main() {
	generate_template "$@" "${EZ_INSTALL_HOME}/generate/utils/pac_template.txt"
	return $?
}
function generate_template_pre() {
	generate_template "$@" "${EZ_INSTALL_HOME}/generate/utils/pac_pre_template.txt"
	return $?
}
function generate_template_post() {
	generate_template "$@" "${EZ_INSTALL_HOME}/generate/utils/pac_post_template.txt"
	return $?
}

function generate_template() {
	local args=""
	local author=""
	local command_name=""
	local dependencies=""
	local package_manager=""
	local package_name=""
	local destination=""
	local package=""
	local execute=false
	local force=false
	local as_root=false
	local allow_dep_fail=false
	local update=false
	local skip_edit=false

	# Required to parse string args with quoted OPTARG containing spaces
	eval set -- "${@:-}"

	local OPTIND=1
	while getopts "a:A:c:d:m:n:o:p:eEfFsSuUwWt" opt; do
		case ${opt} in
		# Sed strip all trailing and leading 'quotes' and "double-quotes"
		a) args="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		A) author="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		c) command_name="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		d) dependencies="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		m)
			package_manager="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")"
			to_lower package_manager
			;;
		n) package_name="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		o) destination="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		p) package="$(sed -e "s/^[\"']*//" -e "s/[\"']*$//" <<<"${OPTARG}")" ;;
		e) execute=true ;;
		E) execute=false ;;
		f) force=true ;;
		F) force=false ;;
		s) as_root=true ;;
		S) as_root=false ;;
		u) update=true ;;
		U) update=false ;;
		w) allow_dep_fail=true ;;
		W) allow_dep_fail=false ;;
		t) skip_edit=true ;;
		*)
			error "Invalid flag option(s) -- ${opt}"
			exit $BASH_SYS_EX_USAGE
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	if [[ -z "${2+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local file_path="${1}"
	local template_path="${2}"
	[[ -z "${package}" ]] && package="$(basename -- ${file_path})"

	# Remove hook and package manager extensions individually to permit other
	# extensions.
	# NOTE: the format strictly need to be in package.<package-manager>.<hook>
	if ! is_package_manager_downloader "${package_manager}" && [[ "${package_manager}" != 'apt-add' ]]; then
		package="$(sed "s/\.\(${EZ_SUPPORTED_PACKAGE_MANAGER// /\\.\\?\\|}\)\?\(\.pre\|\.post\)\?$//" <<<"${package}")"
	fi

	# Fallbacks for required fields
	[[ -z "${package_name}" ]] && package_name="${package}"

	# Clean data of excess quotes double-quotes

	if check_package "${file_path}" && ! $SKIP_CONFIRM; then
		confirm "'${file_path}' already exist. Continue? (Y/y): " || return $BASH_EZ_EX_PAC_EXIST
	fi

	local res=0
	if execlog "echo -n '' > '${file_path}' && chmod +x '${file_path}'"; then
		while IFS= read -r line; do
			eval "echo \"${line}\" >> '${file_path}'"
		done <"${template_path}"
		res=$?
		[[ $res -eq $BASH_EX_OK ]] && ok "Package generated '${file_path}'"
	else
		error "${file_path} package creation failed!"
		return $BASH_SYS_EX_CANTCREAT
	fi

	! ${skip_edit} && open_editor_package "${file_path}"
	return $res
}

function i_generate_template_main() {
	local args=""
	local author=""
	local command_name=""
	local dependencies=""
	local package_manager=""
	local package_name=""
	local destination=""
	local execute=""
	local force=""
	local update=""
	local as_root=""
	local allow_dep_fail=""
	local skip_edit=false

	eval set -- "${@:-}"

	OPTIND=1
	while getopts "a:A:c:d:m:n:o:p:eEfFsSuUwWt" opt; do
		case ${opt} in
		# Sed strip all trailing and leading 'quotes' and "double-quotes"
		a) args="${OPTARG}" ;;
		A) author="${OPTARG}" ;;
		c) command_name="${OPTARG}" ;;
		d) dependencies="${OPTARG}" ;;
		m)
			package_manager="${OPTARG}"
			to_lower package_manager
			;;
		n) package_name="${OPTARG}" ;;
		o) destination="${OPTARG}" ;;
		p) package="${OPTARG}" ;;
		e) execute=true ;;
		E) execute=false ;;
		f) force=true ;;
		F) force=false ;;
		s) as_root=true ;;
		S) as_root=false ;;
		u) update=true ;;
		U) update=false ;;
		w) allow_dep_fail=true ;;
		W) allow_dep_fail=false ;;
		t) skip_edit=true ;;
		*)
			error "Invalid flag option(s) -- ${opt}"
			exit $BASH_SYS_EX_USAGE
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local file_path="${1}"
	local package_dir="$(dirname -- "${file_path}")"

	local res=0
	local matches=()
	local indent="  "

	echo -e "\nGenerating main package installer..."
	echo -e "\n${indent}${COLOR_HI_BLACK}Press [enter] to skip optionals.${COLOR_NC}"

	while true; do
		echo ""
		prompt_input author "${indent}Author: "
		prompt_input package "${indent}*Package: "
		prompt_input dependencies "${indent}Dependencies (',' delimiter): "
		prompt_package_manager package_manager "${indent}Package manager: "
		prompt_input command_name "${indent}Executable name: "
		prompt_input package_name "${indent}Package name: "

		if [[ -n ${package_manager} ]]; then
			if [[ ${package_manager} == "curl" ]] ||
				[[ ${package_manager} == "wget" ]] ||
				[[ ${package_manager} == "git" ]]; then
				# Curl, wget git packages
				while [[ -z "${package_name}" ]]; do
					package_name="${package%.*}"
					prompt_input package_name "${indent}*Package name: "
				done
				package=""
				while [[ -z "${package}" ]]; do
					prompt_input package "${indent}${indent}*Package Url: "
				done
				prompt_dir destination "${indent}${indent}Destination Path: "
				if [[ ${package_manager} == "curl" ]] ||
					[[ ${package_manager} == "wget" ]]; then
					prompt_boolean execute "${indent}${indent}Shell execute (default=false): "
				fi
			elif [[ ${package_manager} == "apt" ]] ||
				[[ ${package_manager} == "apt-add" ]] ||
				[[ ${package_manager} == "pkg" ]]; then
				# Ask for update if apt, apt-add or pkg
				prompt_boolean update "${indent}${indent}${package_manager} update (default=false): "
			fi
			prompt_input args "${indent}${indent}${package_manager:-'Package Manager'} args: "
		fi
		prompt_boolean as_root "${indent}As root (default=false): "
		[[ -z "${package_name}" ]] && package_name="${package%.*}"

		if [[ -d "${package_dir}" ]]; then
			matches=(
				$(
					find "${package_dir}" -type f \
						! -name "*${package_name}*.pre" \
						! -name "*${package_name}*.post" \
						-name "${package_name}?${package_manager}"
				)
			)
		fi

		if [[ -n "${matches+x}" ]]; then
			echo -e "\nSimilar package(s) found:\n"
			local i=
			for i in "${!matches[@]}"; do
				printf "$(($i + 1))) ${matches[$i]}\n"
			done
		fi

		if [[ -n "${package}" ]]; then
			local file_path="${package_dir}/${package_name}"
			[[ -n "${package_manager}" ]] && file_path+=".${package_manager}"

			if [[ -e "${file_path}" ]]; then
				echo ""
				warning "About to overwrite '${file_path}'"
			fi
			echo ""

			prompt_confirm "${COLOR_YELLOW}Are you ok with these? (y/N):${COLOR_NC} " && break
		else
			echo ""
			if ! prompt_confirm "${COLOR_YELLOW}Missing required field(s). Start over? (y/N):${COLOR_NC} "; then
				return $BASH_SYS_EX_CANTCREAT
			fi
			package=""
			package_name=""
			package_manager=""
			author=""
			dependencies=""
			command_name=""
			destination=""
			execute=""
			update=""
			args=""
			echo ""
		fi
	done

	# Escape whitespaces
	local ez_gen_args=
	[[ -n "${args}" ]] && ez_gen_args+=" -a '${args}'"
	[[ -n "${author}" ]] && ez_gen_args+=" -A '${author}'"
	[[ -n "${command_name}" ]] && ez_gen_args+=" -c '${command_name}'"
	[[ -n "${dependencies}" ]] && ez_gen_args+=" -d '${dependencies}'"
	[[ -n "${package_name}" ]] && ez_gen_args+=" -n '${package_name}'"
	[[ -n "${package_manager}" ]] && ez_gen_args+=" -m '${package_manager}'"
	[[ -n "${destination}" ]] && ez_gen_args+=" -o '${destination}'"
	${execute:-false} && ez_gen_args+=" -e" || ez_gen_args+=" -E"
	${force:-false} && ez_gen_args+=" -f" || ez_gen_args+=" -F"
	${update:-false} && ez_gen_args+=" -u" || ez_gen_args+=" -U"
	${as_root:-false} && ez_gen_args+=" -s" || ez_gen_args+=" -S"
	${skip_edit:-false} && ez_gen_args+=" -t"
	! ${VERBOSE} && ez_gen_args+=" -q"

	generate_template_main "${ez_gen_args}" -- "${file_path}"

	res=$?
	return $res
}

function i_generate_template_pre() {
	i_generate_template_hook "${@}" 'pre'
	return $?
}
function i_generate_template_post() {
	i_generate_template_hook "${@}" 'post'
	return $?
}

function i_generate_template_hook() {
	local author=""
	local package_manager=""
	local package_name=""
	local force=""
	local as_root=""
	local skip_edit=false

	eval set -- "${@:-}"

	OPTIND=1
	while getopts "A:m:n:p:fFsSt" opt; do
		case ${opt} in
		# Sed strip all trailing and leading 'quotes' and "double-quotes"
		A) author="${OPTARG}" ;;
		m)
			package_manager="${OPTARG}"
			to_lower package_manager
			;;
		n) package_name="${OPTARG}" ;;
		p) package="${OPTARG}" ;;
		f) force=true ;;
		F) force=false ;;
		s) as_root=true ;;
		S) as_root=false ;;
		t) skip_edit=true ;;
		*)
			error "Invalid flag option(s) -- ${opt}"
			exit $BASH_SYS_EX_USAGE
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	if [[ -z "${2+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local file_path="${1}"
	local hook="${2}"
	to_lower hook
	local package_dir="$(dirname -- "${file_path}")"

	if [[ "${hook}" == 'pre' ]]; then
		local hook_counter='post'
	elif [[ "${hook}" == 'post' ]]; then
		local hook_counter='pre'
	else
		error "${BASH_SYS_MSG_USAGE_INVARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local res=0
	local matches=()
	local indent="  "

	echo -e "\nGenerating ${hook} hook package installer..."
	echo -e "\n${indent}${COLOR_HI_BLACK}All optional. Press [enter] to skip.${COLOR_NC}\n"

	while true; do
		prompt_input package_name "${indent}*Package name: "
		package="${package_name}"
		prompt_package_manager package_manager "${indent}Package manager: "
		prompt_boolean as_root "${indent}As root (default=false): "

		if [[ -d "${package_dir}" ]]; then
			matches=(
				$(
					find "${package_dir}" -type f \
						! -name "*${package_name}*.${hook_counter}" \
						-name "${package_name}?${package_manager}.${hook}"
				)
			)
		fi

		if [[ -n "${matches+x}" ]]; then
			echo -e "\nSimilar package(s) found:\n"
			local i=
			for i in "${!matches[@]}"; do
				printf "$(($i + 1))) ${matches[$i]}\n"
			done
		fi

		if [[ -n "${package}" ]]; then
			local file_path="${package_dir}/${package_name}"
			[[ -n "${package_manager}" ]] && file_path+=".${package_manager}"

			if [[ -e "${file_path}.${hook}" ]]; then
				echo ""
				warning "About to overwrite '${file_path}.${hook}'"
			fi
			echo ""

			prompt_confirm "${COLOR_YELLOW}Are you ok with these? (y/N):${COLOR_NC} " && break
		else
			echo ""
			if ! prompt_confirm "${COLOR_YELLOW}Missing required field(s). Start over? (y/N):${COLOR_NC} "; then
				return $BASH_SYS_EX_CANTCREAT
			fi
			package=""
			package_name=""
			package_manager=""
			echo ""
		fi
	done

	# Escape whitespaces
	local ez_gen_args=
	[[ -n "${author}" ]] && ez_gen_args+=" -A '${author}'"
	[[ -n "${package_name}" ]] && ez_gen_args+=" -n '${package_name}'"
	[[ -n "${package_manager}" ]] && ez_gen_args+=" -m '${package_manager}'"
	${force:-false} && ez_gen_args+=" -f" || ez_gen_args+=" -F"
	${as_root:-false} && ez_gen_args+=" -s" || ez_gen_args+=" -S"
	${skip_edit:-false} && ez_gen_args+=" -t"
	! ${VERBOSE} && ez_gen_args+=" -q"

	if [[ ${hook} == 'pre' ]]; then
		generate_template_pre ${ez_gen_args} -- "${file_path}.pre"
	else
		generate_template_post ${ez_gen_args} -- "${file_path}.post"
	fi

	res=$?
	return $res
}

function prompt_input() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local _input_var_name="${1}"
	local _message="${2:-'Enter input: '}"
	eval "local _input=\${${_input_var_name}}"

	if [[ -z "${_input}" ]]; then
		get_user_input _input "${_message}"
	else
		echo -e "${_message}${_input}"
	fi
	eval "${_input_var_name}='${_input}'"
}

function prompt_package_manager() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local _package_manager_var_name="${1}"
	local _message="${2:-'Package manager: '}"
	eval "local _package_manager=\${$1}"

	if [[ -z "${_package_manager}" ]]; then
		while ! is_package_manager_supported "${_package_manager}"; do
			get_user_input _package_manager "${_message}"
			[[ -z "${_package_manager}" ]] && break
		done
	else
		echo -e "${_message}${_package_manager}"
	fi
	eval "${_package_manager_var_name}='${_package_manager}'"
}

function prompt_dir() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local _dir_var_name="${1}"
	local _message="${2:-'Directory: '}"
	eval "local _dir=\${$1}"

	if [[ -z "${_dir}" ]]; then
		get_user_input _dir "${_message}"
	else
		echo -e "${_message}${_dir}"
	fi
	eval "${_dir_var_name}='${_dir}'"
}

function prompt_boolean() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local _boolean_var_name="${1}"
	eval "local _boolean=\${$1}"

	local _default="${_boolean}"
	if [[ -z "${_boolean}" ]] || [[ "${_boolean}" != 'true' ]] && [[ "${_boolean}" != 'false' ]]; then
		_default=false
	fi

	local _message="${2:-Boolean \(default=${_default}\): }"

	get_user_input _boolean "${_message}"
	if [[ -z "${_boolean}" ]]; then
		_boolean="${_default}"
	else
		while [[ "${_boolean}" != 'true' ]] && [[ "${_boolean}" != 'false' ]]; do
			get_user_input _boolean "${_message}"
			if [[ -z "${_boolean}" ]]; then
				_boolean="${_default}"
				break
			fi
		done
	fi
	eval "${_boolean_var_name}=${_boolean}"
}

function prompt_confirm() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local _message="${1}"
	local _continue=""

	while ! [[ "${_continue}" =~ ^[YyNn]$ ]]; do
		get_user_input _continue "${_message}"
	done
	if [[ "${_continue}" == 'y' ]] || [[ "${_continue}" == 'y' ]]; then
		return $BASH_EX_OK
	fi
	return $BASH_EX_GENERAL
}

function is_package_manager_supported() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local _pacman
	for _pacman in ${EZ_SUPPORTED_PACKAGE_MANAGER}; do
		if [ "${1}" = "${_pacman}" ]; then
			return $BASH_EX_OK
		fi
	done
	return $BASH_EZ_EX_PACMAN_NOTFOUND
}

function is_package_manager_downloader() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	if [[ "${1}" == 'curl' ]] || [[ "${1}" == 'wget' ]] || [[ "${1}" == 'git' ]]; then
		return $BASH_EX_OK
	fi
	return $BASH_EX_GENERAL
}

function is_package_ppa() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	if [[ "${1}" =~ ppa:.* ]]; then
		return $BASH_EX_OK
	fi
	return $BASH_EX_GENERAL
}

function check_package() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local package="${1:-}"

	if [[ -z "${@+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	[[ -e "${package}" ]] && return 0 || return $BASH_EX_GENERAL
}

function give_exec_permission() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local file_path="${1}"
	local res=0

	if [[ -e "${file_path}" ]]; then
		if eval "chmod +x '${file_path}'"; then
			finish "${file_path} package created!"
			return $BASH_EX_OK
		fi
		res=$?
	else
		res=$BASH_EZ_EX_PAC_NOTFOUND
	fi

	error "${file_path} package creation failed!"
	return $res
}

function open_editor_package() {
	if [[ -z "${1+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}"
		return $BASH_SYS_EX_USAGE
	fi

	local file_path="${1}"
	local editor="${EZ_EDITOR:-${EDITOR:-vim}}"

	if [[ -z "${editor}" ]]; then
		error "No \$EDITOR specified to edit package"
	fi

	if check_package "${file_path}"; then
		if prompt_confirm "Do you wish to edit '${file_path}' now? (y/N): "; then
			${editor} "${file_path}"
		fi
		return $BASH_EX_OK
	fi
	return $BASH_EZ_EX_PAC_EXIST
}
