#!/bin/bash
# Helper to ensure user is logged in to gcloud and application-default credentials are set
# Usage: check_gcp_login

source "$(dirname "$0")/messages.sh"

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
# To use, call gcp_login explicitly in your script or shell
