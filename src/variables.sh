###############################################################################
# variables.sh
#-------------------------------------------------------------------------------
# Purpose:
#   Provides utility functions for handling Terraform variable files (.tfvars)
#   in the current directory. Primarily used to build argument lists for
#   Terraform CLI commands in automation scripts and local workflows.
#
# Usage:
#   Source this file and call build_var_args to generate -var-file arguments
#   for all .tfvars files present. Integrates with other scripts to simplify
#   variable management for Terraform operations.
#
# Notes:
#   - Designed for modular use in larger automation workflows.
#   - Returns an empty string if no .tfvars files are found.
###############################################################################


###############################################################################
# build_var_args
#-------------------------------------------------------------------------------
# Builds an array of -var-file arguments for all .tfvars files in the current directory.
#
# Args:
#   None.
#
# Returns:
#   Echoes a space-separated string of -var-file arguments for use with Terraform CLI.
#
# Raises:
#   None. If no .tfvars files are found, returns an empty string.
###############################################################################
build_var_args() {
  local tfvars_files=( $(find . -maxdepth 1 -name "*.tfvars") )
  local args=()
  for file in "${tfvars_files[@]}"; do
    args+=("-var-file=$file")
  done
  echo "${args[@]}"
}