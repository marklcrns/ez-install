#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${PACKAGE_PACKAGE_INSTALL_SH_INCLUDED+x}" ]] \
  && readonly PACKAGE_PACKAGE_INSTALL_SH_INCLUDED=1 \
  || return 0

source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"
include "${EZ_INSTALL_HOME}/install/utils/pac-logger.sh"
include "${EZ_INSTALL_HOME}/install/utils/progress-bar.sh"


# TODO: Append package install status onto progress bar
function pac_batch_json_install() {
  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local packages=( "${@}" )
  local width="${#packages[@]}"

  local root_package=""
  local root_package_name=""
  local root_package_manager=""

  local res=0
  local idx=0
  for package in ${packages[@]}; do
    root_package="$(echo "${package}" | ${EZ_DEP_JQ} -crM ".package")"
    root_package_name="$(echo "${root_package}" | ${EZ_DEP_JQ} -crM ".name")"

    prog_bar "$(("${idx}*100/${width}"))"
    echo "- ${root_package_name}"
    ((++idx))

    pac_json_install "${root_package}"
    res=$?

    # Report root package failure
    if [[ $res -ne $BASH_EX_OK ]]; then
      if [[ "${root_package_name##*.}" != "${root_package_name}" ]]; then
        root_package_manager="${root_package_name##*.}"
        capitalize root_package_manager
      else
        root_package_manager='N/A'
      fi
      if [[ $res -eq $BASH_EZ_EX_DEP_FAILED ]]; then
        pac_log_skip $res "${root_package_manager}" "${root_package_name%.*}" "'${root_package_name}' dependency failed"
      fi
    fi
  done
  prog_bar "$(("${idx}*100/${width}"))"
  echo ""
}


function pac_json_install() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1}"
  has_json_prop_val "${package}" && return $BASH_EX_OK

  local package_path="$(echo ${package} | ${EZ_DEP_JQ} -crM ".path")"
  has_json_prop_val "${package_path}" && return $BASH_EX_OK

  local package_name="$(echo ${package} | ${EZ_DEP_JQ} -crM ".name")"
  local as_root=$(echo ${package} | ${EZ_DEP_JQ} -crM ".as_root")
  local force=$(echo ${package} | ${EZ_DEP_JQ} -crM ".force")
  local allow_dep_fail=$(echo ${package} | ${EZ_DEP_JQ} -crM ".allow_dep_fail")

  local res=
  local sub_package=
  local dependencies=
  local dependencies_ct="$(echo ${package} | ${EZ_DEP_JQ} -crM ".dependencies | length")"

  if [[ ${dependencies_ct} -gt 1 ]]; then
    # Recursive dependency install
    for ((_i=0; _i<${dependencies_ct}; ++_i)); do
      dependencies="$(echo ${package} | ${EZ_DEP_JQ} -crM ".dependencies[${_i}]")"
      if ! has_json_prop_val "${dependencies}"; then
        sub_package="$(echo "${dependencies}" | ${EZ_DEP_JQ} -crM ".package")"
        pac_json_install ${sub_package}
        res=$?
        ! $allow_dep_fail && [[ $res -ne $BASH_EX_OK ]] && return $BASH_EZ_EX_DEP_FAILED # Abort immediately
      fi
    done
  else
    dependencies="$(echo ${package} | ${EZ_DEP_JQ} -crM ".dependencies")"
    if ! has_json_prop_val "${dependencies}"; then
      sub_package="$(echo "${dependencies}" | ${EZ_DEP_JQ} -crM ".package")"
      pac_json_install ${sub_package}
      res=$?
      ! $allow_dep_fail && [[ $res -ne $BASH_EX_OK ]] && return $BASH_EZ_EX_DEP_FAILED # Abort immediately
    fi
  fi

  # Skip dependency installation
  pac_install -f $force -r false -s $as_root -- "${package_name}" "${package_path}"
  res=$?
  return $res
}


