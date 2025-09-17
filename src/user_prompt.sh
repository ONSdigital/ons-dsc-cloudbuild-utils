###############################################################################
# confirm_with_prompt
#-------------------------------------------------------------------------------
# Displays a multi-line prompt and waits for user confirmation ('y' or 'Y').
# Returns 0 if confirmed, 1 otherwise.
#
# Args:
#   $1...: Lines of the prompt to display (each as a separate argument).
#
# Returns:
#   0 if user confirms, 1 if cancelled.
confirm_with_prompt() {
  for line in "$@"; do
    info_msg "$line"
  done
  read confirm
  confirm_char="$(echo "$confirm" | cut -c1 | tr '[:upper:]' '[:lower:]')"
  if [ "$confirm_char" != "y" ]; then
    error_msg "Operation cancelled by user."
    return 1
  fi
  return 0
}