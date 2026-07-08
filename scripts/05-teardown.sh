#!/usr/bin/env bash
# Tear everything down: uninstall Polaris, delete namespaces, remove Minikube.
set -euo pipefail

PROFILE="polaris-demo"
NAMESPACE="polaris-demo"
POLARIS_NS="polaris"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

echo ""
echo "================================================"
echo "  🔍 Polaris in Action — Teardown"
echo "================================================"
echo ""

read -rp "This will delete the Minikube cluster '$PROFILE'. Continue? (y/N) " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    info "Cancelled."
    exit 0
fi

# Delete demo namespace
info "Deleting demo namespace..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found --timeout=60s 2>/dev/null || true

# Uninstall Polaris
info "Uninstalling Polaris..."
helm uninstall polaris -n "$POLARIS_NS" 2>/dev/null || true
kubectl delete namespace "$POLARIS_NS" --ignore-not-found 2>/dev/null || true

# Uninstall cert-manager
info "Uninstalling cert-manager..."
helm uninstall cert-manager -n cert-manager 2>/dev/null || true
kubectl delete namespace cert-manager --ignore-not-found 2>/dev/null || true

# Delete Minikube profile
info "Deleting Minikube profile '$PROFILE'..."
minikube delete -p "$PROFILE"

echo ""
echo "================================================"
echo "  ✅ Teardown complete. System is clean."
echo "================================================"
