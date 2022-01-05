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


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/string.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"
for script in ${EZ_INSTALL_HOME}/install/install-utils/install-*.sh; do
  include "${script}"
done


function install() {
  local args=""
  local command_name=""
  local package_manager=""
  local package_name=""
  local destination=""
  local execute=false
  local as_root=false
  local update=false

  OPTIND=1
  while getopts "a:c:e:m:n:o:S:u:" opt; do
    case ${opt} in
      a)
        args="${OPTARG}"
        ;;
      c)
        command_name="${OPTARG}"
        ;;
      e)
        execute=${OPTARG}
        ;;
      m)
        package_manager="${OPTARG}"
        to_lower package_manager
        ;;
      n)
        package_name="${OPTARG}"
        ;;
      o)
        destination="${OPTARG}"
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

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1}"
  local file="${package}"

  if [[ ${package_manager} == "curl" ]] || [[ ${package_manager} == "wget" ]] || [[ ${package_manager} == "git" ]]; then
    if [[ -z "${package_name}" ]]; then
      error "No package name provided for '${package_manager} ${package}'"
      return $BASH_SYS_EX_USAGE
    fi
    file="${package_name}"
  fi

  local res=0

  case ${package_manager} in
    apt)
      apt_install -a "${args}" \
                  -c "${command_name}" \
                  -n "${package_name}" \
                  -S $as_root \
                  -u $update \
                  -- "${package}" \
      ;;
    apt-add)
      apt_add_repo -a "${args}" \
                   -c "${command_name}" \
                   -n "${package_name}" \
                   -S $as_root \
                   -u $update \
                   -- "${package}" \
      ;;
    pkg)
      pkg_install -a "${args}" \
                  -c "${command_name}" \
                  -n "${package_name}" \
                  -S $as_root \
                  -u $update \
                  -- "${package}" \
      ;;
    npm)
      npm_install -a "${args}" \
                  -c "${command_name}" \
                  -n "${package_name}" \
                  -S $as_root \
                  -- "${package}" \
      ;;
    pip)
      pip_install -a "${args}" \
                  -c "${command_name}" \
                  -n "${package_name}" \
                  -S $as_root \
                  -- "${package}" \
      ;;
    pip2)
      pip_install -v 2 \
                  -a "${args}" \
                  -c "${command_name}" \
                  -n "${package_name}" \
                  -S $as_root \
                  -- "${package}" \
      ;;
    pip3)
      pip_install -v 3 \
                  -a "${args}" \
                  -c "${command_name}" \
                  -n "${package_name}" \
                  -S $as_root \
                  -- "${package}" \
      ;;
    curl)
      curl_install -a "${args}" \
                   -c "${command_name}" \
                   -n "${package_name}" \
                   -o "${destination}" \
                   -e $execute \
                   -S $as_root \
                   -- "${package}" \
      ;;
    wget)
      wget_install -a "${args}" \
                   -c "${command_name}" \
                   -n "${package_name}" \
                   -o "${destination}" \
                   -e $execute \
                   -S $as_root \
                   -- "${package}" \
      ;;
    git)
      git_clone -a "${args}" \
                -c "${command_name}" \
                -n "${package_name}" \
                -o "${destination}" \
                -S $as_root \
                -- "${package}" \
      ;;
    local)
      # Do nothing but check if executable exists and trigger pre and post processes
      local_install -c "${command_name}" -n "${package_name}" -- "${package}"
      ;;
    *)
      error "${BASH_EZ_MSG_PACMAN_NOTFOUND}"
      return $BASH_EZ_EX_PACMAN_NOTFOUND
      ;;
  esac

  res=$?
  return $res
}

