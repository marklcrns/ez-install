set -o pipefail
set -o nounset

# Header guard
[[ -z "${INSTALL_INIT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INIT_SH_INCLUDED=1 \
  || return 0


source "$(dirname -- $(realpath -- "${BASH_SOURCE[0]}"))/../.ez-installrc"
source "${EZ_INSTALL_HOME}/common/include.sh"

include "${EZ_INSTALL_HOME}/install/const.sh"
include "${EZ_INSTALL_HOME}/install/common.sh"
include "${EZ_INSTALL_HOME}/install/install.sh"
include "${EZ_INSTALL_HOME}/install/pac-install.sh"
include "${EZ_INSTALL_HOME}/common/sys.sh"

[[ -z "${RUN_AS_SU+x}" ]] && RUN_AS_SU=false

function handle_package_args() {
  OPTIND=1
  while getopts "e:f:o:s:" opt; do
    case ${opt} in
      o)
        output_path="${OPTARG}"
        ;;
      e)
        execute=${OPTARG}
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
}
