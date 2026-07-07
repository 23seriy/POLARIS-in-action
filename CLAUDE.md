# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**polaris-in-action** is a hands-on portfolio project demonstrating Polaris — an open source policy engine for Kubernetes that validates and remediates resource configuration. The demo uses an NBA arena metaphor: the cluster is the arena, Polaris is the quality assurance inspector, and the goal is to ensure every workload meets security, efficiency, and reliability standards.

The project consists of:
- **Two sample apps** (game-day-api: compliant; bench-warmer: non-compliant base image)
- **Seven bad-pod variants** each violating one or more Polaris checks
- **Three Polaris configurations** (default, strict, mutating)
- **Five orchestration scripts** that set up the cluster and run 10 interactive demo scenarios

## Architecture & Key Concepts

### Polaris Three Modes

1. **Dashboard** — A web UI that scans the cluster and shows a health score with violations grouped by Security, Efficiency, and Reliability. No enforcement — just visibility.
2. **Webhook (Validating)** — An admission controller that rejects workloads at `kubectl apply` time. Only blocks `danger`-level checks; `warning`-level checks pass but appear in the dashboard.
3. **CLI** — A command-line tool that audits local YAML files without a cluster. Ideal for CI/CD pipelines.

### Check Categories

- **Security**: runAsRoot, privileged, capabilities, hostNetwork, hostPID, hostIPC, readOnlyFilesystem, privilegeEscalation
- **Efficiency**: CPU/memory requests and limits
- **Reliability**: readiness/liveness probes, image tags, pull policy, replicas, PDB

### Severity Levels

- **danger** — Webhook rejects the workload
- **warning** — Visible in dashboard/CLI but allowed through webhook
- **ignore** — Check is disabled entirely

### Custom Checks

Polaris supports custom checks via JSON Schema. This project includes a custom `teamLabelRequired` check that requires every pod to have a `team` label — defined in `polaris/config.yaml`.

### Demo Scenario Sequence

1. **CLI Audit — Compliant App** — game-day-api passes all checks
2. **CLI Audit — Runs as Root** — Security: runAsRootAllowed
3. **CLI Audit — Uses :latest** — Reliability: tagNotSpecified
4. **CLI Audit — Missing Probes** — Reliability: probes missing
5. **CLI Audit — No Resources** — Efficiency: requests/limits missing
6. **Dashboard** — Deploy bad pods, view cluster-wide health score
7. **CLI Audit — Maximum Violations** — Privileged + host network
8. **Webhook** — Enable validating webhook, reject bad pods
9. **Strict Mode** — All checks promoted to danger
10. **Custom Check** — JSON Schema enforcement of team label

## File Structure

```
polaris-in-action/
├── apps/
│   ├── game-day-api/        # Compliant Flask app (Dockerfile: multi-stage, non-root UID 10001)
│   └── bench-warmer/        # Base image for bad-pod manifests
├── k8s/
│   ├── namespace.yaml       # polaris-demo namespace
│   ├── game-day-api.yaml    # Compliant Deployment + Service
│   └── bad-pods/            # Seven variants, each violating one or more checks
│       ├── 01-runs-as-root.yaml
│       ├── 02-uses-latest-tag.yaml
│       ├── 03-no-probes.yaml
│       ├── 04-no-resources.yaml
│       ├── 05-privileged.yaml
│       ├── 06-host-network.yaml
│       └── 07-insecure-capabilities.yaml
├── polaris/
│   ├── config.yaml          # Default config (danger + warning levels)
│   ├── config-strict.yaml   # All checks at danger (full lockdown)
│   └── config-mutating.yaml # Mutating webhook config (auto-remediate)
├── scripts/
│   ├── 01-install-prerequisites.sh   # Homebrew: minikube, kubectl, helm, polaris
│   ├── 02-start-cluster.sh           # Create Minikube, install Polaris dashboard
│   ├── 03-deploy-app.sh              # Build images, deploy compliant app
│   ├── 04-demo-scenarios.sh          # 10 interactive scenarios
│   └── 05-teardown.sh                # Uninstall Polaris, delete cluster
├── docs/
│   └── medium-story.md
└── README.md
```

## Common Tasks

