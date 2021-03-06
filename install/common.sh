#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${PACKAGES_COMMON_SH_INCLUDED+x}" ]] \
  && readonly PACKAGES_COMMON_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/sys.sh"
include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/common/log.sh"
include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/install-utils/install.sh"


function resolve_package_dir() {
  os_release
  local distrib_id="${OS_DISTRIB_ID}"; to_lower distrib_id
  local distrib_release="${OS_DISTRIB_RELEASE}"

  if [[ -z "${PACKAGE_ROOT_DIR+x}" ]]; then
    PACKAGE_ROOT_DIR="$(realpath -s "${EZ_INSTALL_HOME}/generate/packages")"
  fi
  if [[ -z "${LOCAL_PACKAGE_ROOT_DIR+x}" ]]; then
    PACKAGE_ROOT_DIR="${HOME}/.ez-install.d/packages"
  fi

  if [[ -n "${PACKAGE_ROOT_DIR+x}" ]]; then
    PACKAGE_DIR="${PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
  fi
  if [[ -n "${LOCAL_PACKAGE_ROOT_DIR+x}" ]]; then
    LOCAL_PACKAGE_DIR="${LOCAL_PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
  fi
}


function fetch_package() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package_var_name="${1:-}"
  eval "local package=\"\$${package_var_name}\""

  if [[ -z "${package+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_INVREFVAR}"
    return $BASH_SYS_EX_USAGE
  fi
 
  if [[ -e "${LOCAL_PACKAGE_DIR}/${package}" ]]; then
    info "Package '${package}' found in '${LOCAL_PACKAGE_DIR}'"
    eval "${package_var_name}='${LOCAL_PACKAGE_DIR}/${package}'"
    return $BASH_EX_OK
  elif [[ -e "${PACKAGE_DIR}/${package}" ]]; then
    info "Package '${package}' found in '${PACKAGE_DIR}'"
    eval "${package_var_name}='${PACKAGE_DIR}/${package}'"
    return $BASH_EX_OK
  else
    skip "Package '${package}' not found"
    return $BASH_EZ_EX_PAC_NOTFOUND
  fi
}


function has_package() {
  if [[ ! -e "${LOCAL_PACKAGE_DIR}/${1:?}" ]] && [[ ! -e "${PACKAGE_DIR}/${1}" ]]; then
    return $BASH_EZ_EX_PAC_NOTFOUND || return $BASH_EX_OK
  fi
}


# TODO: Search as executable name instead if package not found using grep
function select_package() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi
  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1%.*}"
  local package_ext="$([[ "${1##*.}" != "${package}" ]] && echo "${1##*.}")"
  local selected_var_name="${2}"
  local excluded=${3:-}

  local package_dirs=
  [[ -d "${PACKAGE_DIR}" ]] && package_dirs=( ${package_dirs} "${PACKAGE_DIR}" )
  [[ -d "${LOCAL_PACKAGE_DIR}" ]] && package_dirs=( ${package_dirs} "${LOCAL_PACKAGE_DIR}" )

  local matches=(
    $(find ${package_dirs[@]} -type f \
      ! -name "${excluded}" \
      ! -name "*${package}*.pre" \
      ! -name "*${package}*.post" \
      ! -name "*${package}.${package_ext}.*" \
      -name "*${package}*" \
    )
  )

  local select=""

  if [[ -n "${matches[@]}" ]]; then
    if [[ "${#matches[@]}" -eq 1 ]]; then
      select="${matches[0]}"
      warning "Defaulting: ${package} -> $(basename -- "${select}")"
    else
      printf "\nMultiple '${package}' package detected\n\n"
      local i=
      while true; do
        printf "0) SKIP INSTALL\n"
        for i in "${!matches[@]}"; do
          printf "$(($i+1))) ${matches[$i]}\n"
        done
        printf "\n"
        read -p "Please select from the matches (1-${#matches[@]}): "
        printf "\n"
        if [[ "${REPLY}" =~ ^-?[0-9]+$  ]]; then
          if [[ "${REPLY}" -le "${#matches[@]}" ]]; then
            [[ "${REPLY}" -eq 0 ]] && return $BASH_EX_OK   # Skip
            select="${matches[$(($REPLY-1))]}"
            break
          fi
        fi
      done
    fi
  fi

  if [[ -n "${select}" ]]; then
    eval "${selected_var_name}=${select}"
    return $BASH_EX_OK
  else
    skip "No matching package for '${package}'"
    return $BASH_EZ_EX_PAC_NOTFOUND
  fi
}


