#!/bin/bash
# Helper to set the active GCP project in gcloud and for application-default credentials
# Usage: set_gcp_project <project_id>

source "$(dirname "$0")/messages.sh"
source "$(dirname "$0")/input_validation.sh"

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
#   Echoes the path to the tfvars file containing 'project_id' and returns 0 on success.
#
# Exceptions:
#   Exits with status 1 and prints an error message if no file is found.
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


#------------------------------------------------------------------------------
# get_project_id
#------------------------------------------------------------------------------
# Finds and returns the GCP project ID from a Terraform variable file.
#
# Sets the GCP project by extracting the 'project_id' from a specified .tfvars file.
#
# Args:
#   $1: Path to the environment directory containing the .tfvars file.
#
# Returns:
#   Prints the value of 'project_id' found in the .tfvars file.
#
# Exceptions:
#   Exits with status 1 and prints an error message if the environment directory is invalid or if 'project_id' is not found.
# ------------------------------------------------------------------------------
get_project_id() {
  local env_dir="$1"
  local tfvars_file
  local found_id

  check_valid_env "$env_dir"
  tfvars_file=$(find_tfvars_file_with_project_id "$env_dir")
  found_id=$(grep -E '^ *project_id *= *"[^"]+"' "$tfvars_file" | sed -E 's/^ *project_id *= *"([^"]+)"$/\1/')
  if [ -n "$found_id" ]; then
    echo "$found_id"
  else
    error_msg "No project_id found in $tfvars_file."
    exit 1
  fi
}

#------------------------------------------------------------------------------
# set_gcp_project
#------------------------------------------------------------------------------
# Sets the active GCP project in gcloud and application-default credentials.
#
# Args:
#   $1: Environment directory to extract project_id from.
#
# Returns:
#   None. Prints status messages and errors.
#
# Exceptions:
#   Exits with status 1 and prints an error message if project_id cannot be set.
#------------------------------------------------------------------------------
set_gcp_project() {
  local project_id
  project_id="$(get_project_id "$1")"

  info_msg "Setting project to ${project_id}..."
  if [[ "$(gcloud config get-value project 2>/dev/null)" == "$project_id" ]]; then
    info_msg "Project is already set to ${project_id}."
  else
    gcloud config set project "$project_id" > /dev/null
    gcloud auth application-default set-quota-project "$project_id" > /dev/null
    if [[ $? -eq 0 ]]; then
      success_msg "Project is set to ${project_id} successfully."
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
#   Exits with error if not confirmed.
#-------------------------------------------------------------------------------
confirm_gcp_project_interactive() {
  local current_project confirmation
  current_project=$(gcloud config get-value project)
  info_msg "Current GCP project is: $current_project. Is this correct? (y/Y to confirm)"

  read -n 1 -s confirmation
  if [[ "${confirmation,,}" != "y" ]]; then
    error_msg "Aborting: The active GCP project is not confirmed. Please check your project settings and try again."
    exit 1
  fi
  success_msg "Project confirmation received: '$current_project' is set as the active GCP project."
}