### Run the Full Demo

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh      # Install tools via Homebrew
./scripts/02-start-cluster.sh              # Create Minikube + install Polaris
./scripts/03-deploy-app.sh                 # Build and deploy apps
./scripts/04-demo-scenarios.sh             # Run 10 interactive scenarios
./scripts/05-teardown.sh                   # Delete cluster
```

### Audit a Single YAML File

```bash
polaris audit --audit-path k8s/bad-pods/01-runs-as-root.yaml \
    --config polaris/config.yaml --format pretty --only-show-failed-tests
```

### Open the Polaris Dashboard

```bash
kubectl port-forward svc/polaris-dashboard 8080:80 -n polaris
open http://localhost:8080
```

### Check Webhook Logs

```bash
kubectl logs -n polaris deploy/polaris-webhook -f
```

### Port-Forward to Compliant App

```bash
kubectl port-forward svc/game-day-api 9080:8080 -n polaris-demo
curl http://localhost:9080/games
```

## Script Internals

All scripts use `set -euo pipefail` for strict error handling. They define helper functions (`info()`, `warn()`) and use color-coded output. Expect interactive prompts (e.g., "Delete and recreate?" in `02-start-cluster.sh`).

### 02-start-cluster.sh: Key Steps

1. Creates Minikube profile `polaris-demo` with K8s v1.32.0
2. Adds the Fairwinds Helm repo
3. Installs Polaris in dashboard-only mode (webhook disabled initially)
4. Creates the `polaris-demo` namespace

### 03-deploy-app.sh: Key Steps

1. Switches to Minikube's Docker daemon (`eval $(minikube docker-env)`)
2. Builds both apps with `docker build`
3. Tags bench-warmer as both `:v1` and `:latest`
4. Deploys game-day-api with `imagePullPolicy: IfNotPresent`

### 04-demo-scenarios.sh: Scenario Pattern

Each scenario:
1. Shows a header with the scenario name and description
2. Runs the Polaris CLI audit or applies manifests to demonstrate the feature
3. Shows results with clear pass/fail indicators
4. Pauses for `Press ENTER to continue`

The script is idempotent — running it twice in a row is safe.

## Development Notes

### Adding a New Check Scenario

1. Create `k8s/bad-pods/NN-<violation>.yaml` (Pod manifest)
2. Add the check to `polaris/config.yaml` if it's not already there
3. Add a new scenario section to `04-demo-scenarios.sh`
4. Update README.md with the new scenario

### Adding a New Bad-Pod Variant

1. Create `k8s/bad-pods/NN-<violation>.yaml` (Pod)
2. Reference it in the appropriate scenario in `04-demo-scenarios.sh`
3. Use the `bench-warmer` image so all variants share the same base

### Modifying Apps

Both `game-day-api` and `bench-warmer` are Flask apps. The compliant app uses a multi-stage build:
- **Stage 1**: Install Python deps into `/install`
- **Stage 2**: Copy installed deps, add non-root user (UID 10001), run as that user

### Polaris Configuration

- `config.yaml` — Default: security checks at danger, efficiency/reliability at warning
- `config-strict.yaml` — Everything at danger (full lockdown mode)
- `config-mutating.yaml` — Enables the mutating webhook for auto-remediation

Custom checks are defined in the `customChecks` section of the config YAML using JSON Schema.

## Polaris vs Kyverno

| Feature | Polaris | Kyverno |
|---------|---------|---------|
| **30+ built-in checks** | ✅ Out of the box | ❌ Write your own |
| **Custom policies** | JSON Schema | YAML (Kyverno CRDs) |
| **Dashboard UI** | ✅ Built-in | Via Policy Reporter |
| **Mutating webhook** | ✅ Auto-remediate | ✅ Mutate rules |
| **Generate resources** | ❌ | ✅ Generate rules |
| **Image verification** | ❌ | ✅ Cosign verifyImages |
| **CLI audit** | ✅ `polaris audit` | ✅ `kyverno apply` |
| **Cleanup policies** | ❌ | ✅ ClusterCleanupPolicy |

Both tools solve the same core problem — policy enforcement — but with different approaches. Polaris is "batteries included" with built-in checks; Kyverno is more flexible with custom CRDs.

## Testing & Validation

Run `04-demo-scenarios.sh` to validate the entire flow. Each scenario demonstrates a specific Polaris capability.

To test individual checks without running the full demo:

```bash
polaris audit --audit-path k8s/<manifest>.yaml --config polaris/config.yaml --format pretty
```
