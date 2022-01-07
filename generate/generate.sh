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
  local package_dir=""

  OPTIND=1
  while getopts "D:" opt; do
    case ${opt} in
      D)
        package_dir="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  resolve_package_dir

  local packages=( "${@}" )
  [[ -z "${package_dir}" ]] && package_dir="${LOCAL_PACKAGE_DIR}"

  for package in ${packages[@]}; do
    generate_package -D "${package_dir}" -- "${package}"
  done
}


function generate_package() {
  local package_dir=""

  OPTIND=1
  while getopts "D:" opt; do
    case ${opt} in
      D)
        package_dir="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  resolve_package_dir

  local package="${1##*#}"
  local package_name="${package%.*}"
  local package_manager="$([[ "${package##*.}" != "${package}" ]] && echo "${package##*.}")"
  [[ -z "${package_dir}" ]] && package_dir="${LOCAL_PACKAGE_DIR}"

  local author=""
  local dependencies=""
  local executable_name=""
  local output_dir=""
  local execute=""
  local update=""
  local args=""
  local indent="  "
  local res=0
  local matches=()

  echo -e "Generating for '${package}' package..."
  echo -e "\n${indent}${COLOR_HI_BLACK}All optional. Press [enter] to skip.${COLOR_NC}\n"

  while true; do
    prompt_input author "${indent}Author: "
    prompt_input dependencies "${indent}Dependencies (',' separator): "
    prompt_input package_name "${indent}Package name: "; package="${package_name}"
    prompt_input executable_name "${indent}Executable name: "
    prompt_package_manager package_manager "${indent}Package manager: "

    if [[ -n ${package_manager} ]]; then
      [[ "${package##*.}" == "${package}" ]] && package+=".${package_manager}"

      if [[ ${package_manager} == "curl" ]] \
        || [[ ${package_manager} == "wget" ]] \
        || [[ ${package_manager} == "git" ]]; then
        prompt_dir output_dir "${indent}${indent}Output directory: "
        if [[ ${package_manager} == "curl" ]] \
          || [[ ${package_manager} == "wget" ]]; then
          prompt_boolean execute "${indent}${indent}Shell execute (default=false): "
        fi
      elif [[ ${package_manager} == "apt" ]] \
        || [[ ${package_manager} == "apt-add" ]] \
        || [[ ${package_manager} == "pkg" ]]; then
        prompt_boolean update "${indent}${indent}${package_manager} update (default=false): "
      fi
      prompt_input args "${indent}${indent}${package_manager:-Package Manager} args: "
    fi

    matches=(
      $(find "${package_dir}" -type f \
        ! -name "${package_name}*.pre" \
        ! -name "${package_name}*.post" \
        -name "${package_name}?${package_manager}")
      )

    if [[ -n "${matches+x}" ]]; then
      echo -e "\nSimilar package(s) found:\n"
      local i=
      for i in "${!matches[@]}"; do
        printf "$(($i+1))) ${matches[$i]}\n"
      done
    fi

    if [[ -n "${package_name}" ]] && [[ -e "${package_dir}/${package}" ]]; then
      echo ""
      warning "About to overwrite '${package_dir}/${package}'"
    fi
    echo ""

    if [[ -n "${package_name}" ]] && prompt_confirm "${COLOR_YELLOW}Are you ok with these? (y/N):${COLOR_NC} "; then
      break
    else
      if ! prompt_confirm "${COLOR_YELLOW}Start over? (y/N):${COLOR_NC} "; then
        return $BASH_SYS_EX_CANTCREAT
      fi
      package=""
      package_name=""
      package_manager=""
      author=""
      dependencies=""
      executable_name=""
      output_dir=""
      execute=""
      update=""
      args=""
      echo ""
    fi
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
  ${update:-false}              && ez_gen_args+=" -u"
  ${execute:-false}             && ez_gen_args+=" -e"
  ! ${VERBOSE}                  && ez_gen_args+=" -q"
  ${DEBUG}                      && ez_gen_args+=" -x"

  ${EZ_DEP_EZ_GEN} -D "${package_dir}" -y ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


function generate_package_pre() {
  local package_dir=""

  OPTIND=1
  while getopts "D:" opt; do
    case ${opt} in
      D)
        package_dir="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  resolve_package_dir

  local package="${1##*#}"
  local package_name="${package%.*}"
  local package_manager="$([[ "${package##*.}" != "${package}" ]] && echo "${package##*.}" || echo 'null')"
  [[ -z "${package_dir}" ]] && package_dir="${LOCAL_PACKAGE_DIR}"

  local update=false
  local execute=false
  local args=""
  local indent="  "
  local res=0
  local matches=()

  echo -e "Generating for '${package}.pre' package..."
  echo -e "\n${indent}${COLOR_HI_BLACK}All optional. Press [enter] to skip.${COLOR_NC}\n"

  while true; do
    prompt_input package_name "${indent}Package name: "; package="${package_name}"
    prompt_package_manager package_manager "${indent}Package manager: "
    echo ""

    matches=(
    $(find "${package_dir}" -type f \
      ! -name "${package_name}*.post" \
      -name "${package_name}?${package_manager}.pre")
    )

    if [[ -n "${matches+x}" ]]; then
      echo -e "\nSimilar package(s) found:\n"
      local i=
      for i in "${!matches[@]}"; do
        printf "$(($i+1))) ${matches[$i]}\n"
      done
    fi

    if [[ -n "${package_name}" ]] && [[ -e "${package_dir}/${package}.pre" ]]; then
      echo ""
      warning "About to overwrite '${package_dir}/${package}.pre'"
    fi
    echo ""

    if [[ -n "${package_name}" ]] && prompt_confirm "${COLOR_YELLOW}Are you ok with these? (y/N):${COLOR_NC} "; then
      break
    else
      if ! prompt_confirm "${COLOR_YELLOW}Start over? (y/N):${COLOR_NC} "; then
        return $BASH_SYS_EX_CANTCREAT
      fi
      package=""
      package_name=""
      package_manager=""
      echo ""
    fi
  done

  # Escape whitespaces
  local ez_gen_args=
  [[ -n "${package_name}" ]]    && ez_gen_args+=" -n ${package_name// /\\ }"
  [[ -n "${package_manager}" ]] && ez_gen_args+=" -m ${package_manager// /\\ }"
  ! ${VERBOSE}                  && ez_gen_args+=" -q"
  ${DEBUG}                      && ez_gen_args+=" -x"

  ${EZ_DEP_EZ_GEN} -D "${package_dir}" -pyS ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


function generate_package_post() {
  local package_dir=""

  OPTIND=1
  while getopts "D:" opt; do
    case ${opt} in
      D)
        package_dir="${OPTARG}"
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  resolve_package_dir

  local package="${1##*#}"
  local package_name="${package%.*}"
  local package_manager="$([[ "${package##*.}" != "${package}" ]] && echo "${package##*.}" || echo 'null')"
  [[ -z "${package_dir}" ]] && package_dir="${LOCAL_PACKAGE_DIR}"

  local update=false
  local execute=false
  local args=""
  local indent="  "
  local res=0
  local matches=()

  echo -e "Generating for '${package}.post' package..."
  echo -e "\n${indent}${COLOR_HI_BLACK}All optional. Press [enter] to skip.${COLOR_NC}\n"

  while true; do
    prompt_input package_name "${indent}Package name: "; package="${package_name}"
    prompt_package_manager package_manager "${indent}Package manager: "
    echo ""

    matches=(
    $(find "${package_dir}" -type f \
      ! -name "${package_name}*.pre" \
      -name "${package_name}?${package_manager}.post")
    )

    if [[ -n "${matches+x}" ]]; then
      echo -e "\nSimilar package(s) found:\n"
      local i=
      for i in "${!matches[@]}"; do
        printf "$(($i+1))) ${matches[$i]}\n"
      done
    fi

    if [[ -n "${package_name}" ]] && [[ -e "${package_dir}/${package}.post" ]]; then
      echo ""
      warning "About to overwrite '${package_dir}/${package}.post'"
    fi
    echo ""

    if [[ -n "${package_name}" ]] && prompt_confirm "${COLOR_YELLOW}Are you ok with these? (y/N):${COLOR_NC} "; then
      break
    else
      if ! prompt_confirm "${COLOR_YELLOW}Start over? (y/N):${COLOR_NC} "; then
        return $BASH_SYS_EX_CANTCREAT
      fi
      package=""
      package_name=""
      package_manager=""
      echo ""
    fi
  done

  # Escape whitespaces
  local ez_gen_args=
  [[ -n "${package_name}" ]]    && ez_gen_args+=" -n ${package_name// /\\ }"
  [[ -n "${package_manager}" ]] && ez_gen_args+=" -m ${package_manager// /\\ }"
  ! ${VERBOSE}                  && ez_gen_args+=" -q"
  ${DEBUG}                      && ez_gen_args+=" -x"

  ${EZ_DEP_EZ_GEN} -D "${package_dir}" -PyS ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


prompt_input() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _input_var_name="${1}"
  local _message="${2:-'Enter input: '}"
  eval "local _input=\${${_input_var_name}}"

  if [[ -z "${_input}" ]]; then
    get_user_input _input "${_message}"
  else
    echo -e "${_message}${_input}"
  fi
  eval "${_input_var_name}=${_input}"
}


function prompt_package_manager() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _package_manager_var_name="${1}"
  local _message="${2:-'Package manager: '}"
  eval "local _package_manager=\${$1}"

  if [[ -z "${_package_manager}" ]]; then
    while ! is_package_manager_supported "${_package_manager}"; do
      get_user_input _package_manager "${_message}"
      [[ -z "${_package_manager}" ]] && break
    done
  else
    echo -e "${_message}${_package_manager}"
  fi
  eval "${_package_manager_var_name}=${_package_manager}"
}


function prompt_dir() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _dir_var_name="${1}"
  local _message="${2:-'Directory: '}"
  eval "local _dir=\${$1}"

  if [[ -z "${_dir}" ]]; then
    get_user_input _dir "${_message}" 
  else
    echo -e "${_message}${_dir}"
  fi
  eval "${_dir_var_name}=${_dir}"
}


function prompt_boolean() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _boolean_var_name="${1}"
  local _message="${2:-'Boolean (default=false): '}"
  eval "local _boolean=\${$1}"

  while [[ "${_boolean}" != 'true' ]] && [[ "${_boolean}" != 'false' ]]; do
    get_user_input _boolean "${_message}"
    if [[ -z "${_boolean}" ]]; then
      _boolean=false
      break
    fi
  done
  eval "${_boolean_var_name}=${_boolean}"
}


prompt_confirm() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _message="${1}"
  local _continue=""

  while ! [[ "${_continue}" =~ ^[YyNn]$ ]]; do
    get_user_input _continue "${_message}"
  done
  if [[ "${_continue}" == 'y' ]] || [[ "${_continue}" == 'y' ]]; then
    return $BASH_EX_OK
  fi
  return $BASH_EX_GENERAL
}


function is_package_manager_supported() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local _package_manager="${1}"

  local _pacman=""
  for _pacman in ${EZ_SUPPORTED_PACKAGE_MANAGER}; do
    if [ "${_package_manager}" = "${_pacman}" ]; then
      return $BASH_EX_OK
    fi
  done

  return $BASH_EZ_EX_PACMAN_NOTFOUND
}

