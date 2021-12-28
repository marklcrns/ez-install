set -o pipefail
set -o nounset

# Header guard
[[ -z "${INSTALL_INIT_SH_INCLUDED+x}" ]] \
  && readonly INSTALL_INIT_SH_INCLUDED=1 \
  || return 0

# Symlink safe
INIT_PATH="$(realpath -- "${BASH_SOURCE[0]}")"
INIT_DIR="$(cd -P "$(dirname "${INIT_PATH}")" >/dev/null 2>&1 && pwd)"

source "${INIT_DIR}/../common/include.sh"

include "${INIT_DIR}/../.ez-installrc"
include "${HOME}/.ez-installrc"
include "${INIT_DIR}/common.sh"
include "${INIT_DIR}/install.sh"
include "${INIT_DIR}/pac-install.sh"
include "${INIT_DIR}/../common/sys.sh"

[[ -z "${SKIP_CONFIRM+x}" ]]    && SKIP_CONFIRM=false
[[ -z "${VERBOSE+x}" ]]         && VERBOSE=false
[[ -z "${DEBUG+x}" ]]           && DEBUG=false
[[ -z "${LOG_DEBUG_LEVEL+x}" ]] && LOG_DEBUG_LEVEL=3

unset INIT_PATH
unset INIT_DIR
