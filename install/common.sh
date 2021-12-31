#!/usr/bin/env bash

set -o pipefail
set -o nounset

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${PACKAGES_COMMON_SH_INCLUDED+x}" ]] \
  && readonly PACKAGES_COMMON_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/common/sys.sh"
source "${EZ_INSTALL_HOME}/common/colors.sh"
source "${EZ_INSTALL_HOME}/common/log.sh"
source "${EZ_INSTALL_HOME}/install/install.sh"


resolve_package_dir() {
  os_release
  local distrib_id="${OS_DISTRIB_ID}"; to_lower distrib_id
  local distrib_release="${OS_DISTRIB_RELEASE}"

  if [[ -z ${PACKAGE_ROOT_DIR+x} ]]; then
    PACKAGE_ROOT_DIR="$(realpath -s "${EZ_INSTALL_HOME}/generate/packages")"
  fi
  if [[ -z ${PACKAGE_DIR+x} ]]; then
    PACKAGE_DIR="${PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
  fi
  if [[ -n ${LOCAL_PACKAGE_ROOT_DIR+x} ]]; then
    LOCAL_PACKAGE_DIR="${LOCAL_PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
  fi
}


fetch_package() {
  local package_var_name="${1:-}"
  eval "local package=\"\$${package_var_name}\""

  [[ -z "${package}" ]] && error "No package provided"
 
  if [[ -e "${LOCAL_PACKAGE_DIR}/${package}" ]]; then
    info "Package '${package}' found in '${LOCAL_PACKAGE_DIR}'"
    eval "${package_var_name}='${LOCAL_PACKAGE_DIR}/${package}'"
    return 0
  elif [[ -e "${PACKAGE_DIR}/${package}" ]]; then
    info "Package '${package}' found in '${PACKAGE_DIR}'"
    eval "${package_var_name}='${PACKAGE_DIR}/${package}'"
    return 0
  else
    warning "Package '${package}' not found"
    return 1
  fi
}


has_package() {
  if [[ ! -e "${LOCAL_PACKAGE_DIR}/${1:?}" ]] && [[ ! -e "${PACKAGE_DIR}/${1}" ]]; then
    return 1 || return 0
  fi
}


# TODO: Search as executable name instead if package not found using grep
function select_package() {
  if [[ -z "${1:-}" ]]; then
    error "No package provided"
    return 1
  fi
  if [[ -z "${2:-}" ]]; then
    error "No variable name provided for selected package"
    return 1
  fi

  local package="${1%.*}"
  local package_ext="$([[ "${1##*.}" != "${package}" ]] && echo "${1##*.}")"
  local selected_var_name="${2}"
  local excluded=${3:-}

  local matches=(
    $(find "${LOCAL_PACKAGE_DIR}" "${PACKAGE_DIR}" -type f \
      ! -name "${excluded}" \
      ! -name "${package}*.pre" \
      ! -name "${package}*.post" \
      ! -name "${package}.${package_ext}.*" \
      -name "${package}*.*"
    )
  )

  local select=""

  if [[ -n "${matches+x}" ]]; then
    if [[ "${#matches[@]}" -eq 1 ]]; then
      select="${matches[0]}"
      info "Defaulting: ${select}"
    else
      printf "\nMultiple '${package}' package detected\n\n"
      local i=
      while true; do
        for i in "${!matches[@]}"; do
          printf "$(($i+1))) ${matches[$i]}\n"
        done
        printf "\n"
        read -p "Please select from the matches (1-${#matches[@]}): "
        printf "\n"
        if [[ "${REPLY}" =~ ^-?[0-9]+$  ]] && [[ "${REPLY}" -le "${#matches[@]}" ]]; then
          select="${matches[$(($REPLY-1))]}"
          break
        fi
      done
    fi
  fi

  if [[ -n "${select}" ]]; then
    eval "${selected_var_name}=${select}"
    return 0
  else
    return 1
  fi
}


has_alternate_package() {
  if [[ -z "${1:-}" ]]; then
    error "No package provided"
    return 1
  fi

  local package="${1%.*}"
  local package_ext="$([[ "${1##*.}" != "${package}" ]] && echo "${1##*.}")"
  local matches=(
    $(find "${LOCAL_PACKAGE_DIR}" "${PACKAGE_DIR}" -type f \
      ! -name "${package}*.pre" \
      ! -name "${package}*.post" \
      ! -name "${package}.${package_ext}.*" \
      -name "${package}*.*")
    )

  if [[ -n "${matches+x}" ]]; then
    info "Alternate package found for '${package}'"
    return 0
  fi

  info "Alternate package NOT found for '${package}'"
  return 1
}


get_sys_package_manager() {
  if [[ -z "${1:-}" ]]; then
    error "No variable name provided for package manager"
    return 1
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
    log 'error' 'No package manager supported'
    exit 1
  fi

  eval "${1}='${manager}'" && return 0 || return 1
}

