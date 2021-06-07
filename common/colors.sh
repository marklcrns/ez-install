#!/usr/bin/env bash

################################################################################
# Predefined ANSI color codes for colorful output strings.
#
# WARNING: This is not an executable script. This script is meant to be used as
# a utility by sourcing this script for efficient bash script writing.
#
################################################################################
# Author : Mark Lucernas <https://github.com/marklcrns>
# Date   : 2020-08-13
################################################################################


if [ "${0##*/}" == "${BASH_SOURCE[0]##*/}" ]; then
  echo "WARNING: $(realpath -s $0) is not meant to be executed directly!" >&2;
  echo "Use this script only by sourcing it." >&2;
  exit 1
fi

# Header guard
[[ -z "${COMMON_COLORS_SH_INCLUDED+x}" ]] \
  && readonly COMMON_COLORS_SH_INCLUDED=1 \
  || return 0


# Regular Colors
COLOR_BLACK='\033[0;30m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_PURPLE='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[0;37m'

# Bold
COLOR_BO_BLACK='\033[1;30m'
COLOR_BO_RED='\033[1;31m'
COLOR_BO_GREEN='\033[1;32m'
COLOR_BO_YELLOW='\033[1;33m'
COLOR_BO_BLUE='\033[1;34m'
COLOR_BO_PURPLE='\033[1;35m'
COLOR_BO_CYAN='\033[1;36m'
COLOR_BO_WHITE='\033[1;37m'
COLOR_BO_NC='\033[1m' # Bold default color

# Underline
COLOR_UL_BLACK='\033[4;30m'
COLOR_UL_RED='\033[4;31m'
COLOR_UL_GREEN='\033[4;32m'
COLOR_UL_YELLOW='\033[4;33m'
COLOR_UL_BLUE='\033[4;34m'
COLOR_UL_PURPLE='\033[4;35m'
COLOR_UL_CYAN='\033[4;36m'
COLOR_UL_WHITE='\033[4;37m'
COLOR_UL_NC='\033[4m' # Underlined default color

# Background
COLOR_BG_BLACK='\033[40m'
COLOR_BG_RED='\033[41m'
COLOR_BG_GREEN='\033[42m'
COLOR_BG_YELLOW='\033[43m'
COLOR_BG_BLUE='\033[44m'
COLOR_BG_PURPLE='\033[45m'
COLOR_BG_CYAN='\033[46m'
COLOR_BG_WHITE='\033[47m'
COLOR_BG_EXPAND='\033[K' # Expand any background color horizontally

# High Intensty
COLOR_HI_BLACK='\033[0;90m'
COLOR_HI_RED='\033[0;91m'
COLOR_HI_GREEN='\033[0;92m'
COLOR_HI_YELLOW='\033[0;93m'
COLOR_HI_BLUE='\033[0;94m'
COLOR_HI_PURPLE='\033[0;95m'
COLOR_HI_CYAN='\033[0;96m'
COLOR_HI_WHITE='\033[0;97m'

# Bold High Intensty
COLOR_BO_HI_BLACK='\033[1;90m'
COLOR_BO_HI_RED='\033[1;91m'
COLOR_BO_HI_GREEN='\033[1;92m'
COLOR_BO_HI_YELLOW='\033[1;93m'
COLOR_BO_HI_BLUE='\033[1;94m'
COLOR_BO_HI_PURPLE='\033[1;95m'
COLOR_BO_HI_CYAN='\033[1;96m'
COLOR_BO_HI_WHITE='\033[1;97m'

# High Intensty backgrounds
COLOR_BG_HI_BLACK='\033[0;100m'
COLOR_BG_HI_RED='\033[0;101m'
COLOR_BG_HI_GREEN='\033[0;102m'
COLOR_BG_HI_YELLOW='\033[0;103m'
COLOR_BG_HI_BLUE='\033[0;104m'
COLOR_BG_HI_PURPLE='\033[0;105m'
COLOR_BG_HI_CYAN='\033[0;106m'
COLOR_BG_HI_WHITE='\033[0;107m'

# Reset to Default
COLOR_NC='\033[0m'

