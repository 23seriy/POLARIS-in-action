#!/usr/bin/env bash
# Start Minikube, install Polaris dashboard + webhook via Helm.
set -euo pipefail

PROFILE="polaris-demo"
K8S_VERSION="v1.32.0"
CPUS=4
MEMORY=4096
POLARIS_NS="polaris"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

echo ""
echo "================================================"
echo "  🔍 Polaris in Action — Cluster Setup"
echo "================================================"
echo ""

# Reuse or recreate profile
if minikube status -p "$PROFILE" &>/dev/null 2>&1; then
    warn "Minikube profile '$PROFILE' already exists."
    read -rp "Delete and recreate? (y/N) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Deleting existing profile..."
        minikube delete -p "$PROFILE"
    else
        info "Reusing existing profile."
        echo ""
        echo "  Next: ./scripts/03-deploy-app.sh"
        exit 0
    fi
fi

# Start Minikube
info "Starting Minikube (profile=$PROFILE, k8s=$K8S_VERSION, CPUs=$CPUS, RAM=${MEMORY}MB)..."
minikube start \
    -p "$PROFILE" \
    --kubernetes-version="$K8S_VERSION" \
    --cpus="$CPUS" \
    --memory="$MEMORY" \
    --driver=docker

# Add Helm repos
info "Adding Helm repositories..."
helm repo add fairwinds-stable https://charts.fairwinds.com/stable --force-update
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update

# Install cert-manager — required for the Polaris webhook TLS certificates (scenario 8).
info "Installing cert-manager (required for webhook TLS)..."
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set crds.install=true \
    --wait --timeout=3m

info "Waiting for cert-manager (up to 3 min)..."
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=3m
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=3m

# Helpers for surfacing what went wrong when a deploy gets stuck.
diagnose_namespace() {
    local ns=$1
    warn "Pods in $ns:"
    kubectl get pods -n "$ns" -o wide || true
    warn "Recent events in $ns (last 20):"
    kubectl get events -n "$ns" --sort-by=.lastTimestamp 2>/dev/null | tail -20 || true
    warn "Pull errors / Warning conditions in $ns:"
    kubectl describe pods -n "$ns" 2>/dev/null \
        | grep -E "Events:|Warning|Failed|ImagePull|ErrImage|OOMKilled" \
        | head -20 || true
}

# Install Polaris — dashboard mode.
# We start with the dashboard (no webhook) so we can see violations before
# we start rejecting them.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

info "Installing Polaris Dashboard via Helm..."
helm upgrade --install polaris fairwinds-stable/polaris \
    --namespace "$POLARIS_NS" \
    --create-namespace \
    --set dashboard.enable=true \
    --set webhook.enable=false \
    --set-file config="$PROJECT_DIR/polaris/config.yaml"

info "Waiting for Polaris Dashboard (up to 5 min)..."
if ! kubectl -n "$POLARIS_NS" rollout status deploy --timeout=5m; then
    error "Polaris Dashboard did not become ready in 5 min."
    diagnose_namespace "$POLARIS_NS"
    exit 1
fi

# Create the demo namespace up front
info "Creating namespace 'polaris-demo'..."
kubectl apply -f "$PROJECT_DIR/k8s/namespace.yaml"

echo ""
info "Cluster + Polaris status:"
kubectl get pods -n "$POLARIS_NS"
echo ""

echo "================================================"
echo "  ✅ Polaris cluster ready!"
echo ""
echo "  Cluster:       $PROFILE"
echo "  K8s:           $K8S_VERSION"
echo "  Polaris NS:    $POLARIS_NS"
echo "  Dashboard:     enabled"
echo "  Webhook:       disabled (enable in scenario 8)"
echo ""
echo "  Next: ./scripts/03-deploy-app.sh"
echo "================================================"
