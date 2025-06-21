#!/bin/bash
set -euo pipefail

# --- Helper Functions ---

# Color codes for formatting output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# --- Main Logic ---

# Get the current date in Unix timestamp format
now=$(date +%s)

# Arrays to store key IDs for deletion
declare -a expired_key_ids
declare -a unknown_key_ids

# --- Identify Expired and Unknown Public Keys ---

info "Searching for expired or unknown public keys..."

while IFS=':' read -r type validity key_length algo key_id created_date expires_date _; do
  # Skip empty key IDs
  if [ -z "$key_id" ]; then
    continue
  fi

  # Check for expired keys
  if [[ "$expires_date" =~ ^[0-9]+$ ]] && [ "$expires_date" -lt "$now" ]; then
    warn "Found expired key: $key_id"
    expired_key_ids+=("$key_id")
  fi

  # Check for keys with unknown validity
  if [ "$validity" == "u" ]; then
    warn "Found key with unknown validity: $key_id"
    unknown_key_ids+=("$key_id")
  fi
done < <(gpg --list-keys --with-colons)

# --- Identify Expired Secret Keys ---

info "Searching for expired secret keys..."

while IFS=':' read -r type validity key_length algo key_id created_date expires_date _; do
  # Check for expired secret keys
  if [[ "$expires_date" =~ ^[0-9]+$ ]] && [ "$expires_date" -lt "$now" ]; then
    warn "Found expired secret key: $key_id"
    # Avoid adding duplicates if the public key is also expired
    if ! [[ " ${expired_key_ids[@]} " =~ " ${key_id} " ]]; then
      expired_key_ids+=("$key_id")
    fi
  fi
done < <(gpg --list-secret-keys --with-colons)

# --- Summary and Confirmation ---

echo
info "--- Deletion Summary ---"

if [ ${#expired_key_ids[@]} -eq 0 ] && [ ${#unknown_key_ids[@]} -eq 0 ]; then
  info "No expired or unknown keys found. Your GPG keyring is clean!"
  exit 0
fi

if [ ${#expired_key_ids[@]} -gt 0 ]; then
  warn "The following EXPIRED keys will be deleted:"
  for key_id in "${expired_key_ids[@]}"; do
    echo "  - $key_id"
  done
fi

if [ ${#unknown_key_ids[@]} -gt 0 ]; then
  warn "The following keys with UNKNOWN validity will be deleted:"
  for key_id in "${unknown_key_ids[@]}"; do
    echo "  - $key_id"
  done
fi

echo
read -p "Do you want to proceed with the deletion? (y/N): " confirm
if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
  info "Aborting. No keys were deleted."
  exit 0
fi

# --- Deletion ---

info "Proceeding with deletion..."

all_keys_to_delete=("${expired_key_ids[@]}" "${unknown_key_ids[@]}")
# Remove duplicates
unique_keys_to_delete=($(for key in "${all_keys_to_delete[@]}"; do echo "${key}"; done | sort -u))

for key_id in "${unique_keys_to_delete[@]}"; do
  info "Deleting public key: $key_id"
  gpg --batch --yes --delete-keys "$key_id" || error "Failed to delete public key $key_id. It might not exist or there was another error."
  
  info "Attempting to delete secret key (if it exists): $key_id"
  gpg --batch --yes --delete-secret-keys "$key_id" || warn "No secret key found for $key_id, or it was already deleted. This is usually normal."
done

info "Cleanup complete!"
