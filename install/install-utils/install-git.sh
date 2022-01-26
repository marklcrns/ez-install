#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_GIT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_GIT_SH_INCLUDED=1 \
  || return $BASH_EX_OK


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"


function git_clone() {
  local forced=false
  local as_root=false
  local args=""
  local command_name=""
  local package_name=""
  local output_path=""

  OPTIND=1
  while getopts "a:c:f:n:o:S:" opt; do
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
      o)
        output_path="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local from="${@}"
  local sudo=""
  ! ${VERBOSE:-false}        && args+=' -q'
  [[ -z "${package_name}" ]] && package_name="${from}"

  if $as_root; then
    if command -v sudo &> /dev/null; then
      sudo="sudo "
    else
      pac_log_failed $BASH_EX_MISUSE 'Git' "${package_name}" "Git '${package_name}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  local res=0

  is_git_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed $res 'Git' "${package_name}" "Git '${package_name}' installation failed. git not installed"
    return $res
  fi

  if $forced; then
    # Check if already installed
    if [[ -n ${command_name} ]] && command -v ${command_name} &> /dev/null; then
      pac_log_skip "Git" "${package_name}"
      return $BASH_EX_OK
    fi
  fi

  # Validate git repo link
  is_git_remote_reachable "${from}"
  res=$?
  if [[ $res -eq 2 ]]; then
    pac_log_failed $res 'Git' "${package_name}" "Git clone '${package_name}' failed! Authentication timeout"
    return $res
  elif [[ $res -eq 1 ]]; then
    pac_log_failed $res 'Git' "${package_name}" "Git clone '${package_name}' failed! Invalid git remote url"
    return $res
  fi

  # Resolve output_path
  local filename="$(basename -- "${from}" '.git')"
  if [[ -z "${output_path}" ]]; then
    output_path="${EZ_DOWNLOADS_DIR}/${filename}"
  fi
  # NOTE: ~ does not expand when `test -d`, i.e., [[ -d "${output_path}" ]]
  output_path=${output_path//\~/${HOME}}
  if [[ -d "${output_path}" ]]; then
    output_path="${output_path}/${filename}"
  fi

  # Replace existing repo output_path dir if force
  if [[ -d "${output_path}" ]]; then
    if ${forced}; then
      is_git_repo "${output_path}"
      res=$?
      if [[ $res -ne $BASH_EX_OK ]] ; then
        pac_log_failed $res 'Git' "${package_name}" "Git clone '${package_name}' failed! '${output_path}' already exist and is not a git repository"
        return $res
      fi
      warning "Replacing '${output_path}' Git repository"
      execlog "rm -rf '${output_path}'"
    else
      is_git_repo "${output_path}"
      res=$?
      if [[ $res -ne $BASH_EX_OK ]] ; then
        pac_log_failed $res 'Git' "${package_name}" "Git clone '${package_name}' failed! '${output_path}' already exist"
        return $res
      fi
      pac_log_skip "Git" "${package_name}"
      return $res
    fi
  fi

  pac_pre_install -o "${output_path}" -f $forced -S $as_root "${package_name}" 'git'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  # DEPRECATED: For reference only
  # Execute cloning
  # clone_repo -a "${args}" -n "${package_name}" -o "${output_path}" -S $as_root -- "${from}"
  # res=$?
  # if [[ $res -ne $BASH_EX_OK ]]; then
  #   if [[ $res -eq $BASH_SYS_EX_SOFTWARE ]]; then
  #     pac_log_failed $res 'Git' "${package_name}" "Git clone '${package_name}' failed! Authentication timeout"
  #   else
  #     pac_log_failed $res 'Git' "${package_name}" "Git clone '${from}' -> '${output_path}' failed"
  #   fi
  #   return $res
  # fi

  if execlog "${sudo}git clone ${args} -- "${from}" "${output_path}""; then
    pac_log_success 'Git' "${package_name}" "Git '${output_path}' successful"
  else
    res=$?
    pac_log_failed $res 'Git' "${package_name}" "Git '${output_path}' failed!"
    return $res
  fi

  pac_post_install -o "${output_path}" -S ${as_root} "${package_name}" 'git'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  pac_log_success 'Git' "${package_name}" "Git clone '${from}' -> '${output_path}' successful"
  return $res
}


# DEPRECATED: For reference only
# NOTE: Always quiet output
function clone_repo() {
  local as_root=false
  local retry=${retry:-${GIT_AUTH_MAX_RETRY:-5}}
  local args=""
  local package_name=""
  local output_path=""

  OPTIND=1
  while getopts "fa:o:n:S:" opt; do
    case ${opt} in
      f)
        forced=true
        ;;
      a)
        args="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      o)
        output_path="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local from="${@}"
  local stderr=""
  local sudo=""
  local res=0

  $as_root && sudo="sudo "

  # NOTE: do not set stderr to `local` inline to prevent overwritting exit code from subshell
  info "Cloning '${from}' -> '${output_path}'"
  stderr="$(${sudo}git clone ${args} -- "${from}" "${output_path}" 2>&1 > /dev/null; exit $?)"; res=$?
  info "Execute: git clone ${args} -- ${from} ${output_path}"

  [[ $res -eq $BASH_EX_OK ]] || [[ -z "${stderr}" ]] && return $res

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ "${retry}" -ne $BASH_EX_OK ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      clone_repo -a "${args}" -n "${package_name}" -o "${output_path}" -S $as_root -- "${from}"
      res=$?
      return $res
    else
      error "Git authentication timeout!"
      return $BASH_SYS_EX_SOFTWARE
    fi
  else
    pac_log_failed $res 'Git' "${package_name}" "${stderr}"
  fi
  return $res
}


function is_git_installed() {
  if command -v git &> /dev/null; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_NOTFOUND
}


function is_git_remote_reachable() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local repo="${1:-}"
  local retry=${retry:-${GIT_AUTH_MAX_RETRY:-5}}

  if [[ -z "${repo}" ]] || [[ ! "${repo}" =~ ^git@|^https://|^git:// ]]; then
    return $BASH_SYS_EX_USAGE
  fi

  local stderr=""
  local res=0

  # NOTE: do not set stderr to `local` inline to prevent overwritting exit code from subshell
  stderr="$(git ls-remote -q "${repo}" 2>&1 > /dev/null)"; res=$?

  [[ $res -eq $BASH_EX_OK ]] || [[ -z "${stderr}" ]] && return $BASH_EX_OK

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ ${retry} -ne 0 ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      is_git_remote_reachable "${repo}"
      res=$?
      return $res
    else
      warning "Git authentication timeout!"
      return $BASH_SYS_EX_SOFTWARE
    fi
  else
    pac_log_failed $res 'Git' "${from}" "${stderr}"
    return $res
  fi

  return $res
}


function is_git_repo() {
  repo_dir="${1:-}"
  if [[ -d "${repo_dir}/.git" ]]; then
    return $BASH_EX_OK
  fi
  return $BASH_SYS_EX_CANTCREAT
}

