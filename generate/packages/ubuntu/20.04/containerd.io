#!/usr/bin/env bash

############################################ PACKAGE METADATA (DO NOT TOUCH) ###
# ---
# package: containerd.io
# executable: containerd.io
# package-manager: 
# dependency: 
# author: 
# date: 2022-01-04
# ---
################################################################################

source "${EZ_INSTALL_HOME}/install/init.sh"

#################################################### INSTALLATION (TOUCH OK) ###

# containerd.io installation template generated by ez-install

function _main() {
  local as_root=false
  local execute=false
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

  # START INSTALLATION

  # install()
  #
  # Pro tip: keep this package as is and add additional commands in the package's
  #          '.pre' and '.post' scripts
  #
  # Pre installation:
  #
  #   install() will automatically try to source containerd.pre first then containerd.<package-manager>.pre
  #   from either $LOCAL_PACKAGE_DIR and $PACKAGE_DIR before package installation.
  #   $LOCAL_PACKAGE_DIR preferred. Best place to download dependencies or executing
  #   pre installation commands.
  #
  # Post installation:
  #
  #   install() will automatically try to source containerd.post first then containerd.<package-manager>.post
  #   from either $LOCAL_PACKAGE_DIR and $PACKAGE_DIR after package installation.
  #   $LOCAL_PACKAGE_DIR priority. Best place for cleaning up files or executing
  #   post installation commands.
  #
  # Flags (optional):
  #
  #   -a    args for package manager.
  #   -c    executable name if applicable (default=this).
  #   -n    name of the package to install by the package manager (default=this).
  #   -u    pull updates from package manager repository before installation (e.g., apt update).
  #   -S    run package installation with root (sudo) privileges (default=false).
  #
  # Arguments:
  #
  #   $1    installing package manager.
  #         Currently supported:
  #           - apt, apt-add
  #           - pkg
  #           - npm
  #           - pip (executes default pip version), pip2, pip3
  #           - curl
  #           - wget
  #           - git
  #           - local (independent local installation only for reporting and triggering
  #             pre and post installation processes).
  #   $2    package to install.
  #   $3    output directory for curl, wget, and git (optional, default=$HOME/Downloads).

  local install_args=""
  [[ -n "${args}" ]]            && install_args+=" -a ${args}"
  [[ -n "${executable_name}" ]] && install_args+=" -c ${executable_name}"
  [[ -n "${package_name}" ]]    && install_args+=" -n ${package_name}"
  [[ -n "${package_manager}" ]] && install_args+=" -m ${package_manager}"
  [[ -n "${destination}" ]]     && install_args+=" -o ${destination}"

  install ${install_args} -e ${execute} -S ${as_root} -u false -- "${package}"

  # END INSTALLATION

  res=$?
  return ${res}
}

################################################# END INSTALL (DO NOT TOUCH) ###

res=0
_main "${@}"
res=$?

return $res
# Sourced by `pac-install()`, DO NOT USE `exit`. USE `return` INSTEAD
