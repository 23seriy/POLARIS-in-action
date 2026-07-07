# 🔍 Polaris in Action

A hands-on project demonstrating **Polaris** — an open source policy engine for Kubernetes that validates and remediates resource configuration. Built around an NBA scenario: the cluster is the arena, Polaris is the quality assurance inspector, and your job is to ensure every workload meets security, efficiency, and reliability standards before game day.

The demo deploys one compliant app (`game-day-api`) and a "rogue" workload (`bench-warmer`) with seven manifest variants that each violate a different Polaris check. You'll see Polaris catch violations across its three operational modes: **Dashboard**, **Webhook**, and **CLI**.

![Polaris](https://img.shields.io/badge/Polaris-10.2+-4BB5E3?logo=kubernetes&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-local-F7B93E?logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)

## 📖 Documentation

- **[CLAUDE.md](CLAUDE.md)** — Architecture, file structure, and common development tasks
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — How to contribute (features, fixes, docs)
- **[TESTING.md](TESTING.md)** — Manual and automated testing procedures
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — Common issues and solutions
- **[SECURITY.md](SECURITY.md)** — Security policies and responsible disclosure
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — Community guidelines

## 🏗️ Architecture

```text
                ┌──────────────────────────────────────────────────┐
                │                  Minikube Cluster                 │
                │                                                  │
                │   ┌──────────────────────────────────────────┐   │
   kubectl ───► │   │      Polaris (3 modes)                    │   │
   apply ...   │   │                                            │   │
                │   │  📊 Dashboard — visualize violations      │   │
                │   │  🛡️  Webhook   — reject at admission      │   │
                │   │  🔧 CLI       — audit YAML locally        │   │
                │   └────────────────────┬─────────────────────┘   │
                │                        │                          │
                │     ✅ admitted         │      ❌ rejected         │
                │   ┌─────────────────┐  │    "runAsRootAllowed"    │
                │   │ game-day-api   │  │    "tagNotSpecified"     │
                │   │ (non-root,     │  │    "cpuLimitsMissing"    │
                │   │  probes, …)    │  │    "runAsPrivileged"     │
                │   └─────────────────┘  │                          │
                │                        ▼                          │
                │             ┌────────────────────┐                │
                │             │  bench-warmer      │  (one of seven │
                │             │  (rogue variants)  │   bad-pods)    │
                │             └────────────────────┘                │
                │                                                  │
                │   30+ built-in checks + custom JSON Schema       │
                │   Security · Efficiency · Reliability             │
                └──────────────────────────────────────────────────┘
```

**game-day-api** — Compliant workload. Pinned tag, resource requests + limits, probes, non-root, drop ALL caps, read-only filesystem. Passes every Polaris check.

**bench-warmer** — The rogue workload. Used as the base image for seven bad-pod manifests, each triggering one or more Polaris violations.

## 📋 What You'll Learn

| Polaris Feature | What It Does | Demo Scenario |
|---|---|---|
| **CLI Audit** | Scan local YAML files without a cluster | Scenarios 1–5, 7 |
| **Dashboard** | Cluster-wide violation visibility with health score | Scenario 6 |
| **Webhook (Validating)** | Block bad pods at admission time | Scenario 8 |
| **Strict Mode** | Promote all warnings to danger (blocking) | Scenario 9 |
| **Custom Checks** | JSON Schema-based policy enforcement | Scenario 10 |
| **Security Checks** | runAsRoot, privileged, capabilities, hostNetwork | Scenarios 2, 5–7 |
| **Efficiency Checks** | CPU/memory requests and limits | Scenario 5 |
| **Reliability Checks** | Probes, image tags, pull policy | Scenarios 3–4 |

## 🚀 Quick Start

### Step 0: Clone the Repository

```bash
git clone https://github.com/23seriy/polaris-in-action.git
cd polaris-in-action
```

### Prerequisites

- **macOS** (scripts use Homebrew; adapt for Linux)
- **Docker Desktop** running
- ~4 GB RAM available for Minikube

### Step 1: Install Tools

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
```

Installs `minikube`, `kubectl`, `helm`, and the `polaris` CLI via Homebrew.

### Step 2: Start Cluster + Install Polaris

```bash
./scripts/02-start-cluster.sh
```

Creates the `polaris-demo` Minikube profile on **Kubernetes v1.32.0**, installs Polaris via Helm (dashboard mode initially — webhook is enabled during the demo).

### Step 3: Build & Deploy Apps

```bash
./scripts/03-deploy-app.sh
```

- Builds `game-day-api:v1` and `bench-warmer:v1` using Minikube's Docker daemon
- Deploys the compliant `game-day-api` to the cluster
- Tags `bench-warmer` as both `:v1` and `:latest` for demo scenarios

### Step 4: Reach the Compliant App

```bash
kubectl port-forward svc/game-day-api 9080:8080 -n polaris-demo
```

```bash
curl http://localhost:9080/games
curl http://localhost:9080/live
curl http://localhost:9080/health
```

### Step 5: Run the Demo Scenarios

```bash
./scripts/04-demo-scenarios.sh
```

Ten interactive scenarios, one Polaris feature at a time.

## 🎮 Demo Scenarios

### 1. CLI Audit — The Starting Lineup Passes Inspection

```bash
polaris audit --audit-path k8s/game-day-api.yaml --config polaris/config.yaml --format pretty
```

The compliant app passes every check — it's ready for game day.

### 2. CLI Audit — Runs as Root

```bash
polaris audit --audit-path k8s/bad-pods/01-runs-as-root.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
```

Security violation: `runAsRootAllowed` — no root access allowed on game day.

### 3. CLI Audit — Uses :latest Tag

Reliability violation: `tagNotSpecified` — no undrafted players on the court.

### 4. CLI Audit — Missing Probes

Reliability violation: `readinessProbeMissing` + `livenessProbeMissing` — every player needs a physical.

### 5. CLI Audit — No Resource Limits

Efficiency violation: all four resource checks fail — nobody gets unlimited minutes.

### 6. Dashboard — The Scoreboard Shows All Violations

Deploy all bad pods and open the Polaris Dashboard:

```bash
kubectl port-forward svc/polaris-dashboard 8080:80 -n polaris
open http://localhost:8080
```

The dashboard shows a cluster-wide health score grouped by Security, Efficiency, and Reliability.

### 7. CLI Audit — Maximum Violations

Audit the worst offenders: privileged containers, host network access, insecure capabilities.

### 8. Webhook — The Bouncer at the Door

Enable the Polaris validating webhook and watch it reject bad pods at admission time:

```bash
helm upgrade polaris fairwinds-stable/polaris --namespace polaris \
    --set dashboard.enable=true --set webhook.enable=true
```

### 9. Strict Mode — Full Lockdown

Upgrade to `config-strict.yaml` where ALL checks are promoted to danger — every violation blocks admission.

### 10. Custom Check — Every Player Needs a Jersey

Demonstrate Polaris custom checks using JSON Schema: require every pod to have a `team` label.

## 🔧 Useful Commands

```bash
# CLI: Audit a YAML file locally (no cluster needed)
polaris audit --audit-path k8s/game-day-api.yaml --config polaris/config.yaml --format pretty

# CLI: Audit with score only
polaris audit --audit-path k8s/ --config polaris/config.yaml --format score

# Dashboard: Port-forward to Polaris UI
kubectl port-forward svc/polaris-dashboard 8080:80 -n polaris
open http://localhost:8080

# Check Polaris pods
kubectl get pods -n polaris

# View webhook logs
kubectl logs -n polaris deploy/polaris-webhook -f

# View dashboard logs
kubectl logs -n polaris deploy/polaris-dashboard -f

# Port-forward to the compliant app
kubectl port-forward svc/game-day-api 9080:8080 -n polaris-demo
curl http://localhost:9080/games
```

## 📁 Project Structure

```text
polaris-in-action/
├── apps/
│   ├── game-day-api/            # Compliant Flask app (non-root, multi-stage)
│   │   ├── app.py               # NBA game-day scores
│   │   ├── Dockerfile           # Multi-stage, runs as UID 10001
│   │   └── requirements.txt
│   └── bench-warmer/            # Rogue base image, reused by bad-pod variants
│       ├── app.py
│       ├── Dockerfile
│       └── requirements.txt
├── k8s/
│   ├── namespace.yaml           # polaris-demo
│   ├── game-day-api.yaml        # Compliant Deployment + Service
│   └── bad-pods/
│       ├── 01-runs-as-root.yaml
│       ├── 02-uses-latest-tag.yaml
│       ├── 03-no-probes.yaml
│       ├── 04-no-resources.yaml
│       ├── 05-privileged.yaml
│       ├── 06-host-network.yaml
│       └── 07-insecure-capabilities.yaml
├── polaris/
│   ├── config.yaml              # Default config (danger + warning levels)
│   ├── config-strict.yaml       # Strict config (all checks at danger)
│   └── config-mutating.yaml     # Mutating webhook config (auto-remediate)
├── scripts/
│   ├── 01-install-prerequisites.sh
│   ├── 02-start-cluster.sh
│   ├── 03-deploy-app.sh
│   ├── 04-demo-scenarios.sh
│   └── 05-teardown.sh
├── docs/
│   └── medium-story.md          # Full Medium article
├── README.md
├── LICENSE
└── .gitignore
```

## 🧹 Teardown

```bash
./scripts/05-teardown.sh
```

Uninstalls Polaris, deletes the demo namespace, and removes the Minikube cluster.

## 💡 Key Takeaways

1. **Three modes, one tool.** Dashboard for visibility, webhook for enforcement, CLI for CI/CD — Polaris covers the entire lifecycle.

2. **30+ built-in checks.** Security, efficiency, and reliability checks are included out of the box — no YAML policy writing required for the basics.

3. **Custom checks via JSON Schema.** When built-in checks aren't enough, write custom policies in JSON Schema — no DSL learning required.

4. **Severity levels control enforcement.** Warning-level checks inform; danger-level checks block. Promote warnings to danger when you're ready for strict mode.

5. **Mutating webhook auto-remediates.** Instead of rejecting bad pods, Polaris can fix them automatically — pull policy, resource limits, security context, and more.

6. **CLI enables shift-left.** Audit manifests in CI/CD pipelines before they reach the cluster — catch violations at the PR level.

7. **Dashboard makes compliance visible.** A single health score shows cluster-wide compliance — auditors see a UI, not raw YAML.

## 📚 Resources

- [Polaris Documentation](https://polaris.docs.fairwinds.com)
- [Polaris GitHub Repository](https://github.com/FairwindsOps/polaris)
- [Polaris Helm Chart](https://github.com/FairwindsOps/charts/tree/master/stable/polaris)
- [Fairwinds Community Slack](https://join.slack.com/t/fairwindscommunity/shared_invite/zt-2na8gtwb4-DGQ4qgmQbczQyB2NlFlYQQ)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 📝 License

MIT — Use freely for learning, demos, and presentations.
