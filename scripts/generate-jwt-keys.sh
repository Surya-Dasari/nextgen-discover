#!/usr/bin/env bash

generate_jwt_keys() {
    local KEY_DIR="${JWT_KEY_DIR:-$HOME/.nextgen-discover/keys}"
    local PRIVATE_KEY="$KEY_DIR/jwt-private.pem"
    local PUBLIC_KEY="$KEY_DIR/jwt-public.pem"

    if ! command -v openssl >/dev/null 2>&1; then
        echo "ERROR: OpenSSL is required."
        return 1
    fi

    mkdir -p "$KEY_DIR" || return 1
    chmod 700 "$KEY_DIR" || return 1

    if [[ -f "$PRIVATE_KEY" && -f "$PUBLIC_KEY" ]]; then
        echo "Existing JWT key pair found. Reusing it."

    elif [[ -e "$PRIVATE_KEY" || -e "$PUBLIC_KEY" ]]; then
        echo "ERROR: Incomplete key pair. Refusing to overwrite."
        return 1

    else
        echo "Generating RSA 3072-bit JWT key pair..."

        openssl genpkey \
            -algorithm RSA \
            -pkeyopt rsa_keygen_bits:3072 \
            -out "$PRIVATE_KEY" || return 1

        openssl pkey \
            -in "$PRIVATE_KEY" \
            -pubout \
            -out "$PUBLIC_KEY" || return 1

        chmod 600 "$PRIVATE_KEY"
        chmod 644 "$PUBLIC_KEY"

        echo "JWT key pair generated successfully."
    fi

    export TF_VAR_jwt_public_key_pem
    TF_VAR_jwt_public_key_pem="$(cat "$PUBLIC_KEY")" || return 1

    echo "JWT public key exported for Terraform."
    echo "Key directory: $KEY_DIR"
    echo "Private key: $PRIVATE_KEY"
    echo "Public key: $PUBLIC_KEY"
}

generate_jwt_keys
unset -f generate_jwt_keys