function pac_install() {
  local force=${FORCE}
  local recursive=${RECURSIVE}
  local as_root=${AS_ROOT}
  local allow_dep_fail=${ALLOW_DEP_FAIL}

  OPTIND=1
  while getopts "f:r:s:w:" opt; do
    case ${opt} in
      f)
        force=${OPTARG}
        ;;
      r)
        recursive=${OPTARG}
        ;;
      s)
        as_root=${OPTARG}
        ;;
      w)
        allow_dep_fail=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  parse_inline_opts "${1}"
  local package="${1%#*}"     # Strip #opts
  local package_path="${2:-}"

  if [[ -z "${package_path}" ]]; then
    local res=0
    local package_path="${package}"
    fetch_package package_path
    res=$?

    if [[ $res -ne $BASH_EX_OK ]]; then
      local selected=
      if select_package "${package}" selected; then
        if [[ -z "${selected}" ]]; then
          warning "Package '${package}' skipped!"
          return $BASH_EZ_EX_PAC_NOTFOUND
        fi
        package_path="${selected}"
      else
        res=$?
        pac_log_failed $res 'N/A' "${package}" "Package '${package}' not found"
        return $res
      fi
    fi
  fi

  if [[ "${package_path}" == "null" ]] || [[ "${package_path}" == "." ]]; then
    pac_log_skip 'N/A' "${package}"
    return $BASH_EX_OK
  elif [[ ! -f "${package_path}" ]]; then
    pac_log_failed $BASH_EZ_EX_PAC_NOTFOUND 'N/A' "${package}" "Package '${package}' not found"
    return $BASH_EZ_EX_PAC_NOTFOUND
  fi

  # Install dependencies
  if $recursive; then
    local tmp="$(${EZ_INSTALL_METADATA_PARSER} "dependency" "${package_path}")"
    local -a package_dependencies=( ${tmp//,/ } )

    for dependency in ${package_dependencies[@]}; do
      info "Installing ${package} dependency -- ${dependency}"
      pac_install -f $force -r $recursive -s $as_root -w $allow_dep_fail -- "${dependency}"
      local res=$?
      ! $allow_dep_fail && [[ $res -ne $BASH_EX_OK ]] && return $res # Abort immediately
    done
  fi

  info "Installing '${package}' from '${package_path}'"
  source "${package_path}" -f $force -s $as_root
  res=$?
  return $res
}


function pac_batch_install() {
  local force=${FORCE}
  local recursive=${RECURSIVE}
  local as_root=${AS_ROOT}
  local allow_dep_fail=${ALLOW_DEP_FAIL}

  OPTIND=1
  while getopts "f:r:s:w:" opt; do
    case ${opt} in
      f)
        force=${OPTARG}
        ;;
      r)
        recursive=${OPTARG}
        ;;
      s)
        as_root=${OPTARG}
        ;;
      w)
        allow_dep_fail=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local packages=( "${@}" )
  local width="${#packages[@]}"

  local idx=1
  for package in ${packages[@]}; do
    pac_install -f $force -r $recursive -s $as_root -w $allow_dep_fail -- "${package}"
    prog_bar "$(("${idx}*100/${width}"))"
    echo "- ${package}"
    ((++idx))
  done
}


# TODO: Deprecated
function pac_deploy_init() {
  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local target="${1}"
  local from="${EZ_INSTALL_HOME}/install/init.sh"

  if [[ ! -e "${from}" ]]; then
    error "Missing '${from}'"
    return $BASH_EZ_EX_DEP_NOTFOUND
  fi

  if [[ -f "${target}" ]]; then
    warning "Replacing '${target}' with '${from}' symlink"
    execlog "rm ${target}"
  elif [[ -d "${target}" ]]; then
    error "Target '${target}' is a directory!"
    return $BASH_SYS_EX_CANTCREAT
  elif [[ ! -d "$(dirname -- "${target}")" ]]; then
    execlog "mkdir -p '$(dirname -- "${target}")'"
  fi

  if execlog "ln -sT '${from}' '${target}'"; then
    ok "${from} -> ${target} symlink created"
  else
    error "${from} -> ${target} symlink failed"
    return $BASH_SYS_EX_CANTCREAT
  fi
}


