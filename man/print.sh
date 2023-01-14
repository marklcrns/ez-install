#!/usr/bin/env bash

if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
	echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2
	echo "Use this script only by sourcing it." >&2
	exit 1
fi

# Header guard
[[ -z "${MAN_PRINT_SH_INCLUDED+x}" ]] &&
	readonly MAN_PRINT_SH_INCLUDED=1 ||
	return 0

function print_page() {
	eval "cat <<EOF
$(<${1})
EOF
" 2>/dev/null
}
