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
