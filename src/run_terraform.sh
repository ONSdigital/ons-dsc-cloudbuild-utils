###############################################################################
# run_terraform.sh
#-------------------------------------------------------------------------------
# Purpose:
#   Provides functions to run local Terraform plan and apply operations with
#   standardized messaging, argument handling, and user confirmation. Intended
#   for use in automation scripts and local development workflows.
#
# Usage:
#   Source this file in your main script and call run_terraform_local with named arguments:
#     run_terraform_local --project_id <id> --method plan --var_files "file1,file2"
#     run_terraform_local --project_id <id> --gcp_env <env> --method apply --build_id <id>
#   Supports interactive confirmation for apply and error handling for missing plan files.
#
# Dependencies:
#   Expects supporting functions such as info_msg and error_msg to be defined.
#   Uses PROJECT_ID, GCP_ENV, and other environment variables as needed.
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
# Uploads the local tfplan file and plan output to a Google Cloud Storage bucket
# named "${project_id}-tf-plans" using gsutil. The plan is stored under a unique
# path based on the current date and a random build ID.
#
# Args:
#   project_id: The GCP project ID to use for constructing the bucket name.
#
# Returns:
#   None.
#
# Raises:
#   Prints error and exits if upload fails or required files are missing.
###############################################################################
upload_plan_to_bucket() {
  local project_id="$1"
  local build_id
  local bucket_name
  local datestamp
  bucket_name="${project_id}-tf-plans"
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
# Runs 'terraform plan' with provided -var-file arguments and outputs to tfplan.
#
# Args:
#   project_id: The GCP project ID to use for constructing the bucket name.
#   var_files:  Array of -var-file arguments to pass to terraform plan.
#
# Returns:
#   None. Writes plan to 'tfplan'.
#
# Raises:
#   Any errors from terraform plan are propagated.
###############################################################################
run_terraform_local_plan() {
  local project_id="$1"
  shift
  local var_files=("$@")
  terraform plan "${var_files[@]}" -out tfplan
  terraform show -no-color tfplan > tfplan.txt
  tar -czf tfplan.tar.gz tfplan
  upload_plan_to_bucket "$project_id"
}

###############################################################################
# run_terraform_local_apply
#-------------------------------------------------------------------------------
# Applies an existing Terraform plan file (tfplan) after user confirmation.
#
# Args:
#   project_id: The GCP project ID to use for constructing the bucket name.
#   gcp_env:    The GCP environment name (for display in confirmation prompt).
#   build_id:   The unique build ID identifying the plan to apply.
#
# Returns:
#   None. Applies the plan if confirmed.
#
# Raises:
#   Exits with error if no plan exists, build_id is missing, or user cancels.
###############################################################################
run_terraform_local_apply() {
  local project_id="$1"
  local gcp_env="$2"
  local build_id="$3"
  local bucket_name
  bucket_name="${project_id}-tf-plans"
  if [ -z "$build_id" ]; then
    error_msg "A build_id argument is required when method is 'apply'. Usage: bash tf_local.sh {gcp_env} apply {build_id}"
    exit 1
  fi

  local remote_plan_path="gs://${bucket_name}/local/${build_id}/tfplan.tar.gz"
  if ! gsutil -q stat "$remote_plan_path"; then
    error_msg "Terraform plan archive not found in bucket: $remote_plan_path"
    exit 1
  fi

  if ! confirm_with_prompt \
    "================ USER CONFIRMATION REQUIRED ================" \
    "This will apply the Terraform plan from archive: $remote_plan_path" \
    "in the ${project_id} ${gcp_env} environment." \
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
# Dispatches to plan or apply based on the method argument, using named arguments.
#
# Args (flags):
#   --project_id: The GCP project ID to use for constructing the bucket name.
#   --gcp_env:    The GCP environment name (for display in confirmation prompt).
#   --method:     'plan' or 'apply'.
#   --build_id:   (Optional) The unique build ID identifying the plan to apply (required for 'apply').
#   --var_files:  (Optional) Array of -var-file arguments to pass to terraform plan.
#
# Returns:
#   None. Runs the appropriate function.
#
# Raises:
#   Exits with error if method is invalid or required arguments are missing.
###############################################################################
run_terraform_local() {
  local project_id=""
  local gcp_env=""
  local method=""
  local build_id=""
  local var_files=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project_id)
        project_id="$2"; shift 2;;
      --gcp_env)
        gcp_env="$2"; shift 2;;
      --method)
        method="$2"; shift 2;;
      --build_id)
        build_id="$2"; shift 2;;
      --var_files)
        IFS=',' read -r -a var_files <<< "$2"; shift 2;;
      *)
        error_msg "Unknown argument: $1"; exit 1;;
    esac
  done

  if [[ -z "$project_id" || -z "$method" ]]; then
    error_msg "--project_id and --method are required arguments."; exit 1
  fi

  if [[ "$method" == "plan" ]]; then
    run_terraform_local_plan "$project_id" "${var_files[@]}"
  elif [[ "$method" == "apply" ]]; then
    run_terraform_local_apply "$project_id" "$gcp_env" "$build_id"
  else
    error_msg "Invalid method: $method. Use 'plan' or 'apply'."; exit 1
  fi
}
