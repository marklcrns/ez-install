#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${INSTALL_INSTALL_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INSTALL_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/utils/actions.sh"
for install_script in ${BASH_SOURCE%/*}/install-utils/install-*.sh; do
  source "${install_script}"
done


install() {
  local args= destination=

  OPTIND=1
  while getopts "d:a:" opt; do
    case ${opt} in
      d)
        destination="${OPTARG}"
        ;;
      a)
        args="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "No package manager provided"
  fi

  if [[ -z "${2+x}" ]]; then
    error "No package provided"
  fi

  local package_manager="${1:-}"
  local package="${2:-}"

  # Pre process
  if [[ -e "${PACKAGE_DIR}/${package}.pre" ]]; then
    ./"${PACKAGE_DIR}/${package}.pre"
  fi

  case ${package_manager} in
    apt)
      apt_install ${args} "${package}" || return 1
      ;;
    add-apt)
      apt_add_repo ${package} || return 1
      ;;
    curl)
      curl_install ${args} "${package}" "${destination}" || return 1
      ;;
    git)
      git_clone ${args} "${package}" "${destination}" || return 1
      ;;
    npm)
      npm_install ${args} "${package}" || return 1
      ;;
    pip)
      pip_install ${args} "${package}" || return 1
      ;;
    pkg)
      pkg_install ${args} "${package}" || return 1
      ;;
    wget)
      wget_install ${args} "${package}" "${destination}" || return 1
      ;;
    *)
      error "'${package_manager}' package manager not supported"
      return 1
      ;;
  esac

  # Post process
  if [[ -e "${PACKAGE_DIR}/${package}.post" ]]; then
    echo "package dir: ${PACKAGE_DIR}"
    "${PACKAGE_DIR}/${package}.post"
  fi

  local res=$?
  return ${res}
}

