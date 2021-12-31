#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_UTILS_INSTALL_GIT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_UTILS_INSTALL_GIT_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOE}/install/utils/pac-logger.sh"


git_clone() {
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

  local from="${@}"

  if ${as_root}; then
    if ! command -v sudo &> /dev/null; then
      pac_log_failed 'Git' "${package}" "Git '${package}' installation failed. 'sudo' not installed"
      return 3
    fi
  fi

  # Check if git is installed
  if ! is_git_installed; then
    pac_log_failed 'Git' "${package}" "Git '${package}' installation failed. git not installed"
    return 1
  fi

  local res=0

  # Validate git repo link
  is_git_remote_reachable "${from}"
  res=$?
  if [[ ${res} -eq 2 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Authentication timeout"
    return ${res}
  elif [[ ${res} -eq 1 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Invalid git remote url"
    return ${res}
  fi

  # Resolve destination
  local repo_name="$(basename -- "${from}" '.git')"
  [[ -z "${to}" ]] && to="./${repo_name}"

  # Check destination directory validity
  if [[ ! -d "$(dirname "${to}")" ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' -> '${to}' failed! Invalid destination path"
    return 1
  fi

  pac_pre_install "${package_name}" 'apt-add'
  res=$?; [[ ${res} -gt 0 ]] && return ${res}

  # Replace existing repo destination dir if force
  if [[ -d "${to}" ]]; then
    if ${is_force}; then
      if is_git_repo "${to}"; then
        warning "Replacing '${to}' Git repository"
        execlog "rm -rf '${to}'"
      fi
      pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! '${to}' already exist and is not a git repository"
      return 1
    else
      if is_git_repo "${to}"; then
        pac_log_skip "Git" "${from}"
        return 0
      fi
      pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! '${to}' already exist"
      return 1
    fi
  fi

  # Execute cloning
  clone_repo -a "${args}" -o "${to}" -S ${as_root} -- "${from}"
  res=$?
  if [[ ${res} -gt 0 ]]; then
    if [[ ${res} -eq 2 ]]; then
      pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Authentication timeout"
    elif [[ ${res} -eq 1 ]]; then
      pac_log_failed 'Git' "${from}" "Git clone '${from}' -> '${to}' failed"
    fi
    return ${res}
  fi

  pac_post_install "${package_name}" 'apt-add'
  res=$?
  if [[ ${res} -eq 0 ]]; then
    pac_log_success 'Git' "${from}" "Git clone '${from}' -> '${to}' successful"
  fi
  return ${res}
}


# Recursive
# returns 0 if ok,
# returns 1 if not found,
# returns 2 if authentication failed
clone_repo() {
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

  local from="${@}"
  local stderr=""
  local sudo=""
  local res=0

  ${as_root} && sudo="sudo "

  # NOTE: do not set stderr to `local` inline to prevent overwritting exit code from subshell
  info "Cloning '${from}' -> '${to}'"
  stderr="$(${sudo}git clone ${args} "${from}" "${to}" 2>&1 > /dev/null; exit $?)"; res=$?
  info "Execute: git clone ${args} ${from} ${to}"

  [[ ${res} -eq 0 ]] || [[ -z "${stderr}" ]] && return 0

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ "${retry}" -ne 0 ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      clone_repo -a "${args}" -o "${to}" -S ${as_root} -- "${from}"
      res=$?
      return ${res}
    else
      error "Git authentication timeout!"
      return 2
    fi
  else
    pac_log_failed 'Git' "${from}" "${stderr}"
    return ${res}
  fi

  return 1
}


is_git_installed() {
  if command -v git &> /dev/null; then
    return 0
  fi
  return 1
}


# Recursive
# returns 0 if ok,
# returns 1 if not found,
# returns 2 if authentication failed
is_git_remote_reachable() {
  local repo="${1:-}"
  local retry=${retry:-${GIT_AUTH_MAX_RETRY:-5}}

  [[ -z "${repo}" ]] || [[ ! "${repo}" =~ ^git@|^https://|^git:// ]] && return 1

  local stderr=""
  local res=0

  # NOTE: do not set stderr to `local` inline to prevent overwritting exit code from subshell
  stderr="$(git ls-remote -q "${repo}" 2>&1 > /dev/null)"; res=$?

  [[ ${res} -eq 0 ]] || [[ -z "${stderr}" ]] && return 0

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ ${retry} -ne 0 ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      is_git_remote_reachable "${repo}"
      res=$?
      return ${res}
    else
      warning "Git authentication timeout!"
      return 2
    fi
  else
    pac_log_failed 'Git' "${from}" "${stderr}"
    return ${res}
  fi

  return 1
}


is_git_repo() {
  repo_dir="${1:-}"
  [[ -d "${repo_dir}/.git" ]] && return 0 || return 1
}

