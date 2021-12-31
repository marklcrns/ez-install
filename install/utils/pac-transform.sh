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
  local as_root=false

  OPTIND=1
  while getopts "S:" opt; do
    case ${opt} in
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local pac_array_name=${1:?}
  eval "pac_array=( \"\${${pac_array_name}[@]}\" )"

  local res=0

  local i=
  for i in "${!pac_array[@]}"; do
    local package="${pac_array[$i]}"
    pac_jsonify -S ${as_root} -- package
    res=$?

    if [[ ${res} -gt 0 ]]; then
      eval "${pac_array_name}[$i]='\"${pac_array[$i]}\":\"\"'"
    else
      eval "${pac_array_name}[$i]='${package}'"
    fi
  done

  return ${res}
}


function pac_jsonify() {
  local as_root=false

  OPTIND=1
  while getopts "S:" opt; do
    case ${opt} in
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local global_pac_var_name="${1:?}"
  local local_pac_var_name="${2:-${1}}"
  local depth=${3:-1}
  local indent="${indent:-}|  "

  local root_package=${_package:-}
  eval "local _package=\${$local_pac_var_name}"

  info "Fetching: ${_package}"

  local package_path="${_package}"
  local res=0
  fetch_package package_path
  res=$?

  if [[ ${res} -gt 0 ]]; then
    local selected=""
    if select_package "${_package}" selected "${root_package}"; then
      # WARNING dangerous substitution! Replaces last occurrence (most recent addition only) of $_package
      local _replaced="$(eval "echo \"'\$${global_pac_var_name}'\"" | sed "s/\(.*\)${_package}/\1$(basename -- ${selected})/")"
      eval "${global_pac_var_name}=${_replaced}"
      _package="$(basename -- ${selected})"
      package_path="${selected}"
    else
      error "'${_package}' not found!"
      return 1
    fi
  fi

  [[ ${depth} -eq 1 ]] && eval "${global_pac_var_name}='{'"
  eval "${global_pac_var_name}+='\"package\":{'"
  eval "${global_pac_var_name}+='\"name\":\"${_package}\",'"
  eval "${global_pac_var_name}+='\"path\":\"${package_path}\",'"
  eval "${global_pac_var_name}+='\"as_root\":${as_root}'"

  local -a package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${package_path}") )

  # Handle dependencies recursively
  if [[ -n ${package_dependencies+x} ]]; then
    info "${indent}Dependency detected for ${_package} (${#package_dependencies[@]})"

    if [[ ${#package_dependencies[@]} -gt 1 ]]; then
      eval "${global_pac_var_name}+=',\"dependencies\":['"
    else
      eval "${global_pac_var_name}+=',\"dependencies\":'"
    fi

    local dependency=""
    local res=0

    local i=
    for i in "${!package_dependencies[@]}"; do
      dependency="${package_dependencies[$i]}"
      [[ ${i} -gt 0 ]] && eval "${global_pac_var_name}+=,"

      info "${indent}Dependency: ${dependency}"
      eval "${global_pac_var_name}+='{'"

      pac_jsonify -S ${as_root} -- "${global_pac_var_name}" dependency $((depth+1))
      res=$?; [[ ${res} -gt 0 ]] && return ${res}

      eval "${global_pac_var_name}+='}'"
      info "${indent}Dependency (resolved): ${dependency}"
    done
    [[ ${#package_dependencies[@]} -gt 1 ]] && eval "${global_pac_var_name}+=']'"
  else
    info "${indent}No dependency detected for ${_package}"
  fi

  [[ ${depth} -eq 1 ]] && eval "${global_pac_var_name}+='}'"
  eval "${global_pac_var_name}+='}'"
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
