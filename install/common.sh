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


source "${BASH_SOURCE%/*}/../common/sys.sh"
source "${BASH_SOURCE%/*}/../common/colors.sh"
source "${BASH_SOURCE%/*}/../common/log.sh"
source "${BASH_SOURCE%/*}/../install/install.sh"


usage() {
  local scriptpath="$(realpath -- "${0}")"

cat <<- EOF
$(basename -- "${scriptpath}")

USAGE:

./$(basename -- "${scriptpath}") [ -hvxy ] [ -m <manager> ] [ -p <package> ]

OPTIONS:

  -m --manager    package manager
  -p --package    package
  -v --verbose    verbose output
  -x --debug      debug
  -y --skip       skip confirmation
  -h --help       show usage
EOF
}


handle_args() {
  local arg=
  for arg; do
    local delim=""
    case "${arg}" in
      --manager)        args="${args:-}-m ";;
      --package)        args="${args:-}-p ";;
      --verbose)        args="${args:-}-v ";;
      --debug)          args="${args:-}-x ";;
      --skip-confirm)   args="${args:-}-y ";;
      --help)           args="${args:-}-h ";;
      *)
        [[ "${arg:0:1}" == "-" ]] || delim="\""
        args="${args:-}${delim}${arg}${delim} ";;
    esac
  done

  eval set -- ${args:-}

  [[ -z "${SKIP_CONFIRM+x}" ]]    && SKIP_CONFIRM=false
  [[ -z "${VERBOSE+x}" ]]         && VERBOSE=false
  [[ -z "${DEBUG+x}" ]]           && DEBUG=false
  [[ -z "${LOG_DEBUG_LEVEL+x}" ]] && LOG_DEBUG_LEVEL=3

  OPTIND=1
  while getopts "m:p:vxyh" opt; do
    case ${opt} in
      m)
        readonly PACKAGE_MANAGER=$(echo "${OPTARG}" | awk '{print tolower($0)}')
        ;;
      p)
        readonly PACKAGE="${OPTARG}"
        ;;
      v)
        VERBOSE=true
        ;;
      x)
        DEBUG=true
        LOG_DEBUG_LEVEL=7
        ;;
      y)
        SKIP_CONFIRM=true
        ;;
      h)
        usage; exit 0
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  readonly SKIP_CONFIRM
  readonly VERBOSE
  readonly DEBUG
  readonly LOG_DEBUG_LEVEL

  return 0
}


resolve_package_dir() {
  os_release
  local distrib_id="${OS_DISTRIB_ID}"; to_lower distrib_id
  local distrib_release="${OS_DISTRIB_RELEASE}"

  if [[ -z ${PACKAGE_ROOT_DIR+x} ]]; then
    PACKAGE_ROOT_DIR="$(realpath -s "${BASH_SOURCE%/*}/../generate/packages")"
  fi
  if [[ -z ${PACKAGE_DIR+x} ]]; then
    PACKAGE_DIR="${PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
  fi
  if [[ -n ${LOCAL_PACKAGE_ROOT_DIR+x} ]]; then
    LOCAL_PACKAGE_DIR="${LOCAL_PACKAGE_ROOT_DIR}/${distrib_id}/${distrib_release}"
  fi
}


fetch_package() {
  : ${1?}
  # NOTE: localizing $package doesn't seem to work when assigning it to external
  # variables, but works on other occasion. pac_jsonify() in pac-transform.sh
  eval "local package=\"\$${1}\""
  
  if [[ -e "${LOCAL_PACKAGE_DIR}/${package}" ]]; then
    # info "Package '${package}' found in '${LOCAL_PACKAGE_DIR}'"
    eval "${1}='${LOCAL_PACKAGE_DIR}/${package}'"
    return 0
  elif [[ -e "${PACKAGE_DIR}/${package}" ]]; then
    # info "Package '${package}' found in '${PACKAGE_DIR}'"
    eval "${1}='${PACKAGE_DIR}/${package}'"
    return 0
  else
    warning "Package '${package}' not found"
    return 1
  fi
}


has_package() {
  [[ ! -e "${LOCAL_PACKAGE_DIR}/${1:?}" ]] && [[ ! -e "${PACKAGE_DIR}/${1}" ]] && \
    return 1 || return 0
}


# TODO: Search as executable name instead if package not found using grep
function select_package() {
  : ${1:?}
  local _package="${1%.*}"
  local _package_ext="$([[ "${1##*.}" != "${_package}" ]] && echo "${1##*.}")"
  local _selected_var=${2:?}
  local _excluded=${3:-}
  local _select=

  local _matches=(
    $(find "${LOCAL_PACKAGE_DIR}" "${PACKAGE_DIR}" -type f \
      ! -name "${_excluded}" \
      ! -name "${_package}*.pre" \
      ! -name "${_package}*.post" \
      ! -name "${_package}.${_package_ext}.*" \
      -name "${_package}*.*"
    )
  )

  if [[ -n "${_matches+x}" ]]; then
    if [[ "${#_matches[@]}" -eq 1 ]]; then
      _select="${_matches[0]}"
      info "Defaulting: ${_select}"
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
          _select="${_matches[$(($REPLY-1))]}"
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


has_alternate_package() {
  local _package="${1%.*:?}"
  local _package_ext="$([[ "${1##*.}" != "${_package}" ]] && echo "${1##*.}")"
  local _matches=(
    $(find "${LOCAL_PACKAGE_DIR}" "${PACKAGE_DIR}" -type f \
      ! -name "${_package}*.pre" \
      ! -name "${_package}*.post" \
      ! -name "${_package}.${_package_ext}.*" \
      -name "${_package}*.*")
  )
  if [[ -n "${_matches+x}" ]]; then
    info "Alternate package found for '${_package}'"
    return 0
  fi

  info "Alternate package NOT found for '${_package}'"
  return 1
}


get_sys_package_manager() {
  local manager=

  if is_darwin; then
    manager='brew'
  elif is_linux; then
    if [[ -x "$(command -v apk)" ]]; then
      manager='apk'
    elif [[ -x "$(command -v pkg)" ]]; then
      manager='pkg'
    elif [[ -x "$(command -v packman)" ]]; then
      manager='packman'
    elif [[ -x "$(command -v apt)" ]]; then
      manager='apt'
    elif [[ -x "$(command -v dnf)" ]]; then
      manager='dnf'
    elif [[ -x "$(command -v zypper)" ]]; then
      manager='zypper'
    fi
  else
    log 'error' 'No package manager supported'
    exit 1
  fi

  eval "${1}='${manager}'" && return 0 || return 1
}
