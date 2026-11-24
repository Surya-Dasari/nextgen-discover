#!/usr/bin/env bash

# ==============================================================================
# Script       : setup-jwt.sh
# Project      : NextGen Discover
# Purpose      : Generate an RSA JWT key pair and provision it in AWS
#                Secrets Manager.
#
# Workflow:
#   1. Validate required tools and AWS configuration.
#   2. Generate an RSA 3072-bit key pair if one does not exist.
#   3. Reuse existing keys without overwriting them.
#   4. Verify that the private and public keys match.
#   5. Check whether the AWS Secrets Manager secret already exists.
#   6. Create the secret containing both keys if it does not exist.
#
# Security:
#   - Private keys are never printed.
#   - Temporary secret payload files use restrictive permissions.
#   - Existing keys and Secrets Manager secrets are preserved.
#
# Usage:
#   ./scripts/setup-jwt.sh
#
# Optional configuration:
#   JWT_KEY_DIR       : Local JWT key directory
#   JWT_SECRET_NAME   : AWS Secrets Manager secret name
#   AWS_REGION        : AWS deployment region
#   AWS_DEFAULT_REGION: Fallback AWS region
# ==============================================================================

set -Eeuo pipefail
umask 077

# ------------------------------------------------------------------------------
# 1. Configuration
# ------------------------------------------------------------------------------

readonly KEY_DIR="${JWT_KEY_DIR:-$HOME/.nextgen-discover/keys}"
readonly SECRET_NAME="${JWT_SECRET_NAME:-nextgen-discover/jwt}"

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"

readonly PRIVATE_KEY="${KEY_DIR}/jwt-private.pem"
readonly PUBLIC_KEY="${KEY_DIR}/jwt-public.pem"

# Temporary files are initialized during execution.
TEMP_SECRET=""
ERROR_FILE=""

# ------------------------------------------------------------------------------
# 2. Logging and cleanup
# ------------------------------------------------------------------------------

log() {
    echo "[INFO] $*"
}

fail() {
    echo "[ERROR] $*" >&2
    exit 1
}

cleanup() {
    [[ -z "$TEMP_SECRET" ]] || rm -f "$TEMP_SECRET"
    [[ -z "$ERROR_FILE" ]] || rm -f "$ERROR_FILE"
}

trap cleanup EXIT

# ------------------------------------------------------------------------------
# 3. Prerequisite validation
# ------------------------------------------------------------------------------

validate_prerequisites() {
    log "Checking required tools and configuration."

    local required_tools=(openssl aws python3 diff)

    for tool in "${required_tools[@]}"; do
        command -v "$tool" >/dev/null 2>&1 ||
            fail "Required tool not found: $tool"
    done

    # Resolve the AWS region after confirming AWS CLI is available.
    if [[ -z "$REGION" ]]; then
        REGION="$(aws configure get region 2>/dev/null || true)"
    fi

    [[ -n "$REGION" ]] ||
        fail "AWS region is not configured."

    log "Required tools and AWS region verified."
}

# ------------------------------------------------------------------------------
# 4. JWT key generation or reuse
# ------------------------------------------------------------------------------

ensure_jwt_key_pair() {
    log "Checking local JWT key pair."

    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR"

    # Reuse a complete key pair. Never overwrite an incomplete pair.
    if [[ -f "$PRIVATE_KEY" && -s "$PRIVATE_KEY" &&
          -f "$PUBLIC_KEY" && -s "$PUBLIC_KEY" ]]; then

        log "Existing JWT key pair found. Reusing existing keys."

    elif [[ -e "$PRIVATE_KEY" || -e "$PUBLIC_KEY" ]]; then

        fail "Incomplete JWT key pair detected. Refusing to overwrite."

    else
        log "Generating new RSA 3072-bit JWT key pair."

        openssl genpkey \
            -algorithm RSA \
            -pkeyopt rsa_keygen_bits:3072 \
            -out "$PRIVATE_KEY"

        openssl pkey \
            -in "$PRIVATE_KEY" \
            -pubout \
            -out "$PUBLIC_KEY"

        log "New JWT key pair generated."
    fi

    # Enforce restrictive private-key permissions for both new and existing keys.
    chmod 600 "$PRIVATE_KEY"
    chmod 644 "$PUBLIC_KEY"

    # Verify that the public key corresponds to the private key.
    if ! openssl pkey \
        -in "$PRIVATE_KEY" \
        -pubout 2>/dev/null |
        diff -q - "$PUBLIC_KEY" >/dev/null; then

        fail "JWT private and public keys do not match."
    fi

    log "JWT key pair verification successful."
}

