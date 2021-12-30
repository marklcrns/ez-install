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


source "${BASH_SOURCE%/*}/utils/pac-logger.sh"
source "${BASH_SOURCE%/*}/utils/progress-bar.sh"


pac_batch_json_install() {
  local packages=("${@}")
  local width="${#packages[@]}"
  local jq='./lib/parser/jq'

  if [[ -n "${packages}" ]]; then
    local i=1 root_package=
    for package in ${packages[@]}; do
      root_package="$(echo "${package}" | ${jq} -crM ".package")"
      pac_json_install_new "${root_package}"
      prog_bar "$(("${i}*100/${width}"))"
      echo "- $(echo "${root_package}" | ${jq} -crM ".name")"
      ((++i))
    done
  else
    error "Required packages array not found"
  fi
}


pac_json_install_new() {
  local package="${1}"
  local jq='./lib/parser/jq'

  if [[ "${package}" != "null" ]]; then

    local package_name="$(echo ${package} | ${jq} -crM ".name")"
    local package_dir="$(dirname -- "$(echo ${package} | ${jq} -crM ".path")")"

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
          pac_json_install_new ${sub_package}
          res=$?
          [[ ${res} -gt 0 ]] && return ${res} # Abort immediately
        fi
      done
    else
      dependencies="$(echo ${package} | ${jq} -crM ".dependencies")"
      if [[ -n "${dependencies}" ]]; then
        sub_package="$(echo "${dependencies}" | ${jq} -crM ".package")"
        pac_json_install_new ${sub_package}
        res=$?
        [[ ${res} -gt 0 ]] && return ${res} # Abort immediately
      fi
    fi
    pac_install "${package_name}" "${package_dir}"
    res=$?
  fi
  return ${res}
}

pac_json_install() {
  local package="${1:-}"

  local -a row=( $(echo "${package}" | ./lib/parser/jq) )

  local indices=( ${!row[@]} )
  for ((i=${#indices[@]} - 1; i >= 0; i--)) ; do
    if [[ ${row[indices[i]]} =~ \".* ]]; then
      local object=${row[indices[i]]}
      pac_install "${object//[\":]/}"
      local res=$?
      if [[ ${res} -gt 0 ]]; then
        local root="${row[indices[1]]//[\":]/}"
        local ext="$([[ "${root##*.}" != "${root}" ]] && echo "${root##*.}")"
        capitalize ext
        pac_log_failed "${ext}" "${root}" "Package '${root}' dependencies installation failed"
        return ${res}
      fi
    fi
  done
}


pac_install() {
  local recursive=false
  OPTIND=1
  while getopts "r" opt; do
    case ${opt} in
      r)
        recursive=true
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
    local _dependency_tracker="$(realpath -- ${BASH_SOURCE%/*})/utils/dependency-tracker"
    local _dependencies="$(${_dependency_tracker} -p "${package}" -d "${package_dir}")"

    for dependency in ${_dependencies}; do
      warning "Installing ${package} dependency -- ${dependency}"
      pac_install -r ${recursive} "${dependency}"
      local res=$?
      [[ ${res} -gt 0 ]] && return ${res}
    done
  fi

  warning "Installing '${package}' from '${package_dir}'"
  source "${package_dir}/${package}" -y
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


# Symlink init.sh
pac_deploy_init() {
  local target="${1:-}"
  local from="$(realpath -- ${BASH_SOURCE%/*}/init.sh)"

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
