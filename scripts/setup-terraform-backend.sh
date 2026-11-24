#!/usr/bin/env bash
set -Eeuo pipefail

# NextGen Discover - Terraform S3 backend setup

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infrastructure/terraform/infrastructure"

REGION="${1:-${AWS_REGION:-us-east-2}}"
PROJECT_NAME="${PROJECT_NAME:-nextgen-discover}"
STATE_KEY="infrastructure/terraform.tfstate"

log() {
    printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

fail() {
    printf '\nERROR: %s\n' "$1" >&2
    exit 1
}

# Check required tools.
for cmd in aws terraform jq; do
    command -v "$cmd" >/dev/null 2>&1 ||
        fail "Required command not found: $cmd"
done

[[ -d "$TF_DIR" ]] || fail "Terraform directory not found: $TF_DIR"

[[ "$REGION" =~ ^[a-z0-9-]+$ ]] ||
    fail "Invalid AWS region: $REGION"

[[ "$PROJECT_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] ||
    fail "Invalid PROJECT_NAME."

# Identify the AWS account.
log "Checking AWS identity"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

[[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]] ||
    fail "Could not determine a valid AWS account ID."

BUCKET="${PROJECT_NAME}-terraform-state-${ACCOUNT_ID}-${REGION}"

(( ${#BUCKET} <= 63 )) ||
    fail "Generated bucket name exceeds 63 characters."

log "AWS account: $ACCOUNT_ID"
log "AWS region: $REGION"
log "S3 bucket: $BUCKET"

# Check whether the bucket exists.
log "Checking S3 bucket"

if aws s3api head-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" >/dev/null 2>&1; then

    log "Existing bucket found."

else
    HEAD_ERROR="$(aws s3api head-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" 2>&1 || true)"

    if grep -Eq '404|Not Found' <<< "$HEAD_ERROR"; then
        log "Bucket does not exist. Creating it."

        if [[ "$REGION" == "us-east-1" ]]; then
            aws s3api create-bucket \
                --bucket "$BUCKET" \
                --region "$REGION"
        else
            aws s3api create-bucket \
                --bucket "$BUCKET" \
                --region "$REGION" \
                --create-bucket-configuration \
                "LocationConstraint=$REGION"
        fi

        log "Bucket created."
    else
        fail "Could not verify bucket existence. AWS response: $HEAD_ERROR"
    fi
fi

# Enable versioning.
log "Ensuring bucket versioning"

aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --versioning-configuration Status=Enabled

# Check encryption before changing anything.
log "Checking bucket encryption"

ENCRYPTION_ERROR="$(mktemp)"

if ENCRYPTION="$(aws s3api get-bucket-encryption \
    --bucket "$BUCKET" \
    --region "$REGION" 2>"$ENCRYPTION_ERROR")"; then

    ALGORITHM="$(jq -r \
        '.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm // empty' \
        <<< "$ENCRYPTION")"

    [[ "$ALGORITHM" == "AES256" ]] ||
        fail "Existing encryption is '$ALGORITHM'. Manual review required."

    log "AES-256 encryption verified."

else
    if grep -q "ServerSideEncryptionConfigurationNotFoundError" "$ENCRYPTION_ERROR"; then
        log "No default encryption found. Enabling AES-256."

        aws s3api put-bucket-encryption \
            --bucket "$BUCKET" \
            --region "$REGION" \
            --server-side-encryption-configuration \
            '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    else
        ERROR_MESSAGE="$(cat "$ENCRYPTION_ERROR")"
        rm -f "$ENCRYPTION_ERROR"
        fail "Could not verify bucket encryption: $ERROR_MESSAGE"
    fi
fi

rm -f "$ENCRYPTION_ERROR"

# Block public access.
log "Ensuring public access is blocked"

aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Enforce bucket-owner ownership.
log "Ensuring bucket ownership controls"

aws s3api put-bucket-ownership-controls \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --ownership-controls \
    '{"Rules":[{"ObjectOwnership":"BucketOwnerEnforced"}]}'

# Check HTTPS-only bucket policy.
log "Checking bucket policy"

POLICY_ERROR="$(mktemp)"

if POLICY_RESPONSE="$(aws s3api get-bucket-policy \
    --bucket "$BUCKET" \
    --region "$REGION" 2>"$POLICY_ERROR")"; then

    POLICY="$(jq -r '.Policy' <<< "$POLICY_RESPONSE")"

    if ! jq -e '
        [
          .Statement[]?
          | select(
              .Sid == "DenyInsecureTransport"
              and .Effect == "Deny"
              and .Action == "s3:*"
              and .Condition.Bool["aws:SecureTransport"] == "false"
            )
        ] | length > 0
    ' <<< "$POLICY" >/dev/null; then
        rm -f "$POLICY_ERROR"
        fail "Existing bucket policy needs manual review. It has not been changed."
    fi

    log "Existing HTTPS-only policy verified and preserved."

else
    if grep -q "NoSuchBucketPolicy" "$POLICY_ERROR"; then
        log "No bucket policy found. Creating HTTPS-only policy."

        POLICY_FILE="$(mktemp)"

        cat > "$POLICY_FILE" <<POLICY_EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$BUCKET",
        "arn:aws:s3:::$BUCKET/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY_EOF

        aws s3api put-bucket-policy \
            --bucket "$BUCKET" \
            --region "$REGION" \
            --policy "file://$POLICY_FILE"

        rm -f "$POLICY_FILE"
    else
        ERROR_MESSAGE="$(cat "$POLICY_ERROR")"
        rm -f "$POLICY_ERROR"
        fail "Could not verify bucket policy: $ERROR_MESSAGE"
    fi
fi

rm -f "$POLICY_ERROR"

# Verify existing remote Terraform state.
log "Checking existing remote Terraform state"

STATE_ERROR="$(mktemp)"

if aws s3api head-object \
    --bucket "$BUCKET" \
    --key "$STATE_KEY" \
    --region "$REGION" >/dev/null 2>"$STATE_ERROR"; then

    log "Existing remote state found. It will be preserved."

else
    if grep -q "404" "$STATE_ERROR"; then
        log "No existing infrastructure state object found."
    else
        ERROR_MESSAGE="$(cat "$STATE_ERROR")"
        rm -f "$STATE_ERROR"
        fail "Could not verify remote state: $ERROR_MESSAGE"
    fi
fi

rm -f "$STATE_ERROR"

# Generate Terraform backend configuration.
log "Generating backend configuration"

BACKEND_FILE="$TF_DIR/backend.hcl"
TEMP_BACKEND="$(mktemp)"

cat > "$TEMP_BACKEND" <<BACKEND_EOF
bucket       = "$BUCKET"
key          = "$STATE_KEY"
region       = "$REGION"
encrypt      = true
use_lockfile = true
BACKEND_EOF

mv "$TEMP_BACKEND" "$BACKEND_FILE"
chmod 600 "$BACKEND_FILE"

log "Generated: $BACKEND_FILE"

# Preserve existing cached backend metadata.
CACHE_FILE="$TF_DIR/.terraform/terraform.tfstate"

if [[ -f "$CACHE_FILE" ]]; then
    BACKUP_FILE="$CACHE_FILE.backup.$(date '+%Y%m%d%H%M%S')"
    cp -p "$CACHE_FILE" "$BACKUP_FILE"
    log "Cached backend metadata backed up: $BACKUP_FILE"
fi

# Initialize Terraform using the generated backend configuration.
log "Initializing Terraform with S3 backend"

cd "$TF_DIR"

terraform init \
    -input=false \
    -reconfigure \
    -backend-config="$BACKEND_FILE"

log "Terraform backend initialization completed."
log "Remote state: s3://$BUCKET/$STATE_KEY"
