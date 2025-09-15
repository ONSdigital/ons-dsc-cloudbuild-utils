#!/bin/bash
# Helper to set the active GCP project in gcloud and for application-default credentials
# Usage: set_gcp_project <project_id>

source "$(dirname "$0")/messages.sh"

set_gcp_project() {
  update_msg "Setting project to ${1}..."
  if [[ "$(gcloud config get-value project 2>/dev/null)" == "$1" ]]; then
    success_msg "Project is already set to ${1}."
  else
    gcloud config set project ${1} > /dev/null
    gcloud auth application-default set-quota-project ${1} > /dev/null
    if [[ $? -eq 0 ]]; then
      success_msg "Project is set to ${1} successfully."
    else
      error_msg "Failed to set project to ${1}."
      exit 1
    fi
  fi
}
