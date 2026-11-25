#!/usr/bin/env bash
#
# Bootstrap the NextGen Discover Argo CD root Application.
#
# Prerequisites:
#   - kubectl configured for the intended Kubernetes cluster
#   - Argo CD already installed
#   - Python 3 and Git installed
#   - GitOps manifests committed and pushed
#
# Optional environment variables:
#   GIT_REPO_URL       Git repository URL (defaults to origin)
#   GIT_BRANCH         Git branch (defaults to current branch)
#   ARGOCD_NAMESPACE   Defaults to argocd
#   WAIT_TIMEOUT       Defaults to 180s

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(git -C "${SCRIPT_DIR}/.." rev-parse --show-toplevel)"

ROOT_APPLICATION_FILE="${REPOSITORY_ROOT}/gitops/root/application.yaml"
CHILD_APPLICATION_FILE="${REPOSITORY_ROOT}/gitops/applications/nextgen-discover.yaml"

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180s}"

log() {
  printf '[INFO] %s\n' "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

for command_name in kubectl python3 git; do
  command -v "$command_name" >/dev/null 2>&1 ||
    fail "${command_name} is required."
done

[[ -f "$ROOT_APPLICATION_FILE" ]] ||
  fail "Root Application manifest not found."

[[ -f "$CHILD_APPLICATION_FILE" ]] ||
  fail "Child Application manifest not found."

GIT_REPO_URL="${GIT_REPO_URL:-$(git -C "$REPOSITORY_ROOT" remote get-url origin)}"
GIT_BRANCH="${GIT_BRANCH:-$(git -C "$REPOSITORY_ROOT" branch --show-current)}"

[[ -n "$GIT_REPO_URL" ]] || fail "GIT_REPO_URL is empty."
[[ -n "$GIT_BRANCH" ]] || fail "GIT_BRANCH is empty."

log "Repository: $GIT_REPO_URL"
log "Branch: $GIT_BRANCH"
log "Kubernetes context: $(kubectl config current-context)"

# Verify that both Application manifests reference the same
# repository and branch as this checkout.
python3 - "$ROOT_APPLICATION_FILE" "$CHILD_APPLICATION_FILE" \
  "$GIT_REPO_URL" "$GIT_BRANCH" <<'PYTHON'
import re
import sys
from pathlib import Path

root_file, child_file, expected_repo, expected_branch = sys.argv[1:]
errors = []

for filename in (root_file, child_file):
    content = Path(filename).read_text()

    repositories = re.findall(
        r'(?m)^\s*repoURL:\s*["\']?([^"\'\s]+)', content
    )
    branches = re.findall(
        r'(?m)^\s*targetRevision:\s*["\']?([^"\'\s]+)', content
    )

    if not repositories or any(value != expected_repo for value in repositories):
        errors.append(f"{filename}: repoURL does not match {expected_repo}")

    if not branches or any(value != expected_branch for value in branches):
        errors.append(f"{filename}: targetRevision does not match {expected_branch}")

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    print(
        "Update repoURL and targetRevision in both manifests, "
        "commit and push the changes, then rerun this script.",
        file=sys.stderr,
    )
    raise SystemExit(1)

print("GitOps repository and branch configuration verified.")
PYTHON

log "Checking Kubernetes connectivity..."
kubectl cluster-info >/dev/null

log "Checking Argo CD namespace..."
kubectl get namespace "$ARGOCD_NAMESPACE" >/dev/null ||
  fail "Argo CD namespace does not exist. Install Argo CD first."

log "Waiting for Argo CD Pods to become Ready..."
kubectl wait \
  --for=condition=Ready \
  pod \
  --all \
  --namespace "$ARGOCD_NAMESPACE" \
  --timeout="$WAIT_TIMEOUT"

log "Registering root Application..."
kubectl apply -f "$ROOT_APPLICATION_FILE"

log "Waiting for root Application synchronization and health..."
kubectl wait \
  --for=jsonpath='{.status.sync.status}'=Synced \
  application.argoproj.io/nextgen-discover-root \
  --namespace "$ARGOCD_NAMESPACE" \
  --timeout="$WAIT_TIMEOUT"

kubectl wait \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application.argoproj.io/nextgen-discover-root \
  --namespace "$ARGOCD_NAMESPACE" \
  --timeout="$WAIT_TIMEOUT"

log "Waiting for child Application registration..."
kubectl wait \
  --for=create \
  application.argoproj.io/nextgen-discover \
  --namespace "$ARGOCD_NAMESPACE" \
  --timeout="$WAIT_TIMEOUT"

log "Waiting for child Application synchronization..."
kubectl wait \
  --for=jsonpath='{.status.sync.status}'=Synced \
  application.argoproj.io/nextgen-discover \
  --namespace "$ARGOCD_NAMESPACE" \
  --timeout="$WAIT_TIMEOUT"

log "Waiting for child Application health..."
kubectl wait \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application.argoproj.io/nextgen-discover \
  --namespace "$ARGOCD_NAMESPACE" \
  --timeout="$WAIT_TIMEOUT"

printf '\n'
log "Argo CD bootstrap completed successfully."
kubectl get applications --namespace "$ARGOCD_NAMESPACE"

printf '\n'
log "Inspect application Pods with:"
printf 'kubectl get pods -n nextgen-discover\n'
