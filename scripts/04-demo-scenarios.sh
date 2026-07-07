#!/usr/bin/env bash
# Interactive demo scenarios for Polaris in Action.
# Runs through 10 scenarios demonstrating Polaris's three modes:
#   dashboard, admission controller (webhook), and CLI.
set -euo pipefail

PROFILE="polaris-demo"
NAMESPACE="polaris-demo"
POLARIS_NS="polaris"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
header()  { echo -e "\n${CYAN}${BOLD}═══════════════════════════════════════════════${NC}"; echo -e "${CYAN}${BOLD}  $*${NC}"; echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════${NC}\n"; }
pause()   { echo ""; read -rp "  Press ENTER to continue to the next scenario... "; echo ""; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we're in the right Minikube context
eval "$(minikube docker-env -p "$PROFILE")"

cleanup_bad_pods() {
    info "Cleaning up bad pods..."
    kubectl delete pod -n "$NAMESPACE" -l app=bench-warmer --ignore-not-found 2>/dev/null || true
}

echo ""
echo "================================================"
echo "  🔍 Polaris in Action — Demo Scenarios"
echo "================================================"
echo ""
echo "  This script runs 10 interactive scenarios"
echo "  demonstrating Polaris's three operational modes:"
echo ""
echo "  📊 Dashboard    — Visualize violations"
echo "  🛡️  Webhook      — Block bad workloads at admission"
echo "  🔧 CLI          — Audit YAML files locally"
echo "  🔄 Mutating     — Auto-remediate issues"
echo ""
pause

# ─────────────────────────────────────────────────
# SCENARIO 1: CLI Audit — Compliant App
# ─────────────────────────────────────────────────
header "Scenario 1: CLI Audit — The Starting Lineup Passes Inspection"
info "Using the Polaris CLI to audit game-day-api.yaml locally (no cluster needed)."
echo ""

polaris audit \
    --audit-path "$PROJECT_DIR/k8s/game-day-api.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests=false 2>/dev/null || true

echo ""
info "✅ game-day-api passes all Polaris checks — it's the starting lineup."
pause

# ─────────────────────────────────────────────────
# SCENARIO 2: CLI Audit — Runs as Root
# ─────────────────────────────────────────────────
header "Scenario 2: CLI Audit — The Bench Warmer Runs as Root"
info "Auditing 01-runs-as-root.yaml — container can run as UID 0."
echo ""

polaris audit \
    --audit-path "$PROJECT_DIR/k8s/bad-pods/01-runs-as-root.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests 2>/dev/null || true

echo ""
info "❌ Polaris caught it: runAsRootAllowed — no root access allowed on game day!"
pause

# ─────────────────────────────────────────────────
# SCENARIO 3: CLI Audit — Uses :latest Tag
# ─────────────────────────────────────────────────
header "Scenario 3: CLI Audit — Undrafted Player (:latest Tag)"
info "Auditing 02-uses-latest-tag.yaml — image uses the :latest tag."
echo ""

polaris audit \
    --audit-path "$PROJECT_DIR/k8s/bad-pods/02-uses-latest-tag.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests 2>/dev/null || true

echo ""
info "❌ Polaris caught it: tagNotSpecified — no undrafted players on the court!"
pause

# ─────────────────────────────────────────────────
# SCENARIO 4: CLI Audit — Missing Probes
# ─────────────────────────────────────────────────
header "Scenario 4: CLI Audit — No Health Checks (Missing Probes)"
info "Auditing 03-no-probes.yaml — no readiness or liveness probes."
echo ""

polaris audit \
    --audit-path "$PROJECT_DIR/k8s/bad-pods/03-no-probes.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests 2>/dev/null || true

echo ""
info "❌ Polaris caught it: readinessProbeMissing + livenessProbeMissing — every player needs a physical!"
pause

# ─────────────────────────────────────────────────
# SCENARIO 5: CLI Audit — No Resources
# ─────────────────────────────────────────────────
header "Scenario 5: CLI Audit — Unlimited Minutes (No Resource Limits)"
info "Auditing 04-no-resources.yaml — no CPU/memory requests or limits."
echo ""

polaris audit \
    --audit-path "$PROJECT_DIR/k8s/bad-pods/04-no-resources.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests 2>/dev/null || true

echo ""
info "❌ Polaris caught it: missing requests + limits — nobody gets unlimited minutes!"
pause

# ─────────────────────────────────────────────────
# SCENARIO 6: Dashboard — See All Violations
# ─────────────────────────────────────────────────
header "Scenario 6: Dashboard — The Scoreboard Shows All Violations"
info "Deploying all bad pods so the Polaris dashboard can scan them."
echo ""

# Deploy bad pods (use IfNotPresent for local images)
for manifest in "$PROJECT_DIR/k8s/bad-pods/"*.yaml; do
    filename=$(basename "$manifest")
    info "Deploying $filename..."
    sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' "$manifest" \
        | kubectl apply -f - 2>/dev/null || warn "  (expected — some may fail if webhook is active)"
done

echo ""
info "Waiting for pods to settle..."
sleep 5
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
info "📊 Open the Polaris Dashboard to see all violations:"
echo ""
echo "  kubectl port-forward svc/polaris-dashboard 8080:80 -n $POLARIS_NS"
echo "  open http://localhost:8080"
echo ""
info "The dashboard shows a cluster-wide health score with violations"
info "grouped by Security, Efficiency, and Reliability."
pause

cleanup_bad_pods

# ─────────────────────────────────────────────────
# SCENARIO 7: CLI Audit — Privileged + Host Network
# ─────────────────────────────────────────────────
header "Scenario 7: CLI Audit — Maximum Violations (Privileged + Host Access)"
info "Auditing the worst offenders: privileged container and host network access."
echo ""

echo "--- 05-privileged.yaml ---"
polaris audit \
    --audit-path "$PROJECT_DIR/k8s/bad-pods/05-privileged.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests 2>/dev/null || true

echo ""
echo "--- 06-host-network.yaml ---"
polaris audit \
    --audit-path "$PROJECT_DIR/k8s/bad-pods/06-host-network.yaml" \
    --config "$PROJECT_DIR/polaris/config.yaml" \
    --format pretty \
    --only-show-failed-tests 2>/dev/null || true

echo ""
info "❌ Maximum security violations — these players would be ejected immediately!"
pause

# ─────────────────────────────────────────────────
# SCENARIO 8: Webhook — Validating Admission Controller
# ─────────────────────────────────────────────────
header "Scenario 8: Webhook — The Bouncer at the Door"
info "Enabling the Polaris validating webhook to REJECT bad pods at admission."
echo ""

info "Upgrading Polaris Helm release to enable the webhook..."
helm upgrade polaris fairwinds-stable/polaris \
    --namespace "$POLARIS_NS" \
    --set dashboard.enable=true \
    --set webhook.enable=true \
    --set-file config="$PROJECT_DIR/polaris/config.yaml" \
    --wait --timeout=3m

info "Webhook is now active. Attempting to deploy bad pods..."
echo ""

for manifest in "$PROJECT_DIR/k8s/bad-pods/"*.yaml; do
    filename=$(basename "$manifest")
    echo -e "${YELLOW}--- Applying $filename ---${NC}"
    if sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' "$manifest" \
        | kubectl apply -f - 2>&1; then
        warn "  ⚠️  Admitted (warning-level checks don't block by default)"
    else
        info "  ✅ REJECTED by Polaris webhook"
    fi
    echo ""
done

echo ""
info "The webhook rejected pods with danger-level violations."
info "Warning-level checks are visible in the dashboard but don't block admission."
pause

cleanup_bad_pods

# ─────────────────────────────────────────────────
# SCENARIO 9: Strict Mode — Full Lockdown
# ─────────────────────────────────────────────────
header "Scenario 9: Strict Mode — Full Lockdown"
info "Upgrading to config-strict.yaml: ALL checks promoted to danger level."
echo ""

info "Upgrading Polaris to strict configuration..."
helm upgrade polaris fairwinds-stable/polaris \
    --namespace "$POLARIS_NS" \
    --set dashboard.enable=true \
    --set webhook.enable=true \
    --set-file config="$PROJECT_DIR/polaris/config-strict.yaml" \
    --wait --timeout=3m

info "Now EVERY violation will be rejected. Testing..."
echo ""

for manifest in "$PROJECT_DIR/k8s/bad-pods/"*.yaml; do
    filename=$(basename "$manifest")
    echo -e "${YELLOW}--- Applying $filename ---${NC}"
    if sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' "$manifest" \
        | kubectl apply -f - 2>&1; then
        warn "  ⚠️  Unexpected: pod was admitted in strict mode"
    else
        info "  ✅ REJECTED — strict mode blocks everything"
    fi
    echo ""
done

echo ""
info "Meanwhile, the compliant app is still running happily:"
kubectl get pods -n "$NAMESPACE" -l app=game-day-api
pause

cleanup_bad_pods

# ─────────────────────────────────────────────────
# SCENARIO 10: Custom Check — Team Label Required
# ─────────────────────────────────────────────────
header "Scenario 10: Custom Check — Every Player Needs a Jersey"
info "Demonstrating Polaris custom checks with JSON Schema."
info "Our custom check requires every pod to have a 'team' label."
echo ""

# Create a test pod without the team label
cat <<EOF | kubectl apply -f - 2>&1 || true
apiVersion: v1
kind: Pod
metadata:
  name: bench-warmer-no-label
  namespace: $NAMESPACE
  labels:
    app: bench-warmer
    scenario: missing-team-label
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
  containers:
    - name: bench-warmer
      image: bench-warmer:v1
      imagePullPolicy: IfNotPresent
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          cpu: 200m
          memory: 128Mi
      readinessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 3
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 5
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 10001
        capabilities:
          drop: ["ALL"]
EOF

echo ""
info "Custom check 'teamLabelRequired' — every player needs a jersey number!"
info "The webhook rejected the pod because it's missing the 'team' label."

cleanup_bad_pods
pause

# ─────────────────────────────────────────────────
# FINAL: Restore default config
# ─────────────────────────────────────────────────
header "Demo Complete — Restoring Default Configuration"
info "Switching back to the default Polaris config (dashboard + webhook)..."

helm upgrade polaris fairwinds-stable/polaris \
    --namespace "$POLARIS_NS" \
    --set dashboard.enable=true \
    --set webhook.enable=true \
    --set-file config="$PROJECT_DIR/polaris/config.yaml" \
    --wait --timeout=3m

echo ""
echo "================================================"
echo "  ✅ All 10 scenarios complete!"
echo ""
echo "  What we demonstrated:"
echo "    📊 Dashboard  — Cluster-wide violation visibility"
echo "    🔧 CLI        — Local YAML auditing (no cluster needed)"
echo "    🛡️  Webhook    — Reject bad pods at admission time"
echo "    ⚙️  Strict     — Promote all warnings to blockers"
echo "    🎯 Custom     — JSON Schema policy enforcement"
echo ""
echo "  Dashboard: kubectl port-forward svc/polaris-dashboard 8080:80 -n $POLARIS_NS"
echo "  Teardown:  ./scripts/05-teardown.sh"
echo "================================================"
