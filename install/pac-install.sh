#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${PACKAGE_PACKAGE_INSTALL_SH_INCLUDED+x}" ]] \
  && readonly PACKAGE_PACKAGE_INSTALL_SH_INCLUDED=1 \
  || return 0


source "${BASH_SOURCE%/*}/utils/pac-logger.sh"
source "${BASH_SOURCE%/*}/utils/progress-bar.sh"


pac_install() {
  local package="${1:-}"
  local package_dir="${PACKAGE_DIR:-${BASH_SOURCE%/*}/../generate/packages}"

  if [[ ! -e "${package_dir}/${package}" ]]; then
    pac_log_failed 'N/A' "${package}" "Package '${package}' not found in ${package_dir}"
    return 1
  fi

  pac_install_dependencies "${package}" "${package_dir}"

  source "${package_dir}/${package}" -y
  return 0
}

pac_install_dependencies() {
  local package="${1:-}"
  local package_dir="${PACKAGE_DIR:-${BASH_SOURCE%/*}/../generate/packages}"

  local _dependency_tracker="$(realpath -- ${BASH_SOURCE%/*})/utils/dependency-tracker"
  local _dependencies="$(${_dependency_tracker} -p "${package}" -d "${package_dir}")"

  for dependency in ${_dependencies}; do
    warning "Installing ${package} dependency -- ${dependency}"
    pac_install "${dependency}"
  done
}

pac_batch_install() {
  local packages=("${@}")
  local width="${#packages[@]}"
  local i=1

  if [[ -n "${packages}" ]]; then
    for package in ${packages[@]}; do
      pac_install "${package}"
      prog_bar "$(("${i}*100/${width}"))"
      echo "- ${package}"
      ((++i))
    done
  else
    error "${FUNCNAME[0]}: Required packages array not found"
  fi
}
