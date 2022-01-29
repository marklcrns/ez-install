#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${UTILS_PAC_LOGGER_SH_INCLUDED+x}" ]] \
  && readonly UTILS_PAC_LOGGER_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"


[[ -z "${SUCCESSFUL_PACKAGES+x}" ]] && declare -a SUCCESSFUL_PACKAGES=()
[[ -z "${SKIPPED_PACKAGES+x}" ]]    && declare -a SKIPPED_PACKAGES=()
[[ -z "${FAILED_PACKAGES+x}" ]]     && declare -a FAILED_PACKAGES=()


function pac_log_success() { _pac_log -r 'SUCCESSFUL_PACKAGES' -m 'ok' "${@}"; }
function pac_log_skip()    { _pac_log -r 'SKIPPED_PACKAGES' -m 'skip' "${@}"; }
function pac_log_failed()  { _pac_log -r 'FAILED_PACKAGES' -m 'error' "${@}"; }

function _pac_log() {
  local message_command=""
  local report_array_name=""
  local skip_tally=false

  OPTIND=1
  while getopts "m:r:x" opt; do
    case ${opt} in
      m) message_command="${OPTARG}" ;;
      r) report_array_name="${OPTARG}" ;;
      x) skip_tally=true ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi
  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local exit_code=$1
  local has_exit_code=false
  if is_integer $exit_code; then
    has_exit_code=true
    shift
  fi

  local manager="${1}"
  local package="${2}"
  local message="${3:-}"

  # '-d 3' offsets _pac_log() and its wrapper functions
  if [[ -n "${message}" ]]; then
    ${message_command} -d 3 "${message}"
  else
    ${message_command} -d 3 "${manager} '${package}' package installation failed"
  fi

  local log=""
  if $has_exit_code; then
    log="'${package}' FAILED [$exit_code]"
  else
    log="'${package}' FAILED"
  fi

  [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
  ! $skip_tally && handle_duplicates -s "${log}" ${report_array_name}
}


