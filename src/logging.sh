###############################################################################
# logging.sh - Utility functions for standardized script messaging
#-------------------------------------------------------------------------------
# Provides functions for printing info, warning, error, success, and debug
# messages in a consistent format across scripts in this repo.
#
# Usage:
#   source logging.sh
#   info_msg "This is an info message."
#   error_msg "This is an error message."
#
# Used by all major scripts to improve readability and maintainability.
###############################################################################


RED=$'\033[0;31m'
NC=$'\033[0m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
BOLD=$'\033[1m'
UNBOLD=$'\033[22m'
MAGENTA=$'\033[0;35m'


###############################################################################
# update_msg
#-------------------------------------------------------------------------------
# Prints a timestamped message to the specified output stream, with optional color.
#
# Args:
#   message: The message to print.
#   color: (Optional) ANSI color code. Defaults to NC (no color).
#   out_stream: (Optional) Output stream (1 for stdout, 2 for stderr). Defaults to 1.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
update_msg() {
  local message="$1"
  local color="$2"
  local out_stream="$3"
  local type="$4"
  # Use echo -e to interpret newlines in message
  local timestamp="$(date +'%Y-%m-%dT%H:%M:%S%z')"
  if [[ "$message" == *$'\n'* ]]; then
    # Multi-line message: print header, then message
    echo -e "${color}[${timestamp}] ${BOLD}[${type}]${UNBOLD}:${NC}" >&$out_stream
    echo -e "$message" >&$out_stream
  else
    echo -e "${color}[${timestamp}] ${BOLD}[${type}]${UNBOLD}: $message${NC}" >&$out_stream
  fi
}

###############################################################################
# info_msg
#-------------------------------------------------------------------------------
# Prints a timestamped info message in default color to stdout.
#
# Args:
#   $1: The info message to print.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
info_msg() {
  update_msg "$*" "$NC" 1 "INFO"
}

###############################################################################
# success_msg
#-------------------------------------------------------------------------------
# Prints a timestamped success message in green to stdout.
#
# Args:
#   $1: The success message to print.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
success_msg() {
  update_msg "$*" "$GREEN" 1 "SUCCESS"
}

###############################################################################
# error_msg
#-------------------------------------------------------------------------------
# Prints a timestamped error message in red to stderr.
#
# Args:
#   $1: The error message to print.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
error_msg() {
  update_msg "$*" "$RED" 2 "ERROR"
}

###############################################################################
# warning_msg
#-------------------------------------------------------------------------------
# Prints a timestamped warning message in yellow to stderr.
#
# Args:
#   $1: The warning message to print.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
warning_msg() {
  update_msg "$*" "$YELLOW" 2 "WARNING"
}

###############################################################################
# debug_msg
#-------------------------------------------------------------------------------
# Prints a timestamped debug message in blue to stdout
#
# Args:
#   $1: The debug message to print.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
debug_msg() {
  update_msg "$*" "$BLUE" 1 "DEBUG"
}

###############################################################################
# confirm_msg
#-------------------------------------------------------------------------------
# Prints a timestamped confirmation message in magenta to stdout
#
# Args:
#   $1: The confirmation message to print.
#
# Returns:
#   None
#-------------------------------------------------------------------------------
confirm_msg() {
  update_msg "$*" "$MAGENTA" 1 "CONFIRM"
}
