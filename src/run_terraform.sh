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
# upload_plan_to_bucket
#-------------------------------------------------------------------------------
# Uploads the local tfplan file to the remote tf_plans_bucket using gsutil.
#
# Args:
#   build_id: Unique identifier for the plan upload (e.g., a hex string).
#
# Returns:
#   None.
#
# Raises:
#   Prints error and exits if upload fails.
###############################################################################
upload_plan_to_bucket() {
  local build_id
  local bucket_name
  local datestamp
  bucket_name=$(get_bucket_name "tf-plans")
  build_id=$(openssl rand -hex 3)
  datestamp=$(date +"%Y-%m-%d")
  if [[ -z "$bucket_name" ]]; then
    error_msg "tf_plans_bucket output not found."
    return 1
  fi
  if [[ ! -f "tfplan.tar.gz" ]]; then
    error_msg "tfplan.tar.gz file not found."
    return 1
  fi
  gsutil -q cp tfplan.tar.gz "gs://${bucket_name}/local/${datestamp}__${build_id}/tfplan.tar.gz"
  gsutil -q cp tfplan.txt "gs://${bucket_name}/local/${datestamp}__${build_id}/tfplan.txt"
  
  rm -f tfplan tfplan.tar.gz tfplan.txt
  success_msg "tfplan uploaded to gs://${bucket_name}/local/${datestamp}__${build_id}/tfplan.tar.gz"
  info_msg "To see the plan go to: https://console.cloud.google.com/storage/browser/${bucket_name}/local/${datestamp}__${build_id}"
  info_msg "To apply these changes after review run: bash ../../ons-dsc-cloudbuild-utils/tf_local.sh ${GCP_ENV} apply '${datestamp}__${build_id}'"
}

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
  terraform show -no-color tfplan > tfplan.txt
  tar -czf tfplan.tar.gz tfplan
  upload_plan_to_bucket
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
  local bucket_name
  bucket_name=$(get_bucket_name "tf-plans")
  if [ -z "$BUILD_ID" ]; then
    error_msg "A build_id argument is required when method is 'apply'. Usage: bash tf_local.sh {gcp_env} apply {build_id}"
    exit 1
  fi

  local remote_plan_path="gs://${bucket_name}/local/${BUILD_ID}/tfplan.tar.gz"
  if ! gsutil -q stat "$remote_plan_path"; then
    error_msg "Terraform plan archive not found in bucket: $remote_plan_path"
    exit 1
  fi

  if ! confirm_with_prompt \
    "================ USER CONFIRMATION REQUIRED ================" \
    "This will apply the Terraform plan from archive: $remote_plan_path" \
    "in the ${PROJECT_ID} ${GCP_ENV} environment." \
    "Do you want to continue? Type 'y' or 'Y' and press Enter to continue." \
    "==========================================================="; then
    exit 1
  fi
  info_msg "Applying Terraform plan from archive $remote_plan_path"
  gsutil -q cp "$remote_plan_path" tfplan.tar.gz
  tar -xzf tfplan.tar.gz
  terraform apply tfplan
  rm -f tfplan tfplan.tar.gz
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