function pac_pre_install() {
  local force=false
  local as_root=false
  local destination=""

  OPTIND=1
  while getopts "f:o:s:" opt; do
    case ${opt} in
      o)
        destination="${OPTARG}"
        ;;
      f)
        force=${OPTARG}
        ;;
      s)
        as_root=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1}"
  local package_manager="${2:-N/A}"

  local res=0
  local package_pre_path=""

  [[ -z "${destination}" ]] && destination="${EZ_DOWNLOADS_DIR}"

  # Pre process global
  package_pre_path="${package}.pre"
  fetch_package package_pre_path
  if [[ $? -eq $BASH_EX_OK ]]; then
    info "Executing ${package_pre_path}..."
    # Do not exit on unbound variables
    set -u
    source "${package_pre_path}" -o "${destination}" -f $force -s $as_root
    res=$?
    set +u

    if [[ $res -ne $BASH_EX_OK ]]; then
      pac_log_failed $res "${package_manager}" "${package}.pre"
      return $res
    fi
    pac_log_success "${package_manager}" "${package}.pre"
  fi

    # Pre process local
  if [[ "${package_manager}" != 'N/A' ]]; then
    local package_manager_lower="${package_manager}"
    capitalize package_manager
    to_lower package_manager_lower

    package_pre_path="${package}.${package_manager_lower}.pre"
    fetch_package package_pre_path
    if [[ $? -eq $BASH_EX_OK ]]; then
      info "Executing ${package_pre_path}..."
      # Do not exit on unbound variables
      set -u
      source "${package_pre_path}" -o "${destination}" -f $force -s $as_root
      res=$?
      set +u

      if [[ $res -ne $BASH_EX_OK ]]; then
        pac_log_failed $res "${package_manager}" "${package}.${package_manager_lower}.pre"
        return $res
      fi
      pac_log_success "${package_manager}" "${package}.${package_manager_lower}.pre"
    fi
  fi
}


function pac_post_install() {
  local force=false
  local as_root=false
  local destination=""

  OPTIND=1
  while getopts "f:o:s:" opt; do
    case ${opt} in
      o)
        destination="${OPTARG}"
        ;;
      f)
        force=${OPTARG}
        ;;
      s)
        as_root=${OPTARG}
        ;;
      *)
        error "Invalid flag option(s)"
        exit $BASH_SYS_EX_USAGE
    esac
  done
  shift "$((OPTIND-1))"

  if [[ -z "${@+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  local package="${1}"
  local package_manager="${2:-N/A}"

  local res=0
  local package_post_path=""

  [[ -z "${destination}" ]] && destination="${EZ_DOWNLOADS_DIR}"

  # Post process global
  package_post_path="${package}.post"
  fetch_package package_post_path
  if [[ $? -eq $BASH_EX_OK ]]; then
    info "Executing ${package_post_path}..."
    # Do not exit on unbound variables
    set -u
    source "${package_post_path}" -o "${destination}" -f $force -s $as_root
    res=$?
    set +u

    if [[ $res -ne $BASH_EX_OK ]]; then
      pac_log_failed $res "${package_manager}" "${package}.post"
      return $res
    fi
    pac_log_success "${package_manager}" "${package}.post"
  fi

    # Post process local
  if [[ "${package_manager}" != 'N/A' ]]; then
    local package_manager_lower="${package_manager}"
    capitalize package_manager
    to_lower package_manager_lower

    package_post_path="${package}.${package_manager_lower}.post"
    fetch_package package_post_path
    if [[ $? -eq $BASH_EX_OK ]]; then
      info "Executing ${package_post_path}..."
      # Do not exit on unbound variables
      set -u
      source "${package_post_path}" -o "${destination}" -f $force -s $as_root
      res=$?
      set +u

      if [[ $res -ne $BASH_EX_OK ]]; then
        pac_log_failed $res "${package_manager}" "${package}.${package_manager_lower}.post"
        return $res
      fi
      pac_log_success "${package_manager}" "${package}.${package_manager_lower}.post"
    fi
  fi
}


function has_json_prop_val() {
  if [[ -z "${1+x}" ]]; then
    error "${BASH_SYS_MSG_USAGE_MISSARG}"
    return $BASH_SYS_EX_USAGE
  fi

  [[ "${package}" == 'null' ]] || [[ "${package}" == "." ]] \
    && return $BASH_EX_OK \
    || return $BASH_EX_GENERAL
}
