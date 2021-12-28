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

pac_batch_json_install() {
  local packages=("${@}")
  local width="${#packages[@]}"

  if [[ -n "${packages}" ]]; then
    local _i=1
    for package in ${packages[@]}; do
      pac_json_install "${package}"
      prog_bar "$(("${_i}*100/${width}"))"
      echo "- ${package}"
      ((++_i))
    done
  else
    error "Required packages array not found"
  fi
}

pac_install() {
  local package="${1:-}"
  local recursive="${2:-0}"
  local package_dir="${PACKAGE_DIR:-${BASH_SOURCE%/*}/../generate/packages}"

  if [[ ! -e "${package_dir}/${package}" ]]; then
    pac_log_failed 'N/A' "${package}" "Package '${package}' not found in ${package_dir}"
    return 1
  fi

  # Install dependencies
  if [[ ${recursive} -eq 1 ]]; then
    local _dependency_tracker="$(realpath -- ${BASH_SOURCE%/*})/utils/dependency-tracker"
    local _dependencies="$(${_dependency_tracker} -p "${package}" -d "${package_dir}")"

    for dependency in ${_dependencies}; do
      warning "Installing ${package} dependency -- ${dependency}"
      pac_install "${dependency}" ${recursive}
      local res=$?
      if [[ ${res} -gt 0 ]]; then
        return ${res}
      fi
    done
  fi

  source "${package_dir}/${package}" -y
  res=$?
  if [[ ${res} -gt 0 ]]; then
    return $res
  fi
}

# pac_install() {
#   local package="${1:-}"
#   local package_dir="${PACKAGE_DIR:-${BASH_SOURCE%/*}/../generate/packages}"
# 
#   if [[ ! -e "${package_dir}/${package}" ]]; then
#     pac_log_failed 'N/A' "${package}" "Package '${package}' not found in ${package_dir}"
#     return 1
#   fi
# 
#   pac_install_dependencies "${package}" "${package_dir}"
#   local res=$?
#   if [[ ${res} -gt 0 ]]; then
#     pac_log_failed 'N/A' "${package_dir}/${package}" "Package '${package}' installation failed"
#     return ${res}
#   fi
# 
#   source "${package_dir}/${package}" -y
#   res=$?
#   if [[ ${res} -gt 0 ]]; then
#     pac_log_failed 'N/A' "${package_dir}/${package}" "Package '${package}' installation failed"
#     return $res
#   fi
# }
#
# pac_install_dependencies() {
#   local package="${1:-}"
#   local package_dir="${PACKAGE_DIR:-${BASH_SOURCE%/*}/../generate/packages}"
# 
#   local _dependency_tracker="$(realpath -- ${BASH_SOURCE%/*})/utils/dependency-tracker"
#   local _dependencies="$(${_dependency_tracker} -p "${package}" -d "${package_dir}")"
# 
#   for dependency in ${_dependencies}; do
#     warning "Installing ${package} dependency -- ${dependency}"
#     pac_install "${dependency}"
#     local res=$?
#     if [[ ${res} -gt 0 ]]; then
#       return ${res}
#     fi
#   done
# }

pac_batch_install() {
  local packages=("${@}")
  local width="${#packages[@]}"

  if [[ -n "${packages}" ]]; then
    local i=1
    for package in ${packages[@]}; do
      pac_install "${package}" 1
      prog_bar "$(("${i}*100/${width}"))"
      echo "- ${package}"
      ((++i))
    done
  else
    error "Required packages array not found"
  fi
}

# Symlink init.sh
# 
pac_deploy_init() {
  local target="${1:-}"
  local from="$(realpath -- ${BASH_SOURCE%/*}/init.sh)"

  if [[ -f "${target}" ]]; then
    warning "Replacing '${target}' with __init__.sh symlink"
    execlog "rm ${target}"
  elif [[ -d "${target}" ]]; then
    error "Target '${target}' is a directory!"
    return 1
  elif [[ ! -d "$(basename -- "${target}")" ]]; then
    execlog "mkdir -p ''$(basename -- "${target}")''"
  fi

  if execlog "ln -sT '${from}' '${target}'"; then
    ok "${from} -> ${target}/__init__.sh symlink created"
  else
    error "${from} -> ${target}/__init__.sh symlink failed"
  fi
}