# ------------------------------------------------------------------------------
# 5. AWS identity and Secrets Manager validation
# ------------------------------------------------------------------------------

validate_aws_identity() {
    log "Verifying AWS identity."

    aws sts get-caller-identity \
        --query Arn \
        --output text

    log "AWS region: $REGION"
    log "Secrets Manager secret: $SECRET_NAME"
}

# ------------------------------------------------------------------------------
# 6. Existing secret detection
# ------------------------------------------------------------------------------

check_existing_secret() {
    log "Checking whether the JWT secret already exists."

    ERROR_FILE="$(mktemp)"

    # AWS CLI returns a non-zero status when the secret cannot be found.
    if aws secretsmanager describe-secret \
        --secret-id "$SECRET_NAME" \
        --region "$REGION" \
        >/dev/null 2>"$ERROR_FILE"; then

        log "Secret already exists. No changes will be made."
        return 0
    fi

    # Extract the AWS service error code using Python's standard library.
    local error_code

    error_code="$(python3 - "$ERROR_FILE" <<'PYTHON'
import pathlib
import re
import sys

error_output = pathlib.Path(sys.argv[1]).read_text()

match = re.search(
    r"An error occurred \(([^)]+)\) when calling",
    error_output
)

if match:
    print(match.group(1))
PYTHON
)"

    # Only a confirmed missing secret allows creation to proceed.
    if [[ "$error_code" == "ResourceNotFoundException" ]]; then
        log "Secret does not exist. Creation is required."
        return 1
    fi

    # Do not treat permission, authentication, or network errors as absence.
    cat "$ERROR_FILE" >&2
    fail "Unable to verify existing Secrets Manager secret. AWS error code: ${error_code:-unknown}"
}

# ------------------------------------------------------------------------------
# 7. Secure secret payload preparation
# ------------------------------------------------------------------------------

prepare_secret_payload() {
    log "Preparing JWT secret payload."

    TEMP_SECRET="$(mktemp)"
    chmod 600 "$TEMP_SECRET"

    # Store both keys as JSON without displaying their contents.
    python3 - "$PRIVATE_KEY" "$PUBLIC_KEY" "$TEMP_SECRET" <<'PY'
import json
import pathlib
import sys

private_key_path = pathlib.Path(sys.argv[1])
public_key_path = pathlib.Path(sys.argv[2])
output_path = pathlib.Path(sys.argv[3])

secret_payload = {
    "jwt_private_key_pem": private_key_path.read_text(),
    "jwt_public_key_pem": public_key_path.read_text()
}

output_path.write_text(json.dumps(secret_payload))
output_path.chmod(0o600)
PY

    log "JWT secret payload prepared securely."
}

# ------------------------------------------------------------------------------
# 8. AWS Secrets Manager provisioning
# ------------------------------------------------------------------------------

create_jwt_secret() {
    log "Creating JWT secret in AWS Secrets Manager."

    aws secretsmanager create-secret \
        --name "$SECRET_NAME" \
        --description "NextGen Discover JWT signing and verification keys" \
        --secret-string "file://$TEMP_SECRET" \
        --region "$REGION" \
        --tags \
            Key=Project,Value=NextGenDiscover \
            Key=Purpose,Value=JWT

    log "JWT secret created successfully."
}

# ------------------------------------------------------------------------------
# 9. Main execution
# ------------------------------------------------------------------------------

main() {
    log "Starting NextGen Discover JWT setup."

    validate_prerequisites
    ensure_jwt_key_pair
    validate_aws_identity

    # Stop successfully if the secret already exists.
    # This protects existing JWT keys from accidental replacement.
    if check_existing_secret; then
        log "JWT setup completed. Existing secret preserved."
        return 0
    fi

    prepare_secret_payload
    create_jwt_secret

    log "JWT setup completed successfully."
}

main "$@"
