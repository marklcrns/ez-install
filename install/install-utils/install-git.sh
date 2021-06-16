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


source "${BASH_SOURCE%/*}/../utils/pac-logger.sh"


_is_git_installed() {
  if eval "command -v git &> /dev/null"; then
    return 0
  fi
  return 1
}

# Recursive
# returns 0 if ok,
# returns 1 if not found,
# returns 2 if authentication failed
_is_git_remote_reachable() {
  local repo="${1:-}"
  local retry=${retry:-${GIT_AUTH_MAX_RETRY:-5}}

  [[ -z "${repo}" ]] || [[ ! "${repo}" =~ ^git@|^https://|^git:// ]] && return 1

  local stderr="$(git ls-remote -q "${repo}" 2>&1 > /dev/null)"
  [[ "${?}" -eq 0 ]] || [[ -z "${stderr}" ]] && return 0

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ "${retry}" -ne 0 ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      _is_git_remote_reachable "${repo}"
      return ${?} # Propagate exit code
    else
      warning "Git authentication timeout!"
      return 2
    fi
  fi

  return 1
}

_replace_old_repo() {
  repo_dir="${1:-}"
  # Remove old repository if existing
  if [[ -d "${repo_dir}/.git" ]]; then
    warning "Replacing '${repo_dir}' Git repository"
    execlog "rm -rf '${repo_dir}'"
    return 0
  fi
  return 1
}

# Recursive
# returns 0 if ok,
# returns 1 if not found,
# returns 2 if authentication failed
_clone_repo() {
  local repo="${1}"
  local to="${2:-}"
  local retry=${retry:-${GIT_AUTH_MAX_RETRY:-5}}

  local stderr="$(git clone "${repo}" "${to}" 2>&1 > /dev/null)"
  log 'debug' "Execute: git clone '${repo}' '${to}'"
  [[ "${?}" -eq 0 ]] || [[ -z "${stderr}" ]] && return 0

  if [[ "${stderr}" =~ 'Authentication failed' ]]; then
    if [[ "${retry}" -ne 0 ]]; then
      warning "Git authentication failed. Try again (${retry} remaining)\n"
      ((--retry))
      _clone_repo "${repo}" "${to}"
      return ${?} # Propagate exit code
    else
      warning "Git authentication timeout!"
      return 2
    fi
  fi

  return 1
}

git_clone() {
  local is_force=false
  OPTIND=1

  while getopts "f" opt; do
    case ${opt} in
      f)
        is_force=true
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local from="${1}"
  local to="${2:-}"
  local exit_code

  # Check if git is installed
  if ! _is_git_installed; then
    pac_log_failed 'Git' "${package}" "Git '${package}' installation failed. git not installed"
    return 1
  fi

  # Validate git repo link
  _is_git_remote_reachable "${from}"
  exit_code="${?}"
  if [[ "${exit_code}" -eq 2 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Authentication timeout"
    return 1
  elif [[ "${exit_code}" -eq 1 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Invalid git remote url"
    return 1
  fi

  # Resolve destination
  local repo_name="$(basename -- "${from}" '.git')"
  [[ -z "${to}" ]] && to="${to}/${repo_name}"

  # Check destination directory validity
  if [[ ! -d "$(dirname "${to}")" ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' -> '${to}' failed! Invalid destination path"
    return 1
  fi

  # Remove destination dir if force and is a repo, else return 1
  if [[ -d "${to}" ]]; then
    if ! ${is_force} || ! _replace_old_repo "${to}"; then
      pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! '${to}' already exist"
      return 1
    fi
  fi

  # Execute cloning
  _clone_repo "${from}" "${to}"
  exit_code="${?}"
  if [[ "${exit_code}" -eq 2 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' failed! Authentication timeout"
    return 1
  elif [[ "${exit_code}" -eq 1 ]]; then
    pac_log_failed 'Git' "${from}" "Git clone '${from}' -> '${to}' failed"
    return 1
  fi

  pac_log_success 'Git' "${from}" "Git clone '${from}' -> '${to}' successful"
  return 0
}
