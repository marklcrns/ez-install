source "${BASH_SOURCE%/*}/common.sh"

# Set up if executed instead of sourcing
if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  source "${BASH_SOURCE%/*}/../common/common.sh"
  script_vars
  handle_args "${@}"
fi

