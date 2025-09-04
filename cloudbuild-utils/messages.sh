#######################################
# Prints an error message.
# Globals:
#   RED - error colour
#   NC - no colour
# Arguments:
#   Message
#######################################
error_msg() {
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}" >&2
}

#######################################
# Prints an update message.
# Arguments:
#   Message
#######################################
update_msg() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&1
}

#######################################
# Prints a success message.
# Globals:
#   GREEN - success colour
#   NC - no colour
# Arguments:
#   Message
#######################################
success_msg() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}" >&1
}
