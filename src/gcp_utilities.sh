###############################################################################
# gcp_utilities.sh - Utility functions for Google Cloud Platform scripting
#-------------------------------------------------------------------------------
# Provides functions for GCP authentication, project management, and environment
# validation to support Terraform and CI/CD automation scripts.
#
# Functions:
#   - find_tfvars_file_with_project_id: Locate a tfvars file with a project_id assignment.
#   - get_project_id: Extract the GCP project ID from a tfvars file.
#   - set_gcp_project: Set the active GCP project in gcloud and credentials.
#   - confirm_gcp_project_interactive: Prompt user to confirm the active GCP project.
#   - gcp_login: Ensure gcloud and application-default credentials are authenticated.
#
# Usage:
#   source gcp_utilities.sh
#   find_tfvars_file_with_project_id
#   get_project_id dev
#   set_gcp_project prod
#   confirm_gcp_project_interactive
#   gcp_login
#
# Used by Terraform and deployment scripts to streamline GCP operations and
# ensure consistent environment setup.
###############################################################################


script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source "$script_dir/logging.sh"
source "$script_dir/input_validation.sh"
source "$script_dir/user_prompt.sh"

# Check required commands
for cmd in gcloud grep sed; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error_msg "Required command '$cmd' not found. Please install it."
    exit 2
  fi
done

###############################################################################
# find_tfvars_file_with_project_id
#-------------------------------------------------------------------------------
# Searches for a Terraform variable file (*.auto*.tfvars) in the current directory
# containing a 'project_id' assignment.
#
# Args:
#   None.
#
# Returns:
#   Prints the path to the tfvars file containing 'project_id' to stdout and returns 0 on success.
#
# Raises:
#   Prints an error and exits with status 1 if no file is found.
###############################################################################
find_tfvars_file_with_project_id() {
  local tfvars_file

  for tfvars_file in "."/*auto*.tfvars; do
    [ -e "$tfvars_file" ] || continue
    if grep -qE '^ *project_id *= *"[^"]+"' "$tfvars_file"; then
      echo "$tfvars_file"
      return 0
    fi
  done
  error_msg "No tfvars files with project_id found in current directory."
  exit 1
}

###############################################################################
# get_project_id
#-------------------------------------------------------------------------------
# Finds and returns the GCP project ID from a Terraform variable file.
#
# Args:
#   env_dir: Path to the environment directory containing the .tfvars file.
#
# Returns:
#   Prints the value of 'project_id' found in the .tfvars file to stdout.
#
# Raises:
#   Prints an error and exits with status 1 if the environment directory is invalid or if 'project_id' is not found.
###############################################################################
get_project_id() {
  local env_dir="$1"
  local tfvars_file
  local found_id

  validate_arg --value="$env_dir" --arg_name="env_dir" --allowed="dev|prod|staging" --caller="get_project_id" --arg_map="<env_dir>"
  tfvars_file=$(find_tfvars_file_with_project_id "$env_dir")
  found_id=$(grep -E '^ *project_id *= *"[^"]+"' "$tfvars_file" | sed -E 's/^ *project_id *= *"([^"]+)"$/\1/')
  if [ -n "$found_id" ]; then
    echo "$found_id"
  else
    error_msg "No project_id found in $tfvars_file."
    exit 1
  fi
}

###############################################################################
# set_gcp_project
#-------------------------------------------------------------------------------
# Sets the active GCP project in gcloud and application-default credentials.
#
# Args:
#   env_dir: Environment directory to extract project_id from.
#
# Returns:
#   None. Prints status messages and errors to stdout.
#
# Raises:
#   Prints an error and exits with status 1 if project_id cannot be set.
###############################################################################
set_gcp_project() {
  local env_dir="$1"
  local project_id
  project_id="$(get_project_id "$env_dir")"

  info_msg "Setting project to ${project_id}..."
  if [[ "$(gcloud config get-value project 2>/dev/null)" == "$project_id" ]]; then
    info_msg "Project is already set to ${project_id}."
  else
    gcloud config set project "$project_id" > /dev/null
    gcloud auth application-default set-quota-project "$project_id" > /dev/null
    if [[ $? -eq 0 ]]; then
      info_msg "Project is set to ${project_id} successfully."
    else
      error_msg "Failed to set project to ${project_id}."
      exit 1
    fi
  fi
}

###############################################################################
# confirm_gcp_project_interactive
#-------------------------------------------------------------------------------
# Prompts the user to confirm the currently active GCP project in gcloud config.
# Waits for a single keypress and aborts if not confirmed.
#
# Args:
#   None.
#
# Returns:
#   None. Prints a message with the current project and asks for confirmation.
#
# Raises:
#   Prints an error and exits if not confirmed.
###############################################################################
confirm_gcp_project_interactive() {
  local current_project
  current_project=$(gcloud config get-value project)
  if confirm_with_prompt \
    "================ USER CONFIRMATION REQUIRED ================" \
    "Current GCP project is: $current_project." \
    "Is this correct? Type 'y' or 'Y' and press Enter to confirm." \
    "==========================================================="; then
    info_msg "Project confirmation received: '$current_project' is set as the active GCP project."
  else
    exit 1
  fi
}

###############################################################################
# gcp_login
#-------------------------------------------------------------------------------
# Ensures the user is logged in to gcloud and application-default credentials are set.
#
# Args:
#   None.
#
# Returns:
#   None. Prints info messages to stdout.
#
# Raises:
#   Prompts for login if not authenticated; prints info messages if credentials are missing.
gcp_login() {
    # Check if user is logged in
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        info_msg "No active gcloud user login found. Running 'gcloud auth login'..."
        gcloud auth login
    else
        info_msg "Active gcloud user login found."
    fi

    # Check if application default credentials are set
    if ! gcloud auth application-default print-access-token &>/dev/null; then
        info_msg "No application default credentials found. Running 'gcloud auth application-default login'..."
        gcloud auth application-default login
    else
        info_msg "Application default credentials found."
    fi
}
