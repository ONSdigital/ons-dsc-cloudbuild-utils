#!/bin/bash
# Helper to link Terraform state bucket in GCP
# Usage: link_state_bucket <project_id>
# Expects PROJECT_ID to be set in environment variables

# Function to link the Terraform remote backend bucket
link_state_bucket() {
  local BACKEND
  BACKEND=$(gsutil ls -b "gs://*terraform-remote-backend")
  ACCOUNT_ID=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
  export TF_VAR_terraform_remote_backend="${ACCOUNT_ID}-terraform-remote-backend"

  if [[ -z "$BACKEND" ]]; then
    # do a terraform init locally if the bucket does not exist
    update_msg "Remote state bucket does not exist. Running local terraform init..."
    terraform init -backend=false
  else
   # If the bucket does exist, ensure that a backend.tf file is present; includes gcs backend block
    update_msg "Bucket gs://$TF_VAR_terraform_remote_backend already exists."
    update_msg "Initialising Terraform with backend configuration..."
    if [[ ! -f "backend.tf" ]]; then
      cat <<EOF > backend.tf
terraform {
  backend "gcs" {
  }
}
EOF
      update_msg "Created backend.tf with GCS backend configuration."
    fi
    terraform init \
      -backend-config="bucket=$TF_VAR_terraform_remote_backend"
  fi
}
