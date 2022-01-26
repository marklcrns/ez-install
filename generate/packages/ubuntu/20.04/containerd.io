#!/usr/bin/env bash

############################################ PACKAGE METADATA (DO NOT TOUCH) ###
# ---
# package: containerd.io
# executable: 
# package-manager: 
# dependency: 
# author: 
# date: 2022-01-25
# ---
################################################################################

source "${EZ_INSTALL_HOME}/install/init.sh"

#################################################### INSTALLATION (TOUCH OK) ###

# containerd.io installation template generated by ez-install

function _main() {
  local forced=false
  local as_root=false
  local execute=false
  handle_package_args ${@}

  # Package name defaults to filename
  local args=""
  local package="containerd.io"
  local package_name="containerd.io"
  local executable_name=""
  local package_manager=""
  local destination=""
  local res=0

  # Get system package manager
  [[ -z "${package_manager}" ]] && get_sys_package_manager package_manager

  # START INSTALLATION

  # function install()
  #
  # Flags (optional):
  #
  #   -a    Args for package manager.
  #   -c    Executable name if applicable (default=this).
  #   -n    Name of the package to install by the package manager (default=this).
  #   -u    Pull updates from package manager repository before installation (e.g., apt update).
  #   -S    Run package installation with root (sudo) privileges (default=false).
  #
  # Arguments:
  #
  #   $1    Installing package manager.
  #          Supported:
  #            - apt, apt-add
  #            - pkg
  #            - npm
  #            - pip (executes default pip version), pip2, pip3
  #            - curl
  #            - wget
  #            - git
  #            - local (independent local installation only for reporting and triggering
  #              pre and post installation processes).
  #   $2    Package to install.
  #   $3    Output directory for curl, wget, and git (optional, default=$HOME/Downloads).
  #
  # Pre installation:
  #
  #   install() will automatically try to source containerd.pre first then containerd.<package_manager>.pre
  #   from either $LOCAL_PACKAGE_DIR and $PACKAGE_DIR before package installation.
  #   $LOCAL_PACKAGE_DIR priority. Best place to download dependencies or executing
  #   pre installation commands.
  #
  # Post installation:
  #
  #   install() will automatically try to source containerd.post first then containerd.<package_manager>.post
  #   from either $LOCAL_PACKAGE_DIR and $PACKAGE_DIR after package installation.
  #   $LOCAL_PACKAGE_DIR priority. Best place for cleaning up files or executing
  #   post installation commands.
  #
  # Pro tip: keep this package as is and add additional commands in the package's
  #          '.pre' and '.post' scripts

  install -a "${args}" \
          -c "${executable_name}" \
          -n "${package_name}" \
          -m "${package_manager}" \
          -o "${destination}" \
          -f ${forced} \
          -e ${execute} \
          -S ${as_root} \
          -u false \
          -- \
          "${package}"

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
