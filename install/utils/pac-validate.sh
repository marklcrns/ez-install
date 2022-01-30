#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${UTILS_PAC_VALIDATE_SH_INCLUDED+x}" ]] \
  && readonly UTILS_PAC_VALIDATE_SH_INCLUDED=1 \
  || return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/log.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"


function validate_packages() {
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

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local packages=( "${@}" )

  # Only continue with at least one valid package
  local continue=false
  local res=0
  for package in ${packages[@]}; do
    validate_package ${config} -- "${package}"
    res=$?
    if ! ${continue} && [[ ${res} -eq $BASH_EX_OK ]]; then
      continue=true
    fi
  done
  ! ${continue} && return ${res} || return $BASH_EX_OK
}


function validate_package() {
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

  # In-line opts config
  parse_inline_opts "${1}"

  local package="${1%#*}"   # Strip #opts

  local res=0
  local package_path="${package}"
  fetch_package package_path
  res=$?

  # Package default config
  [[ -z "${as_root}" ]]   && as_root="$(${EZ_INSTALL_METADATA_PARSER} "as-root" "${package_path}")"

  # Global default config
  [[ -z "${force}" ]]          && force=$FORCE
  [[ -z "${recursive}" ]]      && recursive=$RECURSIVE
  [[ -z "${as_root}" ]]        && as_root=$AS_ROOT
  [[ -z "${allow_dep_fail}" ]] && allow_dep_fail=$ALLOW_DEP_FAIL

  info "Validating packages..."

  if $recursive; then
    _validate_dependencies ${config} -- "${package}"
    return $?
  else
    if [[ $res -ne $BASH_EX_OK ]]; then
      if has_alternate_package "${package}"; then
        ! $DEBUG && printf "${package} ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}"
      else
        res=$?
        if [[ $res -eq $BASH_EZ_EX_PAC_GENERATED ]]; then
          ! $DEBUG && printf "${package} ${COLOR_BLUE}(GENERATE)${COLOR_NC}"
        else
          ! $DEBUG && printf "${package} ${COLOR_RED}(MISSING)${COLOR_NC}\n"
          return $BASH_EZ_EX_PAC_NOTFOUND
        fi
      fi
    else
      ! $DEBUG && printf "${package}"
    fi
    ! $DEBUG && $force          && printf " ${COLOR_GREEN}(FORCE)${COLOR_NC}"
    ! $DEBUG && $as_root        && printf " ${COLOR_GREEN}(ROOT)${COLOR_NC}"
    ! $DEBUG && $recursive      && printf " ${COLOR_GREEN}(RECUR)${COLOR_NC}"
    ! $DEBUG && $allow_dep_fail && printf " ${COLOR_GREEN}(DEPFAILOK)${COLOR_NC}"
  fi

  ! $DEBUG && printf "\n"
  return $BASH_EX_OK
}


function _validate_dependencies() {
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

  local _package="${1}"
  local _indent="${2:-}"

  local _package_path="${_package}"
  local _res=0
  fetch_package _package_path
  _res=$?

  # Package default configs
  [[ -z "${as_root}" ]]   && as_root="$(${EZ_INSTALL_METADATA_PARSER} "as-root" "${_package_path}")"

  # Global default configs
  [[ -z "${force}" ]]          && force=$FORCE
  [[ -z "${recursive}" ]]      && recursive=$RECURSIVE
  [[ -z "${as_root}" ]]        && as_root=$AS_ROOT
  [[ -z "${allow_dep_fail}" ]] && allow_dep_fail=$ALLOW_DEP_FAIL

  if [[ $_res -ne $BASH_EX_OK ]]; then
    if has_alternate_package "${_package}"; then
      ! $DEBUG && printf "${_package} ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}"
      ! $DEBUG && $force          && printf " ${COLOR_GREEN}(FORCE)${COLOR_NC}"
      ! $DEBUG && $as_root        && printf " ${COLOR_GREEN}(ROOT)${COLOR_NC}"
      ! $DEBUG && $recursive      && printf " ${COLOR_GREEN}(RECUR)${COLOR_NC}"
      ! $DEBUG && $allow_dep_fail && printf " ${COLOR_GREEN}(DEPFAILOK)${COLOR_NC}"
      ! $DEBUG && printf "\n"
      return $BASH_EX_OK
    else
      _res=$?
      if [[ $_res -eq $BASH_EZ_EX_PAC_GENERATED ]]; then
        ! $DEBUG && printf "${_package} ${COLOR_BLUE}(GENERATE)${COLOR_NC}"
      else
        ! $DEBUG && printf "${_package} ${COLOR_RED}(MISSING)${COLOR_NC}\n"
        return $BASH_EZ_EX_PAC_NOTFOUND
      fi
    fi
  else
    ! $DEBUG && printf "${_package}"
    ! $DEBUG && $force          && printf " ${COLOR_GREEN}(FORCE)${COLOR_NC}"
    ! $DEBUG && $as_root        && printf " ${COLOR_GREEN}(ROOT)${COLOR_NC}"
    ! $DEBUG && $recursive      && printf " ${COLOR_GREEN}(RECUR)${COLOR_NC}"
    ! $DEBUG && $allow_dep_fail && printf " ${COLOR_GREEN}(DEPFAILOK)${COLOR_NC}"
    ! $DEBUG && printf "\n"
  fi

  local _tmp="$(${EZ_INSTALL_METADATA_PARSER} "dependency" "${_package_path}")"
  local -a _package_dependencies=( ${_tmp//,/ } )
  local _has_missing=false
  local _next_indent=""

  for i in "${!_package_dependencies[@]}"; do
    if [[ $i -eq $((${#_package_dependencies[@]}-1)) ]]; then
      ! $DEBUG && printf "${_indent}└──"
      _next_indent="${_indent}   "
    else
      ! $DEBUG && printf "${_indent}├──"
      _next_indent="${_indent}│  "
    fi

    if has_package "${_package_dependencies[$i]}"; then
      _validate_dependencies ${config} -- "${_package_dependencies[$i]}" "${_next_indent}"
    else
      if has_alternate_package ${_package_dependencies[$i]}; then
        ! $DEBUG && printf "${_package_dependencies[$i]} ${COLOR_YELLOW}(CHOOSE)${COLOR_NC}"
      else
        _res=$?
        if [[ $_res -eq $BASH_EZ_EX_PAC_GENERATED ]]; then
          ! $DEBUG && printf "${_package_dependencies[$i]} ${COLOR_BLUE}(GENERATE)${COLOR_NC}"
        else
          ! $DEBUG && printf "${_package_dependencies[$i]} ${COLOR_RED}(MISSING)${COLOR_NC}\n"
          _has_missing=true
          continue
        fi
      fi
      ! $DEBUG && $force          && printf " ${COLOR_GREEN}(FORCE)${COLOR_NC}"
      ! $DEBUG && $as_root        && printf " ${COLOR_GREEN}(ROOT)${COLOR_NC}"
      ! $DEBUG && $recursive      && printf " ${COLOR_GREEN}(RECUR)${COLOR_NC}"
      ! $DEBUG && $allow_dep_fail && printf " ${COLOR_GREEN}(DEPFAILOK)${COLOR_NC}"
      ! $DEBUG && printf "\n"
    fi
  done

  if ${_has_missing}; then
    return $BASH_EZ_EX_PAC_NOTFOUND
  fi
}

