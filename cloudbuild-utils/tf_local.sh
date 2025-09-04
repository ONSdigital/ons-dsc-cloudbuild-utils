#!/bin/bash
# Import utility functions
source "$(dirname "$0")/messages.sh"
source "$(dirname "$0")/gcp_login.sh"
source "$(dirname "$0")/set_gcp_project.sh"
source "$(dirname "$0")/link_state_bucket.sh"
source "$(dirname "$0")/secret_vars.sh"

# Ensure the script exits on any error
set -e

# Default environment and method
GCP_ENV=""
METHOD=""
DIR="terraform"


# Parse input flags
while [[ $# -gt 0 ]]; do
  case $1 in
    dev|staging|prod)
      GCP_ENV="$1"
      shift
      ;;
    plan|apply)
      METHOD="$1"
      shift
      ;;
    *)
      error_msg "Unknown argument: $1"
      exit 1
      ;;
  esac
done


if [[ -z "$GCP_ENV" ]]; then
  error_msg "Environment not specified. Please add value dev, staging, or prod for 1st positional argument."
  exit 1
fi

if [[ "$METHOD" != "plan" && "$METHOD" != "apply" ]]; then
  error_msg "Invalid method: $METHOD. Must be one of: plan, apply."
  exit 1
fi

if [[ "$GCP_ENV" != "dev" && "$GCP_ENV" != "staging" && "$GCP_ENV" != "prod" ]]; then
  error_msg "Invalid environment: $GCP_ENV. Must be one of: dev, staging, prod."
  exit 1
fi

echo "Selected environment: $GCP_ENV"
echo "Selected method: $METHOD"

# TODO: Agree convention for storing project-id
# Extract the project_id from the GCP_ENV/$GCP_ENV/*.tfvars file
PROJECT_ID=""
for tfvars_file in ${DIR}/${GCP_ENV}/*secrets*.tfvars ${DIR}/${GCP_ENV}/*auto*.tfvars; do
    [ -e "$tfvars_file" ] || continue
    FOUND_ID=$(grep -E '^ *project_id *= *"[^"]+"' "$tfvars_file" | sed -E 's/^ *project_id *= *"([^"]+)"$/\1/')
    if [ -n "$FOUND_ID" ]; then
        PROJECT_ID="$FOUND_ID"
        update_msg "Found project_id: $PROJECT_ID ."
        # breaks out of the loop if a project_id is found
        break
    else
        error_msg "No project_id found in $tfvars_file, checking next file..."
    fi
done

gcp_login
set_gcp_project "$PROJECT_ID"

# Confirm the GCP project is correct
CURRENT_PROJECT=$(gcloud config get-value project)
update_msg "Current GCP project is: $CURRENT_PROJECT. Is this correct? (y to confirm)"

read -n 1 -s CONFIRMATION
if [ "$CONFIRMATION" != "y" ]; then
  error_msg -e "\nAborting. Please verify the project configuration."
  exit 1
fi
success_msg -e "\nProject confirmed."

# Initialise Terraform for the specified environment
cd "${DIR}/$GCP_ENV"

# Search for and store bucket name ending with terraform-remote-backend to BACKEND variable
update_msg "Searching for remote backend bucket..."
link_state_bucket

# Find all tfvars files for this environment (e.g., *.tfvars)
TFVARS_FILES=($(find . -maxdepth 1 -name "*.tfvars"))

# Build -var-file arguments
VAR_ARGS=()
for file in "${TFVARS_FILES[@]}"; do
  VAR_ARGS+=("-var-file=$file")
done

update_msg "Fetching additional variables from Secret Manager..."
fetch_secret_vars "tfvars"

# Run terraform plan or apply with all matching tfvars files & secret vars
if [[ "$METHOD" == "plan" ]]; then
  terraform plan "${VAR_ARGS[@]}" "${VARS[@]}" -out tfplan
fi

if [[ "$METHOD" == "apply" ]]; then
  if [[ -f "tfplan" ]]; then
    update_msg "This will apply the existing Terraform plan in the ${PROJECT_ID} ${GCP_ENV} environment. Do you want to continue? (TYPE 'y' TO CONTINUE): "
    read -n 1 -s confirm
    if [[ "${confirm,,}" != "y" ]]; then
      error_msg "Operation cancelled by user."
      exit 1
    fi
    update_msg "Applying existing Terraform plan..."
    terraform apply tfplan
  else
    error_msg "No existing Terraform plan found. Please execute 'bash terraform_local.sh <ENV> plan' first."
  fi
fi
