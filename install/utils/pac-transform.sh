#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${UTILS_PAC_TRANSFORM_SH_INCLUDED+x}" ]] \
  && readonly UTILS_PAC_TRANSFORM_SH_INCLUDED=1 \
  || return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/log.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"


function pac_array_jsonify() {
  local config=""

  OPTIND=1
  while getopts "fFrRsSwW" opt; do
    case ${opt} in
      f|F|r|R|s|S|w|W) config="${config} -${opt}" ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
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
    pac_jsonify ${config} -- package
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
  local force= recursive= as_root= allow_dep_fail=
  local config=""

  OPTIND=1
  while getopts "fFrRsSwW" opt; do
    case ${opt} in
      f) force=true;           config="${config} -${opt}" ;;
      F) force=false;          config="${config} -${opt}" ;;
      r) recursive=true;       config="${config} -${opt}" ;;
      R) recursive=false;      config="${config} -${opt}" ;;
      s) as_root=true;         config="${config} -${opt}" ;;
      S) as_root=false;        config="${config} -${opt}" ;;
      w) allow_dep_fail=true;  config="${config} -${opt}" ;;
      W) allow_dep_fail=false; config="${config} -${opt}" ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
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

  # In-line opts config
  parse_inline_opts "${_package}"

  _package="${_package%#*}" # Strip #opts

  local res=0
  local package_path="${_package}"
  fetch_package package_path
  res=$?

  # Package default config
  [[ -z "${as_root}" ]]   && as_root="$(${EZ_INSTALL_METADATA_PARSER} "as-root" "${package_path}")"

  # Global default config
  [[ -z "${force}" ]]          && force=$FORCE
  [[ -z "${recursive}" ]]      && recursive=$RECURSIVE
  [[ -z "${as_root}" ]]        && as_root=$AS_ROOT
  [[ -z "${allow_dep_fail}" ]] && allow_dep_fail=$ALLOW_DEP_FAIL

  info "Fetching: ${_package}"

  if [[ $res -ne $BASH_EX_OK ]]; then
    local selected=""
    if select_package "${_package}" selected "${root_package}"; then
      if [[ -z "${selected}" ]]; then
        warning "Package '${_package}' skipped!"

        [[ ${depth} -eq 1 ]] && eval "${global_pac_var_name}='{'"
        eval "${global_pac_var_name}+='\"package\":{'"
        eval "${global_pac_var_name}+='\"name\":\"${_package}\",'"
        eval "${global_pac_var_name}+='\"path\":null'"
        [[ ${depth} -eq 1 ]] && eval "${global_pac_var_name}+='}'"
        eval "${global_pac_var_name}+='}'"

        return $BASH_EX_OK
      fi
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
  eval "${global_pac_var_name}+='\"as_root\":$as_root,'"
  eval "${global_pac_var_name}+='\"force\":$force,'"
  eval "${global_pac_var_name}+='\"allow_dep_fail\":$allow_dep_fail'"

  if $recursive; then
    local tmp="$(${EZ_INSTALL_METADATA_PARSER} "dependency" "${package_path}")"
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

        pac_jsonify ${config} -- "${global_pac_var_name}" dependency "${_package}" $((depth+1))
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

