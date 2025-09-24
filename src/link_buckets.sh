###############################################################################
# link_buckets.sh - Utilities for managing Terraform remote state in GCP
#-------------------------------------------------------------------------------
# Provides functions to detect, link, and bootstrap the Terraform remote state
# bucket, including migration from local to remote state and backend setup.
#
# Usage:
#   source link_buckets.sh
#   link_remote_state_bucket
#
# Used by automation scripts to ensure remote state is correctly configured and
# maintained for all environments.
###############################################################################

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source "$script_dir/logging.sh"
source "$script_dir/user_prompt.sh"


###############################################################################
# init_remote_state
#-------------------------------------------------------------------------------
# Initializes the Terraform remote state backend using the bucket specified in
# TF_VAR_tf_remote_state_bucket. Runs 'terraform init' with the backend config.
#
# Args:
#   None. Uses TF_VAR_tf_remote_state_bucket from environment.
#
# Returns:
#   0 on success.
#
# Raises:
#   Prints error and returns 1 if terraform init fails or bucket is not set.
init_remote_state() {
    terraform init -backend-config="bucket=$TF_VAR_tf_remote_state_bucket" || {
    return 1
  }
}

###############################################################################
# is_first_time_setup
#-------------------------------------------------------------------------------
# Checks if this is the first-time Terraform setup by testing for the existence
# of backend.tf in the current directory.
#
# Args:
#   None.
#
# Returns:
#   0 if backend.tf does not exist (first-time setup), 1 otherwise.
#
# Raises:
#   None.
is_first_time_setup() {
  if [[ ! -f "backend.tf" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# print_tf_var_remote_state_bucket_debug
#-------------------------------------------------------------------------------
# Prints the value of TF_VAR_tf_remote_state_bucket if DEBUG is true.
#
# Args:
#   None.
#
# Returns:
#   None.
print_tf_var_remote_state_bucket_debug() {
  if [[ "$DEBUG" == "true" ]]; then
    debug_msg "DEBUG: TF_VAR_tf_remote_state_bucket is set to '$TF_VAR_tf_remote_state_bucket'"
  fi
}

###############################################################################
# required_tf_files_exist
#-------------------------------------------------------------------------------
# Checks if setup.tf, providers.tf, variables.tf, and config.auto.tfvars exist.
#
# Args:
#   None.
#
# Returns:
#   0 if all files exist, 1 otherwise.
required_tf_files_exist() {
  [[ -f "setup.tf" && -f "providers.tf" && -f "variables.tf" && -f "config.auto.tfvars" ]]
}

###############################################################################
# run_isolated_tf_setup
#-------------------------------------------------------------------------------
# Runs terraform init, plan, and apply in a temporary directory using only
# setup.tf, providers.tf, variables.tf, and config.auto.tfvars from the current directory.
#
# Args:
#   None.
#
# Returns:
#   0 on success.
#
# Raises:
#   Prints error messages and returns 1 on failure.
#   Also creates backend.tf and migrates state in both temp and main directory.
run_isolated_tf_setup() {
  local files=(setup.tf providers.tf variables.tf config.auto.tfvars)
  local tmp_dir=$(mktemp -d)
  local tmp_dir
  tmp_dir=$(mktemp -d -t terraform.XXXXXX)
  if [[ ! -d "$tmp_dir" ]]; then
    error_msg "Failed to create temporary directory for Terraform setup."
    return 1
  fi
  cp "${files[@]}" "$tmp_dir/"
  pushd "$tmp_dir" > /dev/null
  terraform init -backend=false || {
    error_msg "Terraform init failed for setup.tf, providers.tf, variables.tf, config.auto.tfvars."
    popd > /dev/null
    rm -rf "$tmp_dir"
    return 1
  }
  terraform apply -auto-approve || {
    error_msg "Terraform apply failed for setup.tf, providers.tf, variables.tf, config.auto.tfvars."
    popd > /dev/null
    rm -rf "$tmp_dir"
    return 1
  }
  info_msg "Creating backend.tf with backend block for remote state." >&2
  create_backend_tf_with_block
  export_tf_remote_state_bucket
  migrate_local_state_to_remote
  info_msg "Remote state backend configured successfully." >&2
  popd > /dev/null
  rm -rf "$tmp_dir"
}

###############################################################################
# create_backend_tf_with_block
#-------------------------------------------------------------------------------
# Creates a backend.tf file with a terraform block containing the specified backend type.
# If backend.tf exists, checks for the backend block and warns if missing.
#
# Args:
#   backend_type: Backend type (default: gcs)
#
# Returns:
#   0 on success.
#
# Raises:
#   Prints error messages and returns 1 on failure.
create_backend_tf_with_block() {
  local backend_file="backend.tf"
  local backend_type="${1:-gcs}"

  if [[ -f "$backend_file" ]]; then
    if grep -q "backend \"$backend_type\"" "$backend_file"; then
      warning_msg "Backend block for $backend_type already exists in $backend_file."
      return 0
    fi
    warning_msg "$backend_file exists but does not contain backend block for $backend_type."
    return 0
  else
    cat > "$backend_file" <<EOF
terraform {
  backend "$backend_type" {}
}
EOF
    info_msg "Created $backend_file with backend block for $backend_type."
    return 0
  fi
}

###############################################################################
# migrate_local_state_to_remote
#-------------------------------------------------------------------------------
# Migrates local Terraform state to the configured remote backend bucket.
#
# Args:
#   None.
#
# Returns:
#   0 on success, 1 on failure.
migrate_local_state_to_remote() {
  info_msg "Migrating local Terraform state to remote backend..." >&2
  if [[ -z "$TF_VAR_tf_remote_state_bucket" ]]; then
    error_msg "TF_VAR_tf_remote_state_bucket is not set. Cannot migrate state." >&2
    return 1
  fi
  terraform init -migrate-state -backend-config="bucket=${TF_VAR_tf_remote_state_bucket}" || {
    error_msg "State migration to remote backend failed." >&2
    return 1
  }
  info_msg "Terraform state successfully migrated to remote backend." >&2
}

###############################################################################
# prompt_local_state_bootstrap_confirmation
#-------------------------------------------------------------------------------
# Explains the local setup and migration process when no backend.tf is found,
# and prompts the user for confirmation before proceeding.
#
# Args:
#   None.
#
# Returns:
#   0 if confirmed, 1 if cancelled.
#
# Raises:
#   Returns 1 if user does not confirm.
prompt_local_state_bootstrap_confirmation() {
  confirm_with_prompt \
    "================ USER CONFIRMATION REQUIRED ================" \
    "Terraform remote state is not yet configured (no backend.tf found)." \
    "This script will now bootstrap remote state by:" \
    "  1. Running an initial local terraform apply to create the required remote state bucket(s)." \
    "  2. Migrating the local state to the remote bucket once created." \
    "You will see progress updates and status messages as the remote state is being set up." \
    "This may take a few moments, and you may be prompted for additional input if required." \
    "Do you want to continue? Type 'y' or 'Y' and press Enter to continue." \
    "==========================================================="
  return $?
}

###############################################################################
# init_and_configure_remote_state
#-------------------------------------------------------------------------------
# Performs first-time Terraform setup locally (no backend), applies initial
# resources using setup.tf, providers.tf, variables.tf, and config.auto.tfvars,
# and then creates backend.tf for remote state. Intended for bootstrapping remote state when no remote state bucket exists.
#
# Args:
#   None.
#
# Returns:
#   0 on success.
#
# Raises:
#   Prints error messages and returns 1 on failure.
init_and_configure_remote_state() {
  if ! prompt_local_state_bootstrap_confirmation; then
    return 1
  fi
  info_msg "Running local terraform init for setup..." >&2
  terraform init -backend=false
  if required_tf_files_exist; then
    info_msg "Required Terraform files found. Running isolated setup." >&2
    run_isolated_tf_setup
    return 0
  else
    error_msg "setup.tf, providers.tf, or variables.tf not found." >&2
    return 1
  fi
}

###############################################################################
# link_remote_state_bucket
#-------------------------------------------------------------------------------
# Detects the Terraform remote state bucket and delegates initialisation to
# init_remote_state (for existing backend) or init_and_configure_remote_state (for first-time setup).
#
# Args:
#   None.
#
# Returns:
#   0 on success.
#
# Raises:
#   Returns 1 if the bucket cannot be linked or setup fails.
link_remote_state_bucket() {
  if is_first_time_setup; then
    init_and_configure_remote_state
    create_backend_tf_with_block
    init_remote_state
  else
    info_msg "Starting remote state bucket linking workflow." >&2
    export_tf_remote_state_bucket
    init_remote_state
  fi
}
