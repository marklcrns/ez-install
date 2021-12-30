#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${UTILS_PAC_RESOLVER_SH_INCLUDED+x}" ]] \
  && readonly UTILS_PAC_RESOLVER_SH_INCLUDED=1 \
  || return 0

source "${BASH_SOURCE%/*}/../../common/include.sh"

include "${BASH_SOURCE%/*}/../../common/colors.sh"
include "${BASH_SOURCE%/*}/../../common/log.sh"
include "${BASH_SOURCE%/*}/../common.sh"


function pac_array_jsonify() {
  local pac_array_name=${1:?}
  eval "pac_array=( \"\${${pac_array_name}[@]}\" )"

  local i= res=
  for i in "${!pac_array[@]}"; do
    local package="${pac_array[$i]}"
    pac_jsonify package
    res=$?
    if [[ ${res} -gt 0 ]]; then
      eval "${pac_array_name}[$i]='\"${pac_array[$i]}\":\"\"'"
    else
      eval "${pac_array_name}[$i]='${package}'"
    fi
  done
}


function pac_jsonify() {
  local _global_pac_var_name="${1:?}"
  local _local_pac_var_name="${2:-${1}}"
  local _depth=${3:-1}
  local _indent="${_indent:-}|  "

  local _root_package=${_package:-}
  eval "local _package=\${$_local_pac_var_name}"

  info "Fetching: ${_package}"

  local _package_path="${_package}"
  fetch_package _package_path
  local res=$?

  if [[ ${res} -gt 0 ]]; then
    local _selected=
    if select_package "${_package}" _selected "${_root_package}"; then
      # WARNING dangerous substitution! Replaces last occurrence (most recent addition only) of $_package
      local _replaced="$(eval "echo \"'\$${_global_pac_var_name}'\"" | sed "s/\(.*\)${_package}/\1$(basename -- ${_selected})/")"
      eval "${_global_pac_var_name}=${_replaced}"
      _package="$(basename -- ${_selected})"
      _package_path="${_selected}"
    else
      error "'${_package}' not found!"
      return 1
    fi
  fi

  if [[ ${_depth} -eq 1 ]]; then
    eval "${_global_pac_var_name}='{'"
  fi

  eval "${_global_pac_var_name}+='\"package\":{'"
  eval "${_global_pac_var_name}+='\"name\":\"${_package}\",'"
  eval "${_global_pac_var_name}+='\"path\":\"${_package_path}\"'"

  local -a _package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${_package_path}") )

  # Handle dependencies recursively
  if [[ -n ${_package_dependencies+x} ]]; then

    if [[ ${#_package_dependencies[@]} -gt 1 ]]; then
      eval "${_global_pac_var_name}+=',\"dependencies\":['"
    else
      eval "${_global_pac_var_name}+=',\"dependencies\":'"
    fi

    info "${_indent}Dependency detected for ${_package} (${#_package_dependencies[@]})"

    local dependency= i= res=
    for i in "${!_package_dependencies[@]}"; do
      dependency="${_package_dependencies[$i]}"
      [[ ${i} -eq 0 ]] || eval "${_global_pac_var_name}+=,"

      info "${_indent}Dependency: ${dependency}"
      eval "${_global_pac_var_name}+='{'"
      pac_jsonify "${_global_pac_var_name}" dependency $((_depth+1))
      eval "${_global_pac_var_name}+='}'"

      res=$?
      [[ ${res} -gt 0 ]] && return ${res}
      info "${_indent}Dependency (resolved): ${dependency}"
    done

    if [[ ${#_package_dependencies[@]} -gt 1 ]]; then
      eval "${_global_pac_var_name}+=']'"
    fi

  else
    info "${_indent}No dependency detected for ${_package}"
  fi

  eval "${_global_pac_var_name}+='}'"

  if [[ ${_depth} -eq 1 ]]; then
    eval "${_global_pac_var_name}+='}'"
  fi
}


function validate_package() {
  local package="${1:?}"

  ! ${DEBUG} && printf "${package}"
  _validate_dependencies "${package}"

  return $?
}

function _validate_dependencies() {
  local _package="${1:?}"
  local _package_path="${_package}"
  local _indent="${_indent:-}│  "
  local res=

  fetch_package _package_path
  res=$?

  if [[ ${res} -gt 0 ]]; then
    if has_alternate_package "${_package}"; then
      ! ${DEBUG} && printf " ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}\n"
      return 0
    fi
    ! ${DEBUG} && printf " ${COLOR_RED}(MISSING)${COLOR_NC}\n"
    return 1
  else
    ! ${DEBUG} && printf "\n"
  fi

  local -a _package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${_package_path}") )
  local _has_missing=false

  for dependency in "${_package_dependencies[@]}"; do
    ! ${DEBUG} && printf "${_indent}└─${dependency}"
    if has_package "${dependency}"; then
      _validate_dependencies "${dependency}"
    else
      if has_alternate_package ${dependency}; then
        ! ${DEBUG} && printf " ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}\n"
      else
        ! ${DEBUG} && printf " ${COLOR_RED}(MISSING)${COLOR_NC}\n"
        _has_missing=true
      fi
    fi
  done

  if ${_has_missing}; then
    return 1
  fi
}
