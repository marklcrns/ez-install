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


source "${EZ_INSTALL_HOME}/install/utils/actions.sh"
for install_script in ${EZ_INSTALL_HOME}/install/install-utils/install-*.sh; do
  source "${install_script}"
done


install() {
  local args=""
  local command_name=""
  local package_name=""
  local as_root=false
  local update=false

  OPTIND=1
  while getopts "a:c:n:S:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      S)
        as_root=${OPTARG}
        ;;
      u)
        update=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  local package_manager=""
  local file=""
  local package=""
  local destination=""

  [[ -z "${1+x}" ]] && error "No package manager provided"
  [[ -z "${2+x}" ]] && error "No package provided"

  package_manager="$(echo "${1}" | awk '{print tolower($0)}')"
  file="${2:-${package_name}}"
  package="${file}"
  destination="${3:-}"

  if [[ ${package_manager} == "curl" ]] || [[ ${package_manager} == "wget" ]] || [[ ${package_manager} == "git" ]]; then
    if [[ -z "${package_name}" ]]; then
      error "No package name provided for '${package_manager} ${package}'"
      return 2
    fi
    file="${package_name}"
  fi

  local res=0

  case ${package_manager} in
    apt)
      apt_install -a "${args}" -c "${command_name}" -S ${as_root} -u ${update} -- "${package}" || return 1
      ;;
    apt-add)
      apt_add_repo -a "${args}" -c "${command_name}" -S ${as_root} -- ${package} || return 1
      ;;
    npm)
      npm_install -a "${args}" -c "${command_name}" -S ${as_root} -- "${package}" || return 1
      ;;
    pip)
      pip_install -a "${args}" -c "${command_name}" -S ${as_root} -- "${package}" || return 1
      ;;
    pip2)
      pip_install -v 2 -a "${args}" -c "${command_name}" -S ${as_root} -- "${package}" || return 1
      ;;
    pip3)
      pip_install -v 3 -a "${args}" -c "${command_name}" -S ${as_root} -- "${package}" || return 1
      ;;
    pkg)
      pkg_install -a "${args}" -c "${command_name}" -S ${as_root} -- "${package}" || return 1
      ;;
    curl)
      curl_install -a "${args}" \
                   -c "${command_name}" \
                   -n "${package_name}" \
                   -o "${destination}" \
                   -S ${as_root} \
                   -- "${package}" \
                   || return 1
      ;;
    wget)
      wget_install -a "${args}" \
                   -c "${command_name}" \
                   -n "${package_name}" \
                   -o "${destination}" \
                   -S ${as_root} \
                   -- "${package}" \
                   || return 1
      ;;
    git)
      git_clone -a "${args}" \
                -n "${package_name}" \
                -o "${destination}" \
                -S ${as_root} \
                -- "${package}" \
                || return 1
      ;;
    local)
      # Do nothing but check if executable exists and trigger pre and post processes
      local_install -c "${command_name}" -- "${package}" || return 0
      ;;
    *)
      error "'${package_manager}' package manager not supported"
      return 1
      ;;
  esac

  res=$?
  return ${res}
}
