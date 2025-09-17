#!/bin/bash

###############################################################################
# tf_local.sh - Run Terraform locally for a given GCP environment and method
#-------------------------------------------------------------------------------
# Usage:
#   bash tf_local.sh <gcp_env> <method>
#
# Arguments:
#   <gcp_env>   Environment to target: sandbox | dev | staging | prod
#   <method>    Terraform action: plan | apply
#
# Example:
#   bash tf_local.sh dev plan
#   bash tf_local.sh prod apply
###############################################################################

# Source utility scripts
source "$(dirname "$0")/src/gcp_utilities.sh"
source "$(dirname "$0")/src/input_validation.sh"
source "$(dirname "$0")/src/link_state_bucket.sh"
source "$(dirname "$0")/src/logging.sh"
source "$(dirname "$0")/src/run_terraform.sh"
source "$(dirname "$0")/src/secret_vars.sh"
source "$(dirname "$0")/src/variables.sh"


# Ensure the script exits on any error
set -e

# Check required commands
for cmd in gcloud terraform; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error_msg "Required command '$cmd' not found. Please install it."
    exit 2
  fi
done

GCP_ENV="$1"
METHOD="$2"

# Input validation
validate_arg --value="$GCP_ENV" --arg_name=gcp_env --allowed="sandbox|dev|staging|prod" --caller='bash tf_local.sh' --arg_map="{gcp_env} {method}"
validate_arg --value="$METHOD" --arg_name=method --allowed="plan|apply" --caller='bash tf_local.sh' --arg_map="{gcp_env} {method}"
PROJECT_ID="$(get_project_id "$GCP_ENV")"
confirm_gcp_project_interactive

# Link the Terraform remote state bucket
link_remote_state_bucket

# Build variable arguments for Terraform commands
VAR_ARGS=( $(build_var_args) )

# Run the Terraform command locally
run_terraform_local $METHOD
