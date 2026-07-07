#!/usr/bin/env bash
# Build and deploy the sample apps into the Minikube cluster.
set -euo pipefail

PROFILE="polaris-demo"
NAMESPACE="polaris-demo"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "================================================"
echo "  🔍 Polaris in Action — Build & Deploy"
echo "================================================"
echo ""

# Switch to Minikube's Docker daemon so images are available in-cluster
info "Switching to Minikube's Docker daemon..."
eval "$(minikube docker-env -p "$PROFILE")"

# Build the compliant app
info "Building game-day-api:v1..."
docker build -t game-day-api:v1 "$PROJECT_DIR/apps/game-day-api"

# Build the rogue app
info "Building bench-warmer:v1..."
docker build -t bench-warmer:v1 "$PROJECT_DIR/apps/bench-warmer"
# Also tag as :latest for the latest-tag scenario
docker tag bench-warmer:v1 bench-warmer:latest

# Deploy the compliant app
info "Deploying game-day-api to namespace '$NAMESPACE'..."
kubectl apply -f "$PROJECT_DIR/k8s/namespace.yaml"

# Patch the deployment to use IfNotPresent since images are loaded locally
sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' \
    "$PROJECT_DIR/k8s/game-day-api.yaml" | kubectl apply -f -

info "Waiting for game-day-api rollout..."
kubectl -n "$NAMESPACE" rollout status deploy/game-day-api --timeout=2m

echo ""
info "Deployed pods:"
kubectl get pods -n "$NAMESPACE"
echo ""

echo "================================================"
echo "  ✅ Apps built and deployed!"
echo ""
echo "  game-day-api:v1     → Compliant workload (deployed)"
echo "  bench-warmer:v1     → Rogue workload (image only)"
echo "  bench-warmer:latest → For :latest tag scenario"
echo ""
echo "  Port-forward to the app:"
echo "    kubectl port-forward svc/game-day-api 9080:8080 -n $NAMESPACE"
echo "    curl http://localhost:9080/games"
echo ""
echo "  Next: ./scripts/04-demo-scenarios.sh"
echo "================================================"
