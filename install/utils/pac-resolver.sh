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

include "${BASH_SOURCE%/*}/../../common/stack.sh"
include "${BASH_SOURCE%/*}/../../common/colors.sh"
include "${BASH_SOURCE%/*}/../../common/log.sh"


function pac_array_resolve() {
  local pac_array_name=${1:?}
  eval "pac_array=( \"\${${pac_array_name}[@]}\" )"

  local i=
  for i in "${!pac_array[@]}"; do
    local package="${pac_array[$i]}"
    pac_resolve package
    eval "${pac_array_name}[$i]='${package}'"
  done
}


function pac_resolve() {
  local _global_pac_var_name="${1:?}"
  local _local_pac_var_name="${2:-${1}}"
  local depth=${3:-1}
  local indent="$(printf "%*s" $((${depth}*4)))|-"
  eval "local _package=\${$_local_pac_var_name}"

  log 'DEBUG' "Inspecting: ${_package}"

  if ! [[ -e "${PACKAGE_DIR}/${_package}" ]]; then
    local _selected=
    if _select_package "${_package%.*}" _selected; then
      # WARNING: Dangerous substitution!!
      eval "${_global_pac_var_name}=\${$_global_pac_var_name/${_package}/${_selected}}"
      _package=${_selected}
    else
      error "'${PACKAGE_DIR}/${_package}' not found!"
      return 1
    fi
  fi

  local -a _package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${PACKAGE_DIR}/${_package}") )

  if [[ -n ${_package_dependencies+x} ]]; then
    eval "${_global_pac_var_name}+=':{'"
    log 'DEBUG' "${indent}Dependency detected for ${_package} (${#_package_dependencies[@]})"

    local dependency= i=
    for i in "${!_package_dependencies[@]}"; do
      dependency="${_package_dependencies[$i]}"
      [[ ${i} -eq 0 ]] || eval "${_global_pac_var_name}+=,"
      eval "${_global_pac_var_name}+='${dependency}'"

      log 'DEBUG' "${indent}Dependency: ${dependency}"
      pac_resolve ${_global_pac_var_name} dependency $((depth+1))
      log 'DEBUG' "${indent}Dependency (resolved): ${dependency}"
    done

    eval "${_global_pac_var_name}+='}'"
  else
    log 'DEBUG' "${indent}No dependency detected for ${_package}"
  fi
}


function _select_package() {
  local _package="${1:?}"
  local _selected_var=${2:?}
  local _select=

  local matches=($(find "${PACKAGE_DIR}" -type f -name "${_package}.*"))
  if [[ -n "${matches+x}" ]]; then
    if [[ "${#matches[@]}" -eq 1 ]]; then
      _select="$(basename -- ${matches[0]})"
    else
      printf "\nMultiple '${_package}' package detected\n\n"
      local i=
      while true; do
        for i in "${!matches[@]}"; do
          printf "$(($i+1))) ${matches[$i]}\n"
        done

        printf "\n"
        read -p "Please select from the matches (1-${#matches[@]}): "
        printf "\n"
        if [[ "${REPLY}" =~ ^-?[0-9]+$  ]] && [[ "${REPLY}" -le "${#matches[@]}" ]]; then
          _select="$(basename -- ${matches[$(($REPLY-1))]})"
          break
        fi
      done
    fi
  fi

  if [[ -n "${_select}" ]]; then
    eval "${_selected_var}=${_select}"
    return 0
  else
    return 1
  fi
}


function validate_package() {
  local package=${1:?}
  local dependency_level=0

  # stack_new _dependencies

  ${VERBOSE} && printf "${package}\n"
  _validate_dependencies "${PACKAGE_DIR}/${package}" $(($dependency_level+1))

  # stack_destroy _dependencies

  return $?
}

function _validate_dependencies() {
  if ! [[ -e "${1}" ]]; then
    error "Package '${1}' not found"
    return 1
  fi

  local -a _package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${1}") )
  local _dependency_level=${2}
  local _has_missing=false

  for dependency in ${_package_dependencies}; do
    # stack_push _dependencies "${dependency}"
    if ${VERBOSE}; then
      printf "%*s" $((${_dependency_level}*4))
      printf "│—${dependency}"
    fi
    if [[ -e "${PACKAGE_DIR}/${dependency}" ]]; then
      ${VERBOSE} && printf "\n"
      _validate_dependencies "${PACKAGE_DIR}/${dependency}" $(($_dependency_level+1))
    else
      ${VERBOSE} && printf " ${COLOR_RED}(MISSING)${COLOR_NC}\n"
      _has_missing=true
    fi
  done

  if ${_has_missing}; then
    return 1
  fi
}
