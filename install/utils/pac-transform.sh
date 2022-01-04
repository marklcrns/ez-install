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

[[ -z "${DEBUG+x}" ]] && DEBUG=false

source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/log.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"


function pac_array_jsonify() {
  local recursive=true
  local as_root=false

  OPTIND=1
  while getopts "R:S:" opt; do
    case ${opt} in
      R)
        recursive=${OPTARG}
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local pac_array_name=${1}
  eval "pac_array=( \"\${${pac_array_name}[@]}\" )"

  local res=0

  local i=
  local package=
  for i in "${!pac_array[@]}"; do
    package="${pac_array[$i]}"
    pac_jsonify -R $recursive -S $as_root -- package
    res=$?

    if [[ $res -ne $BASH_EX_OK ]]; then
      eval "${pac_array_name}[$i]='{\"package\":{\"name\":\"${pac_array[$i]}\",\"path\":null}}'"
    else
      eval "${pac_array_name}[$i]='${package}'"
    fi
  done

  return $res
}


function pac_jsonify() {
  local recursive=true
  local as_root=false

  OPTIND=1
  while getopts "R:S:" opt; do
    case ${opt} in
      R)
        recursive=${OPTARG}
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local global_pac_var_name="${1}"
  local local_pac_var_name="${2:-${1}}"
  local root_package=${3:-}
  local depth=${4:-1}
  local indent="${indent:-}|  "

  eval "local _package=\${$local_pac_var_name}"

  parse_inline_opts "${_package}"
  _package="${_package%#*}" # Strip #opts

  info "Fetching: ${_package}"

  local package_path="${_package}"
  local res=0
  fetch_package package_path
  res=$?

  if [[ $res -ne $BASH_EX_OK ]]; then
    local selected=""
    if select_package "${_package}" selected "${root_package}"; then
      # WARNING dangerous substitution! Replaces last occurrence (most recent addition only) of $_package
      local _replaced="$(eval "echo \"'\$${global_pac_var_name}'\"" | sed "s/\(.*\)${_package}/\1$(basename -- ${selected})/")"
      eval "${global_pac_var_name}=${_replaced}"
      _package="$(basename -- ${selected})"
      package_path="${selected}"
    else
      error "No such '${_package}' package found!"
      return $BASH_EZ_EX_PAC_NOTFOUND
    fi
  fi

  [[ ${depth} -eq 1 ]] && eval "${global_pac_var_name}='{'"
  eval "${global_pac_var_name}+='\"package\":{'"
  eval "${global_pac_var_name}+='\"name\":\"${_package}\",'"
  eval "${global_pac_var_name}+='\"path\":\"${package_path}\",'"
  eval "${global_pac_var_name}+='\"as_root\":$as_root'"

  if $recursive; then
    local tmp="$(${EZ_INSTALL_HOME}/install/utils/metadata-parser "dependency" "${package_path}")"
    local -a package_dependencies=( ${tmp//,/ } )

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
        [[ $i -gt 0 ]] && eval "${global_pac_var_name}+=,"

        info "${indent}Dependency: ${dependency}"
        eval "${global_pac_var_name}+='{'"

        pac_jsonify -R $recursive -S $as_root -- "${global_pac_var_name}" dependency ${_package} $((depth+1))
        res=$?; [[ $res -ne $BASH_EX_OK ]] && return $res

        eval "${global_pac_var_name}+='}'"
        info "${indent}Dependency (resolved): ${dependency}"
      done
      [[ ${#package_dependencies[@]} -gt 1 ]] && eval "${global_pac_var_name}+=']'"
    else
      info "${indent}No dependency detected for ${_package}"
    fi
  fi

  [[ ${depth} -eq 1 ]] && eval "${global_pac_var_name}+='}'"
  eval "${global_pac_var_name}+='}'"
}


function validate_packages() {
  local recursive=true
  local as_root=false

  OPTIND=1
  while getopts "R:S:" opt; do
    case ${opt} in
      R)
        recursive=${OPTARG}
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local packages=( "${@}" )

  # Only continue with at least one valid package
  local continue=false
  local res=0
  for package in ${packages[@]}; do
    validate_package -R $RECURSIVE -S $AS_ROOT -- "${package}"
    res=$?
    if ! ${continue} && [[ ${res} -eq $BASH_EX_OK ]]; then
      continue=true
    fi
  done
  ! ${continue} && return ${res} || return $BASH_EX_OK
}


function validate_package() {
  local recursive=true
  local as_root=false

  OPTIND=1
  while getopts "R:S:" opt; do
    case ${opt} in
      R)
        recursive=${OPTARG}
        ;;
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  parse_inline_opts "${1}"
  local package="${1%#*}"   # Strip #opts

  info "Validating packages..."
  ! $DEBUG && printf "${package}"
  $as_root && ! $DEBUG && printf " ${COLOR_BLUE}(ROOT)${COLOR_NC} "

  if $recursive; then
    _validate_dependencies "${package}" $as_root
    return $?
  fi

  ! $DEBUG && printf "\n"
  return $BASH_EX_OK
}


function _validate_dependencies() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _package="${1}"
  local _as_root=${2:-false}
  local _package_path="${_package}"
  local _indent="${_indent:-}│  "

  local res=
  fetch_package _package_path
  res=$?

  if [[ $res -ne $BASH_EX_OK ]]; then
    if has_alternate_package "${_package}"; then
      ! $DEBUG && printf " ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}\n"
      return $BASH_EX_OK
    fi
    ! $DEBUG && printf " ${COLOR_RED}(MISSING)${COLOR_NC}\n"
    return $BASH_EZ_EX_PAC_NOTFOUND
  else
    ! $DEBUG && printf "\n"
  fi

  local _tmp="$(${EZ_INSTALL_HOME}/install/utils/metadata-parser "dependency" "${_package_path}")"
  local -a _package_dependencies=( ${_tmp//,/ } )
  local _has_missing=false

  for dependency in "${_package_dependencies[@]}"; do
    ! $DEBUG && printf "${_indent}└─${dependency}"
    $_as_root && ! $DEBUG && printf " ${COLOR_BLUE}(ROOT)${COLOR_NC} "

    if has_package "${dependency}"; then
      _validate_dependencies "${dependency}" $_as_root
    else
      if has_alternate_package ${dependency}; then
        ! $DEBUG && printf " ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}\n"
      else
        ! $DEBUG && printf " ${COLOR_RED}(MISSING)${COLOR_NC}\n"
        _has_missing=true
      fi
    fi
  done

  if ${_has_missing}; then
    return $BASH_EZ_EX_PAC_NOTFOUND
  fi
}
