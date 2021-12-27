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


function pac_array_jsonify() {
  local pac_array_name=${1:?}
  eval "pac_array=( \"\${${pac_array_name}[@]}\" )"

  local i=
  for i in "${!pac_array[@]}"; do
    local package="${pac_array[$i]}"
    pac_jsonify package
    eval "${pac_array_name}[$i]='${package}'"
  done
}


function pac_jsonify() {
  local _global_pac_var_name="${1:?}"
  local _local_pac_var_name="${2:-${1}}"
  local _depth=${3:-1}

  local _indent="$(printf "%*s" $((${_depth}*4)))|-"
  local _root_package=${_package:-}
  eval "local _package=\${$_local_pac_var_name}"

  log 'DEBUG' "Inspecting: ${_package}"

  if ! [[ -f "${PACKAGE_DIR}/${_package}" ]]; then
    local _selected=
    if _select_package "${_package}" _selected "${_root_package}"; then
      # WARNING dangerous substitution! Replaces last occurrence (most recent addition) of _package
      local _replaced="$(eval "echo \"'\$${_global_pac_var_name}'\"" | sed "s/\(.*\)${_package}/\1${_selected}/")"
      eval "${_global_pac_var_name}=${_replaced}"
      _package=${_selected}
    else
      error "'${PACKAGE_DIR}/${_package}' not found!"
      return 1
    fi
  fi

  if [[ ${_depth} -eq 1 ]]; then
    # Quote root package
    eval "${_global_pac_var_name}='\"${_package}\"'"
    # Enclose root package
    eval "${_global_pac_var_name}={\$${_global_pac_var_name}"
  fi

  local -a _package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${PACKAGE_DIR}/${_package}") )

  # Handle dependencies recursively
  if [[ -n ${_package_dependencies+x} ]]; then

    if [[ ${#_package_dependencies[@]} -gt 1 ]]; then
      eval "${_global_pac_var_name}+=':[{'"
    else
      eval "${_global_pac_var_name}+=':{'"
    fi

    log 'DEBUG' "${_indent}Dependency detected for ${_package} (${#_package_dependencies[@]})"

    local dependency= i=
    for i in "${!_package_dependencies[@]}"; do
      dependency="${_package_dependencies[$i]}"
      [[ ${i} -eq 0 ]] || eval "${_global_pac_var_name}+=,"
      eval "${_global_pac_var_name}+='\"${dependency}\"'"

      log 'DEBUG' "${_indent}Dependency: ${dependency}"
      pac_jsonify ${_global_pac_var_name} dependency $((_depth+1))
      log 'DEBUG' "${_indent}Dependency (resolved): ${dependency}"
    done

    if [[ ${#_package_dependencies[@]} -gt 1 ]]; then
      eval "${_global_pac_var_name}+='}]'"
    else
      eval "${_global_pac_var_name}+='}'"
    fi

  else
    eval "${_global_pac_var_name}+=':{}'"
    log 'DEBUG' "${_indent}No dependency detected for ${_package}"
  fi

  # Enclose root package
  [[ ${_depth} -eq 1 ]] && eval "${_global_pac_var_name}+='}'"
}


# TODO: Search as executable name instead if package not found using grep
function _select_package() {
  local _package="${1%.*:?}"
  local _package_ext="$([[ "${1##*.}" != "${_package}" ]] && echo "${1##*.}")"
  local _selected_var=${2:?}
  local _excluded=${3:-}
  local _select=

  local _matches=(
    $(find "${PACKAGE_DIR}" -type f \
      ! -name "${_excluded}" \
      ! -name "${_package}*.pre" \
      ! -name "${_package}*.post" \
      ! -name "${_package}.${_package_ext}.*" \
      -name "${_package}*.*"
    )
  )
  if [[ -n "${_matches+x}" ]]; then
    if [[ "${#_matches[@]}" -eq 1 ]]; then
      _select="$(basename -- ${_matches[0]})"
      log 'DEBUG' "Defaulting: ${_select}"
    else
      printf "\nMultiple '${_package}' package detected\n\n"
      local i=
      while true; do
        for i in "${!_matches[@]}"; do
          printf "$(($i+1))) ${_matches[$i]}\n"
        done

        printf "\n"
        read -p "Please select from the matches (1-${#_matches[@]}): "
        printf "\n"
        if [[ "${REPLY}" =~ ^-?[0-9]+$  ]] && [[ "${REPLY}" -le "${#_matches[@]}" ]]; then
          _select="$(basename -- ${_matches[$(($REPLY-1))]})"
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


_has_alternate_package() {
  local _package="${1%.*:?}"
  local _package_ext="$([[ "${1##*.}" != "${_package}" ]] && echo "${1##*.}")"
  local _matches=(
    $(find "${PACKAGE_DIR}" -type f \
      ! -name "${_package}*.pre" \
      ! -name "${_package}*.post" \
      ! -name "${_package}.${_package_ext}.*" \
      -name "${_package}*.*")
  )
  [[ -n "${_matches+x}" ]] && return 0 || return 1
}


function validate_package() {
  local package=${1:?}
  local dependency_level=0

  ${VERBOSE} && printf "Packages\n"
  ${VERBOSE} && printf "│—${package}"
  _validate_dependencies "${PACKAGE_DIR}/${package}" $(($dependency_level+1))

  return $?
}

function _validate_dependencies() {
  if ! [[ -f "${1}" ]]; then
    if _has_alternate_package "$(basename -- ${1})"; then
      printf " ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}\n"
      return 0
    fi
    printf "\n"
    error "Package '${1}' not found"
    return 1
  fi
  printf "\n"

  local -a _package_dependencies=( $(${BASH_SOURCE%/*}/metadata-parser "dependency" "${1}") )
  local _dependency_level=${2}
  local _has_missing=false

  for dependency in "${_package_dependencies[@]}"; do
    if ${VERBOSE}; then
      printf "%*s" $((${_dependency_level}*4))
      printf "│—${dependency}"
    fi
    if [[ -f "${PACKAGE_DIR}/${dependency}" ]]; then
      ${VERBOSE} && printf "\n"
      _validate_dependencies "${PACKAGE_DIR}/${dependency}" $(($_dependency_level+1))
    else
      if _has_alternate_package ${dependency}; then
        ${VERBOSE} && printf " ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}\n"
      else
        ${VERBOSE} && printf " ${COLOR_RED}(MISSING)${COLOR_NC}\n"
        _has_missing=true
      fi
    fi
  done

  if ${_has_missing}; then
    return 1
  fi
}
