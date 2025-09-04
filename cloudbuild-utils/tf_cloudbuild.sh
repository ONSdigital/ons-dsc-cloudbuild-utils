#!/bin/bash
# Import utility functions
source "$(dirname "$0")/messages.sh"
source "$(dirname "$0")/gcp_login.sh"
source "$(dirname "$0")/set_gcp_project.sh"

# Ensure the script exits on any error
set -e

# Default values
METHOD="plan"
GCP_ENV=""
URL=""
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
  # check for method and URL arguments before positional argument (i.e. env)
  case $1 in
    dev|staging|prod)
      GCP_ENV="$1"
      shift
      ;;
    plan|apply)
      METHOD="$1"
      shift
      ;;
    -u|--url)
      URL="$2"
      shift 2
      ;;
    *)
      error_msg "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate method
if [[ "$METHOD" != "plan" && "$METHOD" != "apply" ]]; then
  error_msg "--method must be either 'plan' or 'apply'"
  exit 1
fi

# Validate GCP_ENV
if [[ -z "$GCP_ENV" || ! "$GCP_ENV" =~ ^(dev|staging|prod)$ ]]; then
  error_msg "Usage: $0 <dev|staging|prod> [--method plan|apply] [--url <url>]"
  exit 1
fi

# For apply, URL is required
if [[ "$METHOD" == "apply" && -z "$URL" ]]; then
  error_msg "For apply, --url <url> is required."
  exit 1
fi

outputs=(
  "region"
  "project_id"
  "gcp_env"
  "tf_plans_bucket"
  "tf_cloud_build_service_account_email"
  "tf_cloud_build_logs_bucket"
  "tf_cloud_build_source_bucket"
  "tf_state_bucket_name"
)

for output in "${outputs[@]}"; do
  # Convert output name to uppercase and replace any non-alphanumeric characters with underscores
  var_name=$(echo "$output" | tr '[:lower:]' '[:upper:]')
  value="$(cd "terraform/$GCP_ENV"/; terraform output -raw "$output")"
  # Use indirect reference to assign value to variable
  declare "${var_name}=${value}"

  # print tf_state_bucket_name excluding the first 16 chars, otherwise normal output
  if [[ "$output" == "tf_state_bucket_name" ]]; then
    update_msg "Setting variable ${var_name} to: XXXXXXXXXXXXXXXX${value:16} (sensitive first 16 chars)"
  else
    update_msg "Setting variable ${var_name} to: ${value}"
  fi
done

gcp_login
set_gcp_project "$PROJECT_ID"

if [[ "$METHOD" == "plan" ]]; then
  update_msg "This will run a Terraform plan in the ${PROJECT_ID} ${GCP_ENV} environment. Do you want to continue? (TYPE 'y' TO CONTINUE): "
  read -n 1 -s confirm
  if [[ "${confirm,,}" != "y" ]]; then
    error_msg "Operation cancelled by user."
    exit 1
  fi
  update_msg "Handing over to Google Cloud Build..."
  gcloud builds submit --config="./configs/build_configs/plan.cloudbuild.yaml" \
    --substitutions=_GCP_ENV=$GCP_ENV,_TF_STATE_BUCKET_NAME=$TF_STATE_BUCKET_NAME,_TF_PLANS_BUCKET=$TF_PLANS_BUCKET \
    --region $REGION \
    --service-account "projects/${PROJECT_ID}/serviceAccounts/${TF_CLOUD_BUILD_SERVICE_ACCOUNT_EMAIL}" \
    --gcs-log-dir "gs://${TF_CLOUD_BUILD_LOGS_BUCKET}/plan" \
    --gcs-source-staging-dir "gs://${TF_CLOUD_BUILD_SOURCE_BUCKET}/plan" \
    --ignore-file="$REPO_ROOT/.gcloudignore"
elif [[ "$METHOD" == "apply" ]]; then
  update_msg "This will run a Terraform apply in the ${PROJECT_ID} ${GCP_ENV} environment. Do you want to continue? (TYPE 'y' TO CONTINUE): "
  read -n 1 -s confirm
  if [[ "${confirm,,}" != "y" ]]; then
    error_msg "Operation cancelled by user."
    exit 1
  fi

  # Check if the remote tfplan (tar.gz) URL exists
  if ! gsutil ls "$URL" &>/dev/null; then
    error_msg "The specified URL does not exist: $URL"
    exit 1
  fi

  update_msg "Handing over to Google Cloud Build..."
  gcloud builds submit --config="./configs/build_configs/apply.cloudbuild.yaml" \
    --substitutions=_GCP_ENV=$GCP_ENV,_TF_STATE_BUCKET_NAME=$TF_STATE_BUCKET_NAME \
    --region $REGION \
    --service-account "projects/${PROJECT_ID}/serviceAccounts/${TF_CLOUD_BUILD_SERVICE_ACCOUNT_EMAIL}" \
    --gcs-log-dir "gs://${TF_CLOUD_BUILD_LOGS_BUCKET}/apply" \
    --gcs-source-staging-dir "gs://${TF_CLOUD_BUILD_SOURCE_BUCKET}/apply" \
    --ignore-file="$REPO_ROOT/.gcloudignore" \
    "$URL"
fi
