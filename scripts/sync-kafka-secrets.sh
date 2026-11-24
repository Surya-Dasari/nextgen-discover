#!/usr/bin/env bash
set -euo pipefail

SOURCE_NAMESPACE="${SOURCE_NAMESPACE:-nextgen-kafka}"
TARGET_NAMESPACE="${TARGET_NAMESPACE:-nextgen-discover}"

SECRETS=(
  user-service-producer
  nextgen-kafka-cluster-ca-cert
)

for SECRET in "${SECRETS[@]}"; do
  echo "Synchronizing ${SECRET}"

  kubectl get secret "$SECRET" \
    -n "$SOURCE_NAMESPACE" -o json |
    jq --arg ns "$TARGET_NAMESPACE" '{
      apiVersion: .apiVersion,
      kind: .kind,
      metadata: {
        name: .metadata.name,
        namespace: $ns
      },
      type: .type,
      data: .data
    }' |
    kubectl apply -f -
done

echo "Kafka TLS Secrets synchronized successfully."
