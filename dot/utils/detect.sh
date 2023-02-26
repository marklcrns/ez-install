#!/usr/bin/env bash

################################################################################
# Detection functions for detecting changes or deletion between files or
# directories.
#
################################################################################
# Author : Mark Lucernas <https://github.com/marklcrns>
# Date   : 2020-08-14
################################################################################

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath -s "${0}") is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${DOT_UTILS_DETECT_SH_INCLUDED+x}" ]] &&
	readonly DOT_UTILS_DETECT_SH_INCLUDED=1 ||
	return 0

source "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/common/array.sh"
include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/man/print.sh"
include "${EZ_INSTALL_HOME}/actions.sh"

# TODO: Make bidirectional
#       Make diffing changes detect the most recent file
#       Solution: Caching
#
# Compares two file path (would compare recursively if files are directories)
# and returns all files with discrepancies.
# Require at least 3 arguments or args $1, $2, and $3 to execute.
#
# ARGS:
# $1 = Source file path
# $2 = Target file path
# $3 = List of detected changes, including source and target file path separated
#      by ';', and delimited by '\n'.
# $4 = Detected changes count
# $5 = Total files compared
# $6 = Pass in integer '1' to turn on IS_QUITE
#
# Returns $3, $4, $5 variable args with new values from execution.
function detect_change() {
	if [[ -z "${*+x}" ]]; then
		error "${BASH_SYS_MSG_USAGE_MISSARG}" "$BASH_SYS_EX_USAGE"
	fi

	local __source="${1}"
	local __target="${2}"
	local __changes_list="${3}"
	local __changes_count="${4}"
	local __total_files_count="${5}"
	local silent="${6:-0}"

	# Check args count
	if [[ $# -lt 3 ]]; then
		error "${BASH_SYS_MSG_USAGE_INVARG}" "$BASH_EX_GENERAL"
	fi

	# Exit if invalid path
	if [[ ! -e "${__source}" ]]; then
		error "${SCRIPTPATH} ${FUNCNAME[0]}: Invalid source path '${__source}'"
		return 2
	fi

	local __tmp_changes_list=""
	local __tmp_changes_count=0
	local __tmp_total_files_count=0

	strip_trailing_forwardslash __source
	strip_trailing_forwardslash __target

	if [[ -d "${__source}" ]]; then # Directory dotfile
		# Recursively compare
		while IFS= read -r -d '' __source_file; do
			strip_trailing_forwardslash __source_file

			# Get relative path to append to target
			__rel_path_file=$(echo "${__source_file}" | sed "s,${__source}/,,")
			__target_file="${__target}/${__rel_path_file}"

			# Ignore if in DOTFILES_IGNORE_LIST
			if array_has_element "${__source_file}" "${DOTFILES_IGNORE_LIST[@]}"; then
				echo -e "${FG_LT_BLACK}Changes ignored ${__source_file}${ANSI_OFF}\n"
				continue
			fi
			if array_has_element "${__target_file}" "${DOTFILES_IGNORE_LIST[@]}"; then
				echo -e "${FG_LT_BLACK}Changes ignored ${__target_file}${ANSI_OFF}\n"
				continue
			fi

			# Compare dotfiles in target dir with local copy in source dir
			if cmp "${__source_file}" "${__target_file}" &>/dev/null; then
				info "No changes detected in ${__source_file}"
			else
				if [[ -e "${__target_file}" ]]; then
					echo -e "${COLOR_YELLOW}Changes detected:${COLOR_NC}"
					echo -e "${COLOR_BLUE}SOURCE ${__source_file}${COLOR_NC}"
					echo -e "${COLOR_BLUE}TARGET ${__target_file}${COLOR_NC}"
				else
					echo -e "${COLOR_YELLOW}Missing file:${COLOR_NC}"
					echo -e "${COLOR_BLUE}SOURCE ${__source_file}${COLOR_NC}"
					echo -e "${COLOR_RED}TARGET ${__target_file}${COLOR_NC}"
				fi
				# Record changes
				__tmp_changes_count=$((__tmp_changes_count + 1))
				if [[ -z "${__tmp_changes_list}" ]]; then
					__tmp_changes_list="${__source_file};${__target_file}"
				else
					__tmp_changes_list="${__tmp_changes_list}\n${__source_file};${__target_file}"
				fi
			fi
			# Increment total files compared
			__tmp_total_files_count=$((__tmp_total_files_count + 1))
		done < <(find "${__source}" -not -path "*/.git/*" -type f -print0) # Process substitution for outside variables
	else                                                                # Non-directory dotfile
		# Compare dotfiles in target dir with local copy in source dir
		if cmp -s "${__source}" "${__target}" &>/dev/null; then
			info "No changes detected in ${__source}"
		else
			if [[ -e "${__target}" ]]; then
				echo -e "${COLOR_YELLOW}Changes detected:${COLOR_NC}"
				echo -e "${COLOR_BLUE}SOURCE ${__source}${COLOR_NC}"
				echo -e "${COLOR_BLUE}TARGET ${__target}${COLOR_NC}"
			else
				echo -e "${COLOR_YELLOW}Missing file:${COLOR_NC}"
				echo -e "${COLOR_BLUE}SOURCE ${__source}${COLOR_NC}"
				echo -e "${COLOR_RED}TARGET ${__target}${COLOR_NC}"
			fi
			# Record changes
			__tmp_changes_count=$((__tmp_changes_count + 1))
			if [[ -z "${__tmp_changes_list}" ]]; then
				__tmp_changes_list="${__source};${__target}"
			else
				__tmp_changes_list="${__tmp_changes_list}\n${__source};${__target}"
			fi
		fi
		# Increment total files compared
		__tmp_total_files_count=$((__tmp_total_files_count + 1))
	fi
	# Return variables
	[[ -n "${__changes_list}" ]] && eval $__changes_list="'$__tmp_changes_list'"
	[[ -n "${__changes_count}" ]] && eval $__changes_count=$__tmp_changes_count
	[[ -n "${__total_files_count}" ]] && eval $__total_files_count=$__tmp_total_files_count
}

# Compares two file path (would compare recursively if files are directories)
# and returns all files that does not exists in the target file or directory.
# Require at least 3 arguments or args $1, $2, and $3 to execute.
#
# ARGS:
# $1 = Source file path
# $2 = Target file path
# $3 = List of source files that does not exist in the target file path.
# $4 = Detected changes count
# $5 = Total files compared
# $6 = Pass in integer '1' to turn on IS_QUITE
#
# Returns $3, $4, $5 variable args with new values from execution.
function detect_delete() {
	local __source="${1}"
	local __target="${2}"
	local __deletion_list="${3}"
	local __deletion_count="${4}"
	local __total_files_count="${5}"
	local silent="${6:-0}"

	# Check args count
	if [[ $# -lt 3 ]]; then
		warning "${COLOR_RED}${FUNCNAME[0]}: Invalid number of arguments${COLOR_NC}"
		return 1
	fi

	local __tmp_deletion_list=""
	local __tmp_deletion_count=0
	local __tmp_total_files_count=0

	strip_trailing_forwardslash __source
	strip_trailing_forwardslash __target

	if [[ -d "${__source}" ]]; then # Directory dotfile
		# Recursively compare
		while IFS= read -r -d '' __source_file; do
			strip_trailing_forwardslash __source_file

			# Get relative path to append to target
			__rel_path_file=$(echo "${__source_file}" | sed "s,${__source}/,,")
			__target_file="${__target}/${__rel_path_file}"

			# Ignore if in DOTFILES_IGNORE_LIST
			if array_has_element "${__source_file}" "${DOTFILES_IGNORE_LIST[@]}"; then
				echo -e "${FG_LT_BLACK}Deletion ignored ${__source_file}${ANSI_OFF}\n"
				continue
			fi
			if array_has_element "${__target_file}" "${DOTFILES_IGNORE_LIST[@]}"; then
				echo -e "${FG_LT_BLACK}Deletion ignored ${__target_file}${ANSI_OFF}\n"
				continue
			fi

			# Check deleted files
			if [[ ! -e "${__target_file}" ]]; then
				# Record deletion if not NO_DELETE
				if [[ -z "${NO_DELETE}" ]]; then
					warning "${COLOR_RED}File to be deleted ${__source_file}${COLOR_NC}"

					__tmp_deletion_count=$((__tmp_deletion_count + 1))
				else
					warning "${COLOR_RED}File to be deleted ${__source_file} ${COLOR_YELLOW}SKIPPED${COLOR_NC}"
				fi
				# Append to changes list
				if [[ -z ${__tmp_deletion_list} ]]; then
					__tmp_deletion_list="${__source_file}"
				else
					__tmp_deletion_list="${__tmp_deletion_list}\n${__source_file}"
				fi
			fi
			# Increment total files compared
			__tmp_total_files_count=$((__tmp_total_files_count + 1))
		done < <(find "${__source}" -not -path "*/.git/*" -type f -print0) # Process substitution for outside variables
	else                                                                # Non-directory dotfile
		# Check deleted files
		if [[ ! -e "${__target}" ]]; then
			warning "${COLOR_RED}File does not exist ${__source}${COLOR_NC}"
			# Record changes
			__tmp_deletion_count=$((__tmp_deletion_count + 1))
			if [[ -z ${__tmp_deletion_list} ]]; then
				__tmp_deletion_list="${__source}"
			else
				__tmp_deletion_list="${__tmp_deletion_list}\n${__source}"
			fi
		fi
		# Increment total files compared
		__tmp_total_files_count=$((__tmp_total_files_count + 1))
	fi

	# Return variables
	[[ -n "${__deletion_list}" ]] && eval $__deletion_list="'$__tmp_deletion_list'"
	[[ -n "${__deletion_count}" ]] && eval $__deletion_count=$__tmp_deletion_count
	[[ -n "${__total_files_count}" ]] && eval $__total_files_count=$__tmp_total_files_count
}
