#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${PACKAGE_PACKAGE_INSTALL_SH_INCLUDED+x}" ]] \
  && readonly PACKAGE_PACKAGE_INSTALL_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"
source "${EZ_INSTALL_HOME}/install/utils/progress-bar.sh"


# TODO: Append package install status onto progress bar
pac_batch_json_install() {
  local packages=("${@}")
  local width="${#packages[@]}"
  local jq='./lib/parser/jq'

  local res=0

  if [[ -n "${packages}" ]]; then
    local i=1
    local root_package=""
    local root_package_name=""
    local root_package_manager=""
    for package in ${packages[@]}; do
      root_package="$(echo "${package}" | ${jq} -crM ".package")"
      root_package_name="$(echo "${root_package}" | ${jq} -crM ".name")"
      pac_json_install "${root_package}"
      res=$?

      # Report root package failure
      if [[ ${res} -gt 0 ]]; then
        if [[ "${root_package_name##*.}" != "${root_package_name}" ]]; then
          root_package_manager="${root_package_name##*.}"
          capitalize root_package_manager
        else
          root_package_manager="N/A"
        fi
        pac_log_failed "${root_package_manager}" "${root_package_name}" "'${root_package_name}' installation failed"
      fi

      prog_bar "$(("${i}*100/${width}"))"
      echo "- ${root_package_name}"
      ((++i))
    done
  else
    error "Required packages array not found"
  fi
}


pac_json_install() {
  local package="${1}"
  local jq='./lib/parser/jq'

  if [[ "${package}" != "null" ]]; then

    local package_name="$(echo ${package} | ${jq} -crM ".name")"
    local package_dir="$(dirname -- "$(echo ${package} | ${jq} -crM ".path")")"
    local as_root=$(echo ${package} | ${jq} -crM ".as_root")

    local res=
    local sub_package=
    local dependencies=
    local dependencies_ct="$(echo ${package} | ${jq} -crM ".dependencies | length")"

    if [[ ${dependencies_ct} -gt 1 ]]; then
      # Recursive dependency install
      for ((i=0; i<${dependencies_ct}; ++i)); do
        dependencies="$(echo ${package} | ${jq} -crM ".dependencies[${i}]")"
        if [[ -n "${dependencies}" ]]; then
          sub_package="$(echo "${dependencies}" | ${jq} -crM ".package")"
          pac_json_install ${sub_package}
          res=$?
          [[ ${res} -gt 0 ]] && return ${res} # Abort immediately
        fi
      done
    else
      dependencies="$(echo ${package} | ${jq} -crM ".dependencies")"
      if [[ -n "${dependencies}" ]]; then
        sub_package="$(echo "${dependencies}" | ${jq} -crM ".package")"
        pac_json_install ${sub_package}
        res=$?
        [[ ${res} -gt 0 ]] && return ${res} # Abort immediately
      fi
    fi
    pac_install -S ${as_root} -- "${package_name}" "${package_dir}"
    res=$?
  fi
  return ${res}
}


pac_install() {
  local as_root=false
  local recursive=false
  OPTIND=1
  while getopts "rS:" opt; do
    case ${opt} in
      r)
        recursive=true
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package="${1:?}"
  local package_dir="${2:-}"
  local recursive="${3:-0}"

  if [[ -z "${package_dir}" ]]; then
    local res=0
    package_dir="${package}"
    fetch_package package_dir
    res=$?

    if [[ ${res} -gt 0 ]]; then
      local selected=
      if select_package "${package}" selected; then
        package_dir="$(dirname -- ${selected})"
      else
        pac_log_failed 'N/A' "${package}" "Package '${package}' not found"
        return 1
      fi
    fi
  fi

  if [[ ! -f "${package_dir}/${package}" ]]; then
    pac_log_failed 'N/A' "${package}" "Package '${package}' not found in ${package_dir}"
    return 1
  fi

  # Install dependencies
  if [[ ${recursive} -eq 1 ]]; then
    local dependency_tracker="${EZ_INSTALL_HOME}/install/utils/dependency-tracker"
    local dependencies="$(${dependency_tracker} -p "${package}" -d "${package_dir}")"

    for dependency in ${dependencies}; do
      info "Installing ${package} dependency -- ${dependency}"
      pac_install -r ${recursive} "${dependency}"
      local res=$?
      [[ ${res} -gt 0 ]] && return ${res}
    done
  fi

  info "Installing '${package}' from '${package_dir}'"
  source "${package_dir}/${package}" -S ${as_root}
  res=$?
  return ${res}
}


pac_batch_install() {
  local recursive=false
  OPTIND=1
  while getopts "r:" opt; do
    case ${opt} in
      r)
        recursive=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local packages=("${@}")
  local width="${#packages[@]}"

  if [[ -n "${packages}" ]]; then
    local i=1
    for package in ${packages[@]}; do
      pac_install -r ${recursive} "${package}"
      prog_bar "$(("${i}*100/${width}"))"
      echo "- ${package}"
      ((++i))
    done
  else
    error "Required packages array not found"
  fi
}


pac_deploy_init() {
  local target="${1:-}"
  local from="${EZ_INSTALL_HOME}/install/init.sh"

  if [[ -f "${target}" ]]; then
    warning "Replacing '${target}' with '${from}' symlink"
    execlog "rm ${target}"
  elif [[ -d "${target}" ]]; then
    error "Target '${target}' is a directory!"
    return 1
  elif [[ ! -d "$(dirname -- "${target}")" ]]; then
    execlog "mkdir -p '$(dirname -- "${target}")'"
  fi

  if execlog "ln -sT '${from}' '${target}'"; then
    ok "${from} -> ${target} symlink created"
  else
    error "${from} -> ${target} symlink failed"
  fi
}


pac_pre_install() {
  [[ -z "${1:-}" ]] && error "No package provided"

  local package="${1}"
  local package_manager="${2:-}"

  local res=0
  local package_pre_path=""

  # Pre process global
  package_pre_path="${package}.pre"
  fetch_package package_pre_path
  if [[ ${$?} -eq 0 ]]; then
    source "${package_pre_path}"
    res=$?
  fi

  if [[ ${res} -eq 0 ]] && [[ -n "${package_manager}" ]]; then
    to_lower package_manager
    # Pre process global
    package_pre_path="${package}.${package_manager}.pre"
    fetch_package package_pre_path
    if [[ ${$?} -eq 0 ]]; then
      source "${package_pre_path}"
      res=$?
    fi
  fi

  if [[ ${res} -gt 0 ]]; then
    capitalize package_manager
    pac_log_failed "${package_manager}" "${package}" "${package_manager} '${package}' pre installation failed"
  fi
  return ${res}
}


pac_post_install() {
  [[ -z "${1:-}" ]] && error "No package provided"

  local package="${1}"
  local package_manager="${2:-}"

  local res=0
  local package_post_path=""

  # Post process global
  package_post_path="${package}.post"
  fetch_package package_post_path
  if [[ ${$?} -eq 0 ]]; then
    source "${package_post_path}"
    res=$?
  fi

  if [[ ${res} -eq 0 ]] && [[ -n "${package_manager}" ]]; then
    to_lower package_manager
    # Post process global
    package_post_path="${package}.${package_manager}.post"
    fetch_package package_post_path
    if [[ ${$?} -eq 0 ]]; then
      source "${package_post_path}"
      res=$?
    fi
  fi

  if [[ ${res} -gt 0 ]]; then
    capitalize package_manager
    pac_log_failed "${package_manager}" "${package}" "${package_manager} '${package}' post installation failed"
  fi

  return ${res}
}