function handle_duplicates() {
  local stack=false

  OPTIND=1
  while getopts "s" opt; do
    case ${opt} in
      s) stack=true ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local new_log="${1}"
  local array_name="${2}"

  local log=()
  eval "log=( \"\${${array_name}[@]}\" )"

  local i=
  local repeat=
  local stripped=
  for ((i = 0; i < ${#log[@]}; ++i)); do
    if has_substr "${new_log}" "${log[$i]}"; then
      # Prepend '($repeat)' to new_log
      if $stack; then
        repeat="$(echo "${log[$i]}" | sed -e 's/^(\(.*\)).*/\1/')"    # extract repeat
        stripped="$(echo "${log[$i]}" | sed -e 's/^(\(.*\))\s*//')"   # strip (repeat)
        if is_integer "${repeat}"; then
          eval "${array_name}[$i]=\"($(($repeat+1))) ${stripped}\""
        else
          eval "${array_name}[$i]=\"(2) ${stripped}\""
        fi
      fi
      return $BASH_EX_OK
    fi
  done

  # Add new_log to report
  eval "${array_name}=( \"\${${array_name}[@]}\" \"${new_log}\" )"
}


function pac_report() {
  local total_count=0
  local successful_count=0
  local skipped_count=0
  local failed_count=0

  local reports=(
    "SUCCESSFUL_PACKAGES"
    "SKIPPED_PACKAGES"
    "FAILED_PACKAGES"
  )

  local -A report_desc
  report_desc['SUCCESSFUL_PACKAGES']="Successful Installations"
  report_desc['SKIPPED_PACKAGES']="Skipped Installations"
  report_desc['FAILED_PACKAGES']="Failed Installations"

  local -A report_colors
  report_colors['SUCCESSFUL_PACKAGES']="${COLOR_GREEN}"
  report_colors['SKIPPED_PACKAGES']="${COLOR_BLUE}"
  report_colors['FAILED_PACKAGES']="${COLOR_RED}"

  for report in ${reports[@]}; do
    local package_reports=()
    eval "package_reports=( \"\${${report}[@]}\" )"

    if [[ -n "${package_reports[@]}" ]]; then
      echo -e "\n${COLOR_UL_NC}"${report_desc["${report}"]}"${COLOR_NC}\n"
      for ((i = 0; i < ${#package_reports[@]}; ++i)); do
        echo -e "${report_colors["${report}"]}${package_reports[$i]}${COLOR_NC}"
        total_count=$(expr ${total_count} + 1)
        successful_count=$(expr ${successful_count} + 1)
      done
    fi
  done

  # DEPRECATED: For reference only
  # if [[ -n ${SUCCESSFUL_PACKAGES[@]} ]]; then
  #   echo -e "\n${COLOR_UL_NC}Successful Installations${COLOR_NC}\n"
  #   for ((i = 0; i < ${#SUCCESSFUL_PACKAGES[@]}; ++i)); do
  #     echo -e "${COLOR_GREEN}${SUCCESSFUL_PACKAGES[$i]}${COLOR_NC}"
  #     total_count=$(expr ${total_count} + 1)
  #     successful_count=$(expr ${successful_count} + 1)
  #   done
  # fi

  # if [[ -n ${SKIPPED_PACKAGES[@]} ]]; then
  #   echo -e "\n${COLOR_UL_NC}Skipped Installations${COLOR_NC}\n"
  #   for ((i = 0; i < ${#SKIPPED_PACKAGES[@]}; ++i)); do
  #     echo -e "${COLOR_BLUE}${SKIPPED_PACKAGES[$i]}${COLOR_NC}"
  #     total_count=$(expr ${total_count} + 1)
  #     skipped_count=$(expr ${skipped_count} + 1)
  #   done
  # fi

  # if [[ -n ${FAILED_PACKAGES[@]} ]]; then
  #   echo -e "\n${COLOR_UL_NC}Failed Installations${COLOR_NC}\n"
  #   for ((i = 0; i < ${#FAILED_PACKAGES[@]}; ++i)); do
  #     echo -e "${COLOR_RED}${FAILED_PACKAGES[$i]}${COLOR_NC}"
  #     total_count=$(expr ${total_count} + 1)
  #     failed_count=$(expr ${failed_count} + 1)
  #   done
  # fi

  cat << EOF

Successful │ ${successful_count}
Skipped    │ ${skipped_count}
Failed     │ ${failed_count}
———————————│—————
TOTAL      │ ${total_count}

EOF
}



# DEPRECATED: For reference only
# function pac_log_success() {
#   local skip_tally=false

#   OPTIND=1
#   while getopts "x" opt; do
#     case ${opt} in
#       x) skip_tally=true ;;
#       *)
#         error "Invalid flag option(s)"
#         exit $BASH_SYS_EX_USAGE
#     esac
#   done
#   shift "$((OPTIND-1))"

#   if [[ -z "${1+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi
#   if [[ -z "${2+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi

#   local manager="${1}"
#   local package="${2}"
#   local message="${3:-}"

#   if [[ -n "${message}" ]]; then
#     ok -d 2 "${message}"
#   else
#     ok -d 2 "${manager} '${package}' package installation successful"
#   fi

#   local log="'${package}' SUCCESSFUL"

#   [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
#   ! $skip_tally && handle_duplicates -s "${log}" SUCCESSFUL_PACKAGES
# }


# function pac_log_skip() {
#   local skip_tally=false

#   OPTIND=1
#   while getopts "x" opt; do
#     case ${opt} in
#       x) skip_tally=true ;;
#       *)
#         error "Invalid flag option(s)"
#         exit $BASH_SYS_EX_USAGE
#     esac
#   done
#   shift "$((OPTIND-1))"

#   if [[ -z "${1+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi
#   if [[ -z "${2+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi

#   local exit_code=$1
#   local has_exit_code=false
#   if is_integer $exit_code; then
#     has_exit_code=true
#     shift
#   fi

#   local manager="${1}"
#   local package="${2}"
#   local message="${3:-}"

#   if [[ -n "${message}" ]]; then
#     skip -d 2 "${message}"
#   else
#     skip -d 2 "${manager} '${package}' package already installed"
#   fi

#   local log=""
#   if $has_exit_code; then
#     log="'${package}' SKIPPED [$exit_code]"
#   else
#     log="'${package}' SKIPPED"
#   fi

#   [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
#   ! $skip_tally && handle_duplicates -s "${log}" SKIPPED_PACKAGES
# }


# function pac_log_failed() {
#   local skip_tally=false

#   OPTIND=1
#   while getopts "x" opt; do
#     case ${opt} in
#       x) skip_tally=true ;;
#       *)
#         error "Invalid flag option(s)"
#         exit $BASH_SYS_EX_USAGE
#     esac
#   done
#   shift "$((OPTIND-1))"

#   if [[ -z "${1+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi
#   if [[ -z "${2+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi

#   local exit_code=$1
#   local has_exit_code=false
#   if is_integer $exit_code; then
#     has_exit_code=true
#     shift
#   fi

#   local manager="${1}"
#   local package="${2}"
#   local message="${3:-}"

#   if [[ -n "${message}" ]]; then
#     error -d 2 "${message}"
#   else
#     error -d 2 "${manager} '${package}' package installation failed"
#   fi

#   local log=""
#   if $has_exit_code; then
#     log="'${package}' FAILED [$exit_code]"
#   else
#     log="'${package}' FAILED"
#   fi

#   [[ "${manager}" != 'N/A' ]] && log="${manager} ${log}"
#   ! $skip_tally && handle_duplicates -s "${log}" FAILED_PACKAGES
# }


# function has_pac_log_duplicate() {
#   if [[ -z "${1+x}" ]]; then
#     error "${BASH_SYS_MSG_USAGE_MISSARG}"
#     return $BASH_SYS_EX_USAGE
#   fi

#   local new_log="${1}"
#   shift 1
#   local log=( "${@}" )

#   local i=
#   for ((i = 0; i < ${#log[@]}; ++i)); do
#     if has_substr "${new_log}" "${log[$i]}"; then
#       return $BASH_EX_OK
#     fi
#   done

#   return $BASH_EX_GENERAL
# }

