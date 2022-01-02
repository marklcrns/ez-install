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
  local as_root=false
  local is_force=false
  local args='--'
  local to=""
  local command_name=""
  local package_name=""

  OPTIND=1
  while getopts "fa:o:n:S:" opt; do
    case ${opt} in
      f)
        is_force=true
        ;;
      a)
        args="${OPTARG} --"
        ;;
      o)
        to="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
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

  if $as_root; then
    if ! command -v sudo &> /dev/null; then
      pac_log_failed 'Git' "${package}" "Git '${package}' installation failed. 'sudo' not installed"
      return $BASH_EX_MISUSE
    fi
  fi

  local res=0

  is_git_installed
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    pac_log_failed 'Git' "${package}" "Git '${package}' installation failed. git not installed"
    return $res
  fi

  # Validate git repo link
  is_git_remote_reachable "${from}"
  res=$?
  if [[ $res -eq 2 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Authentication timeout"
    return $res
  elif [[ $res -eq 1 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Invalid git remote url"
    return $res
  fi

  # Resolve destination
  local repo_name="$(basename -- "${from}" '.git')"
  [[ -z "${to}" ]] && to="./${repo_name}"

  # Check destination directory validity
  if [[ ! -d "$(dirname "${to}")" ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' -> '${to}' failed! Invalid destination path"
    return $BASH_SYS_EX_CANTCREAT
  fi

  pac_pre_install "${package_name}" 'apt-add'
  res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

  # Replace existing repo destination dir if force
  if [[ -d "${to}" ]]; then
    if ${is_force}; then
      is_git_repo "${to}"
      res=$?
      if [[ $res -ne $BASH_EX_OK ]] ; then
        pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! '${to}' already exist and is not a git repository"
        return $res
      fi
      warning "Replacing '${to}' Git repository"
      execlog "rm -rf '${to}'"
    else
      is_git_repo "${to}"
      res=$?
      if [[ $res -ne $BASH_EX_OK ]] ; then
        pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! '${to}' already exist"
        return $res
      fi
      pac_log_skip "Git" "${from}"
      return $res
    fi
  fi

  # Execute cloning
  clone_repo -a "${args}" -o "${to}" -S $as_root -- "${from}"
  res=$?
  if [[ $res -ne $BASH_EX_OK ]]; then
    if [[ $res -eq $BASH_SYS_EX_SOFTWARE ]]; then
      pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Authentication timeout"
    else
      pac_log_failed 'Git' "${from}" "Git clone '${from}' -> '${to}' failed"
    fi
    return $res
  fi

  pac_post_install "${package_name}" 'apt-add'
  res=$?
  if [[ $res -eq $BASH_EX_OK ]]; then
    pac_log_success 'Git' "${from}" "Git clone '${from}' -> '${to}' successful"
  fi
  return $res
}


function clone_repo() {
  local as_root=false
  local retry=${retry:-${GIT_AUTH_MAX_RETRY:-5}}
  local args=""
  local to=""

  OPTIND=1
  while getopts "fa:o:n:S:" opt; do
    case ${opt} in
      f)
        is_force=true
        ;;
      a)
        args="${OPTARG}"
        ;;
      o)
        to="${OPTARG}"
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
  info "Cloning '${from}' -> '${to}'"
  stderr="$(${sudo}git clone ${args} "${from}" "${to}" 2>&1 > /dev/null; exit $?)"; res=$?
  info "Execute: git clone ${args} ${from} ${to}"

  [[ $res -eq $BASH_EX_OK ]] || [[ -z "${stderr}" ]] && return $res

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ "${retry}" -ne $BASH_EX_OK ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      clone_repo -a "${args}" -o "${to}" -S $as_root -- "${from}"
      res=$?
      return $res
    else
      error "Git authentication timeout!"
      return $BASH_SYS_EX_SOFTWARE
    fi
  else
    pac_log_failed 'Git' "${from}" "${stderr}"
    return $res
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
    pac_log_failed 'Git' "${from}" "${stderr}"
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

