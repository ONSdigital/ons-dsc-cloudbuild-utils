###############################################################################
# run_terraform.sh
#-------------------------------------------------------------------------------
# Purpose:
#   Provides functions to run local Terraform plan and apply operations with
#   standardized messaging, argument handling, and user confirmation. Intended
#   for use in automation scripts and local development workflows.
#
# Usage:
#   Source this file in your main script and call run_terraform_local with
#   'plan' or 'apply' as the method argument. Supports interactive confirmation
#   for apply and error handling for missing plan files.
#
# Dependencies:
#   Expects supporting functions such as info_msg and error_msg to be defined.
#   Uses global variables VAR_ARGS, VARS, PROJECT_ID, and GCP_ENV.
#
# Notes:
#   - Designed for modular use in larger automation workflows.
#   - Handles user prompts and error messaging for safe Terraform operations.
###############################################################################

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source "$script_dir/logging.sh"

###############################################################################
# run_terraform_local_plan
#-------------------------------------------------------------------------------
# Runs 'terraform plan' with provided variable arguments and outputs to tfplan.
#
# Args:
#   None (uses global VAR_ARGS and VARS arrays).
#
# Returns:
#   None. Writes plan to 'tfplan'.
#
# Raises:
#   Any errors from terraform plan are propagated.
###############################################################################
run_terraform_local_plan() {
  terraform plan "${VAR_ARGS[@]}" "${VARS[@]}" -out tfplan
}

###############################################################################
# run_terraform_local_apply
#-------------------------------------------------------------------------------
# Applies an existing Terraform plan file (tfplan) after user confirmation.
#
# Args:
#   None (uses global PROJECT_ID, GCP_ENV).
#
# Returns:
#   None. Applies the plan if confirmed.
#
# Raises:
#   Exits with error if no plan exists or user cancels.
###############################################################################
run_terraform_local_apply() {
  if [[ -f "tfplan" ]]; then
    if ! confirm_with_prompt \
      "================ USER CONFIRMATION REQUIRED ================" \
      "This will apply the existing Terraform plan in the ${PROJECT_ID} ${GCP_ENV} environment." \
      "Do you want to continue? Type 'y' or 'Y' and press Enter to continue." \
      "==========================================================="; then
      exit 1
    fi
    info_msg "Applying existing Terraform plan..."
    terraform apply tfplan
  else
    error_msg "No existing Terraform plan found. Please execute 'bash terraform_local.sh <ENV> plan' first."
  fi
}

###############################################################################
# run_terraform_local
#-------------------------------------------------------------------------------
# Dispatches to plan or apply based on the method argument.
#
# Args:
#   method: 'plan' or 'apply'.
#
# Returns:
#   None. Runs the appropriate function.
#
# Raises:
#   Exits with error if method is invalid.
###############################################################################
run_terraform_local() {
  local method="$1"
  if [[ "$method" == "plan" ]]; then
    run_terraform_local_plan
  elif [[ "$method" == "apply" ]]; then
    run_terraform_local_apply
  else
    error_msg "Invalid method: $method. Use 'plan' or 'apply'."
    exit 1
  fi
}