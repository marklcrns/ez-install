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
  local args= destination= package_name=

  OPTIND=1
  while getopts "a:d:n:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      d)
        destination="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "No package manager provided"
  fi
  local package_manager="$(echo "${1}" | awk '{print tolower($0)}')"

  if [[ -z "${2+x}" ]]; then
    error "No package provided"
  fi
  local file="${2:-}"
  local package="${file}"

  if [[ ${package_manager} == "curl" ]] || [[ ${package_manager} == "wget" ]]; then
    if [[ -z "${package_name}" ]]; then
      error "No package name provided for '${package_manager} ${package}'"
      return 2
    fi
    file="${package_name}"
  fi

  # Pre process global
  if [[ -e "${PACKAGE_DIR}/${file}.pre" ]]; then
    ./"${PACKAGE_DIR}/${file}.pre"
  fi
  # Pre process local
  if [[ -e "${PACKAGE_DIR}/${file}.${package_manager}.pre" ]]; then
    ./"${PACKAGE_DIR}/${file}.${package_manager}.pre"
  fi

  case ${package_manager} in
    apt)
      apt_install ${args} -- "${package}" || return 1
      ;;
    add-apt)
      apt_add_repo ${package} || return 1
      ;;
    curl)
      curl_install ${args} -n "${package_name}" -- "${package}" "${destination}" || return 1
      ;;
    git)
      git_clone ${args} -- "${package}" "${destination}" || return 1
      ;;
    npm)
      npm_install ${args} -- "${package}" || return 1
      ;;
    pip)
      pip_install ${args} -- "${package}" || return 1
      ;;
    pip2)
      pip_install -v 2 -- "${package}" || return 1
      ;;
    pip3)
      pip_install -v 3 -- "${package}" || return 1
      ;;
    pkg)
      pkg_install ${args} -- "${package}" || return 1
      ;;
    wget)
      wget_install ${args} -n "${package_name}" -- "${package}" "${destination}" || return 1
      ;;
    *)
      error "'${package_manager}' package manager not supported"
      return 1
      ;;
  esac

  # Post process global
  if [[ -e "${PACKAGE_DIR}/${file}.post" ]]; then
    "${PACKAGE_DIR}/${file}.post"
  fi
  # Post process local
  if [[ -e "${PACKAGE_DIR}/${file}.${package_manager}.post" ]]; then
    "${PACKAGE_DIR}/${file}.${package_manager}.post"
  fi

  local res=$?
  return ${res}
}

