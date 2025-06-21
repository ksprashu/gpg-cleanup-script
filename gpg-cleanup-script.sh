#!/bin/bash
set -euo pipefail

# --- Configuration and Helper Functions ---

# Color codes for formatting output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "A script to find and delete expired or unknown GPG keys."
  echo
  echo "Options:"
  echo "  --delete    Actually delete the keys found. Default is a dry run."
  echo "  -h, --help  Display this help message."
  echo
  echo "The script runs in 'dry run' mode by default, only showing what would be deleted."
}

# --- Command-line Argument Parsing ---

DELETE_MODE=0
if [[ "${1:-}" == "--delete" ]]; then
  DELETE_MODE=1
  warn "Running in DELETE mode. Keys will be permanently removed after confirmation."
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
else
  info "Running in DRY RUN mode. No keys will be deleted."
fi

# --- Main Logic ---

info "Reading and analyzing GPG keys..."

keys_to_delete=()
reasons=()
uids=()

# Process keys and UIDs in one pass
while IFS= read -r line; do
  IFS=':' read -r type validity _ _ key_id _ expires_date _ _ uid _ <<< "$line"
  
  if [ "$type" == "pub" ]; then
    current_key_id=$key_id
    
    # Check for expired keys
    if [[ "$expires_date" =~ ^[0-9]+$ ]] && [ "$expires_date" -lt "$(date +%s)" ]; then
      keys_to_delete+=("$current_key_id")
      reasons+=("Expired")
      uids+=("$(gpg --list-keys --with-colons "$current_key_id" | grep "^uid" | head -n 1 | cut -d: -f10)")
    # Check for keys with unknown validity
    elif [ "$validity" == "-" ]; then
      keys_to_delete+=("$current_key_id")
      reasons+=("Unknown validity")
      uids+=("$(gpg --list-keys --with-colons "$current_key_id" | grep "^uid" | head -n 1 | cut -d: -f10)")
    fi
  fi
done < <(gpg --list-keys --with-colons)

# --- Summary and Confirmation ---

echo
info "--- Analysis Summary ---"

if [ ${#keys_to_delete[@]} -eq 0 ]; then
  info "No expired or unknown keys found to delete."
  exit 0
fi

warn "The following keys are flagged for deletion:"
for i in "${!keys_to_delete[@]}"; do
  echo "  - Key ID: ${keys_to_delete[$i]}"
  echo "    UID:    ${uids[$i]}"
  echo "    Reason: ${reasons[$i]}"
done

if [ $DELETE_MODE -eq 0 ]; then
  echo
  info "This was a dry run. To delete these keys, run the script with the --delete flag."
  exit 0
fi

echo
read -p "Do you want to proceed with deleting the keys listed above? (y/N): " confirm
if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
  info "Aborting. No keys were deleted."
  exit 0
fi

# --- Deletion ---

info "Proceeding with deletion..."

for key_id in "${keys_to_delete[@]}"; do
  fingerprint=$(gpg --with-colons --fingerprint "$key_id" | grep "^fpr" | head -n 1 | cut -d: -f10)
  
  if [ -z "$fingerprint" ]; then
    error "Could not get fingerprint for key $key_id. Aborting."
  fi

  info "Deleting secret key for $key_id..."
  gpg --batch --yes --delete-secret-keys "$fingerprint" || warn "No secret key found for $key_id, which is normal."
  
  info "Deleting public key for $key_id..."
  gpg --batch --yes --delete-keys "$fingerprint" || error "Failed to delete public key $key_id."
done

info "Cleanup complete!"