function has_alternate_package() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1%.*}"
  local package_ext="$([[ "${1##*.}" != "${package}" ]] && echo "${1##*.}")"

  local package_dirs=
  [[ -d "${PACKAGE_DIR}" ]] && package_dirs=( ${package_dirs} "${PACKAGE_DIR}" )
  [[ -d "${LOCAL_PACKAGE_DIR}" ]] && package_dirs=( ${package_dirs} "${LOCAL_PACKAGE_DIR}" )

  local matches=(
    $(find ${package_dirs[@]} -type f \
      ! -name "*${package}*.pre" \
      ! -name "*${package}*.post" \
      ! -name "*${package}.${package_ext}.*" \
      -name "*${package}*" \
    )
  )

  if [[ -n "${matches[@]}" ]]; then
    info "Alternate package found for '${package}'"
    return $BASH_EX_OK
  fi

  local res=0
  if ! $SKIP_GENERATE; then
    ! $DEBUG && printf "\n"
    warning "Generating ${package}"
    ${EZ_COMMAND_GEN} -i ${package}
    res=$?
    [[ $res -eq $BASH_EX_OK ]] && return $BASH_EZ_EX_PAC_GENERATED || return $res
  fi

  info "Alternate package NOT found for '${package}'"
  return $BASH_EZ_EX_PAC_NOTFOUND
}


# Requires $recursive and $as_root to be defined outside of function
function parse_inline_opts() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi
  
  local __package="${1%#*}"   # Strip #opts
  local __opts="${1##*#}"     # Strip package

  [[ -z ${config+x} ]] && config=""

  if [[ "${__opts}" != "${__package}" ]]; then
    for __opt in ${__opts//,/ }; do
      case ${__opt} in
        force) force=true;                 strip_substr ' -F' config; config="${config} -f" ;;
        noforce) force=false;              strip_substr ' -f' config; config="${config} -F" ;;
        dep) recursive=true;               strip_substr ' -R' config; config="${config} -r" ;;
        nodep) recursive=false;            strip_substr ' -r' config; config="${config} -R" ;;
        root) as_root=true;                strip_substr ' -S' config; config="${config} -s" ;;
        noroot) as_root=false;             strip_substr ' -s' config; config="${config} -S" ;;
        allowdepfail) allow_dep_fail=true; strip_substr ' -W' config; config="${config} -w" ;;
        nodepfail) allow_dep_fail=false;   strip_substr ' -w' config; config="${config} -W" ;;
      esac
    done
  fi
}


function get_user_input() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  echo -ne "${2}"
  read ${1}
}


function get_sys_package_manager() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local manager=""

  if is_darwin; then
    manager='brew'
  elif is_linux; then
    if [[ -x "$(command -v 'apk')" ]]; then
      manager='apk'
    elif [[ -x "$(command -v 'pkg')" ]]; then
      manager='pkg'
    elif [[ -x "$(command -v 'packman')" ]]; then
      manager='packman'
    elif [[ -x "$(command -v 'apt')" ]]; then
      manager='apt'
    elif [[ -x "$(command -v 'dnf')" ]]; then
      manager='dnf'
    elif [[ -x "$(command -v 'zypper')" ]]; then
      manager='zypper'
    fi
  else
    error "${BASH_EZ_MSG_PACMAN_NOTFOUND}"
    return $BASH_EZ_EX_PACMAN_NOTFOUND
  fi

  eval "${1}='${manager}'"
}

