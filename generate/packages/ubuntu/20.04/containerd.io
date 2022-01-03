#!/usr/bin/env bash

########################################################### PACKAGE METADATA ###
# ---
# package: containerd.io
# executable: containerd.io
# package-manager: 
# dependency: 
# author: 
# date: 2022-01-02
# ---
################################################################################

source "$(realpath -- ${BASH_SOURCE%/*}/__init__.sh)"

############################################################## START INSTALL ###

# containerd.io installation template generated by ez-install

function _main() {
  local as_root=false
  handle_package_args ${@}

  # Package name defaults to filename
  local args=""
  local package="containerd.io"
  local package_name="containerd.io"
  local executable_name="containerd.io"
  local package_manager=""
  local destination=""
  local res=0

  # Get system package manager
  [[ -z "${package_manager}" ]] && get_sys_package_manager package_manager

  # Install package
  install -a "${args}" \
          -c "${executable_name}" \
          -n "${package_name}" \
          -u false \
          -S "${as_root}" -- \
          "${package_manager}" \
          "${package}" \
          "${destination}"

  res=$?
  return ${res}
}

################################################################ END INSTALL ###

res=0
_main "${@}"
res=$?

return $res
# SOURCED BY `pac-install()`, DO NOT USE `exit`. USE `return` INSTEAD
