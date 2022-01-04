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


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/common/colors.sh"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/utils/actions.sh"


function generate() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1}"
  local ez_gen="${EZ_INSTALL_HOME}/generate/ez-gen"
  local supported_manager=(
    'apt' 'apt-add'
    'pkg'
    'npm'
    'pip' 'pip2' 'pip3'
    'curl'
    'wget'
    'git'
    'local'
  )

  local author=""
  local dependencies=""
  local executable_name=""
  local package_name=""
  local package_manager=""
  local output_dir=""
  local args=""
  local res=0

  echo -e "Generating for '${package}' package..."
  get_user_input "  Author (optional): " author
  get_user_input "  Dependencies (optional, use ',' separator): " dependencies
  get_user_input "  Executable name (optional): " executable_name
  get_user_input "  Package name (optional): " package_name
  get_user_input "  Package manager: " package_manager
  get_user_input "  Output directory (optional): " output_dir
  get_user_input "  Package manager args (optional): " args

  echo "author: ${author}"
  echo "dependencies: ${dependencies}"
  echo "executable name: ${executable_name}"
  echo "package name: ${package_name}"
  echo "package manager: ${package_manager}"
  echo "output directory: ${output_dir}"
  echo "args: ${args}"

  local ez_gen_args=
  [[ -n "${author}" ]]          && ez_gen_args+="-A '${author}'"
  [[ -n "${dependencies}" ]]    && ez_gen_args+="-d '${dependencies}'"
  [[ -n "${executable_name}" ]] && ez_gen_args+="-c '${executable_name}'"
  [[ -n "${package_name}" ]]    && ez_gen_args+="-n '${package_name}'"
  [[ -n "${package_manager}" ]] && ez_gen_args+="-m '${package_manager}'"
  [[ -n "${output_dir}" ]]      && ez_gen_args+="-o '${output_dir}'"
  [[ -n "${args}" ]]            && ez_gen_args+="-a '${args}'"
  [[ ${VERBOSE+x} ]]            && ez_gen_args+="--verbose "
  [[ ${DEBUG+x} ]]              && ez_gen_args+="--debug "

  $ez_gen -y ${ez_gen_args} -- "${package}"

  res=$?
  return $res
}


function get_user_input() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  if [[ -z "${2+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi


  echo -ne "${1}"
  read ${2}
}
