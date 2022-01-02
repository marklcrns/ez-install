set -o pipefail
set -o nounset

# Header guard
[[ -z "${INSTALL_INIT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INIT_SH_INCLUDED=1 \
  || return 0


source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/.ez-installrc"
include "${HOME}/.ez-installrc"
include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"
include "${EZ_INSTALL_HOME}/install/install.sh"
include "${EZ_INSTALL_HOME}/install/pac-install.sh"
include "${EZ_INSTALL_HOME}/common/sys.sh"

[[ -z "${RUN_AS_SU+x}" ]]       && RUN_AS_SU=false
[[ -z "${SKIP_CONFIRM+x}" ]]    && SKIP_CONFIRM=false
[[ -z "${VERBOSE+x}" ]]         && VERBOSE=false
[[ -z "${DEBUG+x}" ]]           && DEBUG=false
[[ -z "${LOG_DEBUG_LEVEL+x}" ]] && LOG_DEBUG_LEVEL=3

function handle_package_args() {
  OPTIND=1
  while getopts "S:" opt; do
    case ${opt} in
      S)
        as_root=${OPTARG}
        ;;
    esac
  done
  shift "$((OPTIND-1))"
}
