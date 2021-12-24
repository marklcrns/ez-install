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


function pac_array_resolve() {
  local pac_array_name=${1:?}
  eval "pac_array=( \"\${${pac_array_name}[@]}\"  )"

  local i=
  for i in "${!pac_array[@]}"; do
    local package="${pac_array[$i]}"
    pac_resolve package
    eval "${pac_array_name}[$i]='${package}'"
  done
}


function pac_resolve() {
  local pac_var_name=${1:?}
  eval "local _package=\${$pac_var_name}"

  if [[ -e "${PACKAGE_DIR}/${_package}" ]]; then
    return 0
  else
    local _selected=
    if _select_package "${_package%.*}" _selected; then
      eval "${pac_var_name}=${_selected}"
      return 0
    fi
  fi
  error "'${PACKAGE_DIR}/${_package}' not found!"
  return 1
}


function _select_package() {
  local _package="${1:?}"
  local _selected_var=${2:?}
  local _select=

  local matches=($(find "${PACKAGE_DIR}" -type f -name "${_package}*"))
  if [[ -n "${matches+x}" ]]; then
    if [[ "${#matches[@]}" -eq 1 ]]; then
      _select="$(basename -- ${matches[0]})"
    else
      echo ""
      local i=
      while true; do
        for i in "${!matches[@]}"; do
          echo "$(($i+1))) ${matches[$i]}"
        done

        echo ""
        read -p "Please select from the matches (1-${#matches[@]}): "
        echo ""
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

  stack_new _dependencies

  ${VERBOSE} && printf "${package}\n"
  _validate_dependencies "${PACKAGE_DIR}/${package}" $(($dependency_level+1))

  stack_destroy _dependencies

  return $?
}

function _validate_dependencies() {
  if ! [[ -e "${1}" ]]; then
    error "Package '${1}' not found"
    return 1
  fi

  local -a _package_dependencies=("$(${BASH_SOURCE%/*}/metadata-parser dependency "${1}")")
  local _dependency_level=${2}
  local _has_missing=false

  for dependency in ${_package_dependencies}; do
    stack_push _dependencies "${dependency}"
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
