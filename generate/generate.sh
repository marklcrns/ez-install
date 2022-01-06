#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${GENERATE_GENERATE_SH_INCLUDED+x}" ]] \
  && readonly GENERATE_GENERATE_SH_INCLUDED=1 \
  || return 0


source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"


function batch_generate_package() {
  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local packages=( "${@}" )

  for package in ${packages[@]}; do
    generate_package "${package}"
  done
}


function generate_package() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1##*#}"
  local package_name="${package%.*}"
  local package_manager="$([[ "${package##*.}" != "${package}" ]] && echo "${package##*.}" || echo 'null')"

  resolve_package_dir

  local matches=(
    $(find "${LOCAL_PACKAGE_DIR}" -type f \
      ! -name "${package_name}*.pre" \
      ! -name "${package_name}*.post" \
      ! -name "${package_name}.${package_manager}.*" \
      -name "${package_name}*.*")
    )

  if [[ -n "${matches+x}" ]]; then
    echo -e "Existing package(s) found in:\n"
    local i=
    for i in "${!matches[@]}"; do
      printf "$(($i+1))) ${matches[$i]}\n"
    done

    echo ""

    local continue=""
    while ! [[ "${continue}" =~ ^[Yy]$ ]]; do
      get_user_input "${COLOR_YELLOW}Might overwrite existing package. Continue? (Y/y):${COLOR_NC} " continue
    done
  fi

  local author=""
  local dependencies=""
  local executable_name=""
  local output_dir=""
  local update=false
  local execute=false
  local args=""
  local res=0

  echo -e "Generating for '${package}' package..."

  local proceed=""
  while ! [[ "${proceed}" =~ ^[Yy]$ ]]; do
    echo -e "\n  Everything is optional. Press [enter] to skip.\n"
    get_user_input "  Author: " author
    get_user_input "  Dependencies (use ',' separator): " dependencies
    get_user_input "  Executable name: " executable_name
    get_user_input "  Package manager: " package_manager
    while ! is_package_manager_supported package_manager; do
      echo "package manager: ${package_manager}"
      get_user_input "  Package manager: " package_manager
    done

    if [[ ${package_manager} == "curl" ]] \
      || [[ ${package_manager} == "wget" ]] \
      || [[ ${package_manager} == "git" ]]; then
      get_user_input "  Output directory: " output_dir
      if [[ ${package_manager} == "curl" ]] \
        || [[ ${package_manager} == "wget" ]]; then
        get_user_input "  Execute (default=false): " execute
      fi
    fi

    if [[ ${package_manager} == "apt" ]] \
      || [[ ${package_manager} == "apt-add" ]] \
      || [[ ${package_manager} == "pkg" ]]; then
      get_user_input "  Update (default=false): " execute
    fi

    get_user_input "  Package manager args: " args

    echo ""

    continue=""
    while ! [[ "${continue}" =~ ^[Yy]$ ]]; do
      get_user_input "${COLOR_YELLOW}Would you like to proceed? (Y/y):${COLOR_NC} " continue
    done
    proceed="${continue}"
  done

  # Escape whitespaces
  local ez_gen_args=
  [[ -n "${author}" ]]          && ez_gen_args+=" -A ${author// /\\ }"
  [[ -n "${dependencies}" ]]    && ez_gen_args+=" -d ${dependencies// /\\ }"
  [[ -n "${executable_name}" ]] && ez_gen_args+=" -c ${executable_name// /\\ }"
  [[ -n "${package_name}" ]]    && ez_gen_args+=" -n ${package_name// /\\ }"
  [[ -n "${package_manager}" ]] && ez_gen_args+=" -m ${package_manager// /\\ }"
  [[ -n "${output_dir}" ]]      && ez_gen_args+=" -o ${output_dir// /\\ }"
  [[ -n "${args}" ]]            && ez_gen_args+=" -a ${args// /\\ }"
  [[ ${update} ]]               && ez_gen_args+=" -u"
  [[ ${execute} ]]              && ez_gen_args+=" -e"
  ! ${VERBOSE}                  && ez_gen_args+=" -q"
  ${DEBUG}                      && ez_gen_args+=" -x"

  ${EZ_DEP_EZ_GEN} -y ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


function generate_package_pre() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1##*#}"
  local package_name="${package%.*}"
  local package_manager="$([[ "${package##*.}" != "${package}" ]] && echo "${package##*.}" || echo 'null')"

  resolve_package_dir

  local matches=(
  $(find "${LOCAL_PACKAGE_DIR}" -type f \
    ! -name "${package_name}*.post" \
    ! -name "${package_name}.${package_manager}.*" \
    -name "${package_name}*.pre")
  )

  local continue=""
  local res=0

  if [[ -n "${matches+x}" ]]; then
    echo -e "Existing package(s) found in:\n"
    local i=
    for i in "${!matches[@]}"; do
      printf "$(($i+1))) ${matches[$i]}\n"
    done

    echo ""
    while ! [[ "${continue}" =~ ^[Yy]$ ]]; do
      get_user_input "${COLOR_YELLOW}Might overwrite existing package. Continue? (Y/y):${COLOR_NC} " continue
    done
  fi

  echo -e "Generating for '${package}.pre' package..."

  local proceed=""
  while ! [[ "${proceed}" =~ ^[Yy]$ ]]; do
    echo -e "\n  Everything is optional. Press [enter] to skip.\n"
    get_user_input "  Package manager: " package_manager
    while ! is_package_manager_supported package_manager; do
      echo "package manager: ${package_manager}"
      get_user_input "  Package manager: " package_manager
    done

    if [[ ${package_manager} == "curl" ]] \
      || [[ ${package_manager} == "wget" ]] \
      || [[ ${package_manager} == "git" ]]; then
      get_user_input "  Output directory: " output_dir
      if [[ ${package_manager} == "curl" ]] \
        || [[ ${package_manager} == "wget" ]]; then
        get_user_input "  Execute (default=false): " execute
      fi
    fi

    if [[ ${package_manager} == "apt" ]] \
      || [[ ${package_manager} == "apt-add" ]] \
      || [[ ${package_manager} == "pkg" ]]; then
      get_user_input "  Update (default=false): " execute
    fi

    echo ""
    continue=""
    while ! [[ "${continue}" =~ ^[Yy]$ ]]; do
      get_user_input "${COLOR_YELLOW}Would you like to proceed? (Y/y):${COLOR_NC} " continue
    done
    proceed="${continue}"
  done

  # Escape whitespaces
  local ez_gen_args=
  [[ -n "${package_name}" ]]    && ez_gen_args+=" -n ${package_name// /\\ }"
  [[ -n "${package_manager}" ]] && ez_gen_args+=" -m ${package_manager// /\\ }"
  ! ${VERBOSE}                  && ez_gen_args+=" -q"
  ${DEBUG}                      && ez_gen_args+=" -x"

  ${EZ_DEP_EZ_GEN} -yS -p ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


function generate_package_post() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1##*#}"
  local package_name="${package%.*}"
  local package_manager="$([[ "${package##*.}" != "${package}" ]] && echo "${package##*.}" || echo 'null')"

  resolve_package_dir

  local matches=(
  $(find "${LOCAL_PACKAGE_DIR}" -type f \
    ! -name "${package_name}*.pre" \
    ! -name "${package_name}.${package_manager}.*" \
    -name "${package_name}*.post")
  )

  local continue=""
  local res=0

  if [[ -n "${matches+x}" ]]; then
    echo -e "Existing package(s) found in:\n"
    local i=
    for i in "${!matches[@]}"; do
      printf "$(($i+1))) ${matches[$i]}\n"
    done

    echo ""
    while ! [[ "${continue}" =~ ^[Yy]$ ]]; do
      get_user_input "${COLOR_YELLOW}Might overwrite existing package. Continue? (Y/y):${COLOR_NC} " continue
    done
  fi

  echo -e "Generating for '${package}.post' package..."

  local proceed=""
  while ! [[ "${proceed}" =~ ^[Yy]$ ]]; do
    echo -e "\n  Everything is optional. Press [enter] to skip.\n"
    get_user_input "  Package manager: " package_manager
    while ! is_package_manager_supported package_manager; do
      echo "package manager: ${package_manager}"
      get_user_input "  Package manager: " package_manager
    done

    if [[ ${package_manager} == "curl" ]] \
      || [[ ${package_manager} == "wget" ]] \
      || [[ ${package_manager} == "git" ]]; then
      get_user_input "  Output directory: " output_dir
      if [[ ${package_manager} == "curl" ]] \
        || [[ ${package_manager} == "wget" ]]; then
        get_user_input "  Execute (default=false): " execute
      fi
    fi

    if [[ ${package_manager} == "apt" ]] \
      || [[ ${package_manager} == "apt-add" ]] \
      || [[ ${package_manager} == "pkg" ]]; then
      get_user_input "  Update (default=false): " execute
    fi

    echo ""
    continue=""
    while ! [[ "${continue}" =~ ^[Yy]$ ]]; do
      get_user_input "${COLOR_YELLOW}Would you like to proceed? (Y/y):${COLOR_NC} " continue
    done
    proceed="${continue}"
  done

  # Escape whitespaces
  local ez_gen_args=
  [[ -n "${package_name}" ]]    && ez_gen_args+=" -n ${package_name// /\\ }"
  [[ -n "${package_manager}" ]] && ez_gen_args+=" -m ${package_manager// /\\ }"
  ! ${VERBOSE}                  && ez_gen_args+=" -q"
  ${DEBUG}                      && ez_gen_args+=" -x"

  ${EZ_DEP_EZ_GEN} -yS -P ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


function is_package_manager_supported() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  eval "local _package_manager=\${$1}"

  [[ -z "${_package_manager}" ]] && return $BASH_EX_OK

  local _pacman=""
  for _pacman in ${EZ_SUPPORTED_PACKAGE_MANAGER}; do
    if [ "${_package_manager}" = "${_pacman}" ]; then
      return $BASH_EX_OK
    fi
  done

  error "${BASH_EZ_MSG_PACMAN_NOTFOUND}"
  return $BASH_EZ_EX_PACMAN_NOTFOUND
}

