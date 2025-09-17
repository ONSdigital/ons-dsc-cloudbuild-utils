script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source "$script_dir/logging.sh"

###############################################################################
# validate_arg
#-------------------------------------------------------------------------------
# Validates a script argument against a set of allowed values and prints usage
# guidance if the value is invalid.
#
# Args:
#   --value:      The value to validate.
#   --arg_name:   The name of the argument being validated.
#   --allowed:    Pipe-separated string of allowed values (e.g. "dev|prod").
#   --caller:     The script or command being invoked (for usage output).
#   --arg_map:    Argument usage map (for usage output).
#
# Returns:
#   0 if the value is valid, 1 otherwise.
#
# Raises:
#   Prints an error message and usage guidance if the value is invalid.
###############################################################################
validate_arg() {
    local value=""
    local arg_name=""
    local allowed=""
    local caller=""
    local arg_map=""

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --value=*)
                value="${1#*=}"
                ;;
            --arg_name=*)
                arg_name="${1#*=}"
                ;;
            --allowed=*)
                allowed="${1#*=}"
                ;;
            --caller=*)
                caller="${1#*=}"
                ;;
            --arg_map=*)
                arg_map="${1#*=}"
                ;;
        esac
        shift
    done

    # If value is not allowed, print error and return 1, else return 0
    if [[ ! "$allowed" =~ (^|[|])"$value"($|[|]) ]]; then
        error_msg "==================== ERROR ===================="
        error_msg "[!] Invalid value for argument '$arg_name'"
        error_msg "    You provided: '$value'"
        error_msg "    Allowed values: $allowed"
        error_msg "----------------------------------------------"
        error_msg "Correct Invocation: '$caller $arg_map'"
        error_msg "=============================================="
        error_msg "Tip: Check your input and try again. Refer to the invocation format above."
        return 1
    fi
    return 0
}

validate_regex() {
    local value=""
    local arg_name=""
    local regex=""
    local caller=""
    local arg_map=""

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --value=*)
                value="${1#*=}"
                ;;
            --arg_name=*)
                arg_name="${1#*=}"
                ;;
            --regex=*)
                regex="${1#*=}"
                ;;
            --caller=*)
                caller="${1#*=}"
                ;;
            --arg_map=*)
                arg_map="${1#*=}"
                ;;
        esac
        shift
    done

    # If value does not match regex, print error and return 1, else return 0
    if [[ ! "$value" =~ $regex ]]; then
        error_msg "==================== ERROR ===================="
        error_msg "[!] Invalid format for argument '$arg_name'"
        error_msg "    You provided: '$value'"
        error_msg "    Expected format: $regex"
        error_msg "----------------------------------------------"
        error_msg "Correct Invocation: '$caller $arg_map'"
        error_msg "=============================================="
        error_msg "Tip: Check your input and try again. Refer to the invocation format above."
        return 1
    fi
    info_msg "Selected $arg_name: '$value'" >&2
    return 0
}   