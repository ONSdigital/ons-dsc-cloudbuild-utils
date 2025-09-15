source "$(dirname "$0")/messages.sh"

#------------------------------------------------------------------------------
# check_valid_env
#------------------------------------------------------------------------------
# Checks if the provided environment value is valid (sandbox, dev, staging, prod).
#
# Args:
#   $1: Environment value to check.
#
# Returns:
#   0 if valid, exits with error message if not.
#
# Exceptions:
#   Exits with status 1 and prints an error message if the environment is invalid.
#------------------------------------------------------------------------------
check_valid_env() {
    local env="$1"
    case "$env" in
        sandbox|dev|staging|prod)
            return 0
            ;;
        *)
            error_msg "Invalid environment: '$env'. Must be one of: sandbox, dev, staging, prod."
            exit 1
            ;;
    esac
}

#------------------------------------------------------------------------------
# check_valid_method
#------------------------------------------------------------------------------
# Checks if the provided method value is valid (plan, apply).
#
# Args:
#   $1: Method value to check.
#
# Returns:
#   0 if valid, exits with error message if not.
#
# Exceptions:
#   Exits with status 1 and prints an error message if the method is invalid.
#------------------------------------------------------------------------------
check_valid_method() {
    local method="$1"
    case "$method" in
        plan|apply)
            return 0
            ;;
        *)
            error_msg "Invalid method: $method. Must be one of: plan, apply."
            exit 1
            ;;
    esac
}
