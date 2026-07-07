# Your Kubernetes Workloads Are Failing Best Practices. You Just Don't Know It Yet.

> *30+ checks, zero policy writing, three enforcement modes. This is a hands-on guide to deploying Polaris — Fairwinds' open source Kubernetes best-practices engine — with a working demo you can run on your laptop in 5 minutes.*

<!--
MEDIUM PUBLISHING NOTES:
- Subtitle: "A hands-on guide to Polaris — audit, enforce, and auto-remediate Kubernetes configuration with 30+ built-in checks and zero policy writing"
- Tags: kubernetes, devops, security, cloud-native, best-practices
- Canonical URL: https://github.com/23seriy/polaris-in-action
- Reading time: ~12 min
- Featured image: architecture diagram (see placeholder below)
-->

---

## The Silent Compliance Gap

Here's a stat that should keep you up at night: according to the [2024 Kubernetes benchmark report](https://www.fairwinds.com/kubernetes-config-benchmark-report), **over 70% of workloads** in production Kubernetes clusters have at least one misconfiguration — running as root, missing resource limits, no health probes, or using the `:latest` image tag.

These aren't exotic vulnerabilities. They're **basic hygiene failures** — the Kubernetes equivalent of leaving your front door unlocked, your car running, and your wallet on the dashboard.

The problem isn't that teams don't *know* best practices. It's that **nobody checks**.

Kubernetes will happily schedule a privileged container with no resource limits, no probes, running as root with the `:latest` tag. It doesn't care. It's a scheduler, not a quality inspector.

**You need a quality inspector.**

---

## What is Polaris? (30-Second Version)

[Polaris](https://polaris.docs.fairwinds.com) is an **open source policy engine** by Fairwinds that validates Kubernetes resource configuration against best practices. It includes **30+ built-in checks** covering security, efficiency, and reliability — and you can add custom checks with JSON Schema.

What makes Polaris different from tools like OPA Gatekeeper or Kyverno:

> **Polaris** = batteries included. Install it, get 30+ checks immediately. No policy writing.
> **Kyverno/OPA** = bring your own policies. Powerful but you're starting from scratch.

Think of it like this:

> **Polaris** = the NBA arena's quality assurance inspector. Before game day, they check *everything* — fire exits, scoreboard, equipment, seating. They have a 30-item checklist. They don't write the checklist — it comes with the job.
> **Kyverno** = the bouncer at the door. You tell them exactly who's on the list and who's not. More flexible, but you write *every* rule yourself.

You want both. But if you're starting from zero, Polaris gives you the fastest path from "we check nothing" to "we check everything."

<!-- 📸 IMAGE PLACEHOLDER: Polaris vs Kyverno comparison diagram -->

---

## Three Modes, One Tool

This is the killer feature. Polaris runs in three different modes, covering the entire lifecycle:

### 📊 1. Dashboard — The Scoreboard

A web UI that scans your entire cluster and shows a **health score** with violations grouped by Security, Efficiency, and Reliability.

No enforcement. Just visibility. Deploy it, port-forward, and immediately see where your cluster stands.

**🏀 NBA analogy:** The giant scoreboard in the arena — everyone can see the score, but it doesn't change the game.

### 🛡️ 2. Webhook — The Bouncer at the Door

A validating admission controller that **rejects workloads** at `kubectl apply` time if they fail `danger`-level checks.

Plus an optional **mutating webhook** that auto-fixes issues instead of rejecting — pull policy, resource limits, security context.

**🏀 NBA analogy:** The bouncer who checks your ticket *and* your equipment. Fail the check? You're not getting on the court.

### 🔧 3. CLI — The Pre-Game Checklist

A command-line tool that audits **local YAML files** without a cluster. Run it in CI/CD pipelines to catch violations before they reach the cluster.

```bash
polaris audit --audit-path deployment.yaml --config polaris-config.yaml --format pretty
```

**🏀 NBA analogy:** The equipment inspection *before* the team even arrives at the arena. Catch problems at the factory, not on game day.

---

## The Demo: NBA Game Day Inspection

I built a full working demo that demonstrates all three modes. Following my [*-in-action series*](https://medium.com/@sergeiolshanetski) pattern, it uses NBA game day as the analogy:

| Component | NBA Analogy | What It Does |
|---|---|---|
| **game-day-api** | The starting lineup | Compliant, hardened pod — passes every check |
| **bench-warmer** | The benched player with violations | Bad-pod variants that fail specific checks |
| **Polaris Dashboard** | The arena scoreboard | Cluster-wide violation visibility |
| **Polaris Webhook** | The equipment inspector | Rejects bad pods at admission |
| **Polaris CLI** | The pre-game checklist | Audits YAML locally |

<!-- 📸 IMAGE PLACEHOLDER: Architecture diagram -->

```
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
                │             │  bench-warmer      │                │
                │             │  (7 bad variants)  │                │
                │             └────────────────────┘                │
                │                                                  │
                │   30+ built-in checks + custom JSON Schema       │
                │   Security · Efficiency · Reliability             │
                └──────────────────────────────────────────────────┘
```

Everything runs locally on Minikube. No cloud account needed.

---

## Setup (5 Minutes, Really)

```bash
git clone https://github.com/23seriy/polaris-in-action.git
cd polaris-in-action
chmod +x scripts/*.sh

./scripts/01-install-prerequisites.sh   # minikube, kubectl, helm, polaris CLI
./scripts/02-start-cluster.sh           # minikube + Polaris dashboard
./scripts/03-deploy-app.sh              # build images + deploy demo apps
```

Or run all 10 scenarios interactively:

```bash
./scripts/04-demo-scenarios.sh
```

**Prerequisites:** macOS with Docker Desktop running, ~4 GB RAM available.

---

## The 30+ Built-in Checks

This is what you get **out of the box** — no config file, no policy writing, no YAML CRDs:

### 🔒 Security Checks

| Check | Severity | What It Catches |
|---|---|---|
| `runAsRootAllowed` | danger | Container can run as UID 0 |
| `runAsPrivileged` | danger | Container runs in privileged mode |
| `privilegeEscalationAllowed` | danger | Container can escalate privileges |
| `dangerousCapabilities` | danger | SYS_ADMIN, NET_ADMIN, etc. |
| `insecureCapabilities` | warning | NET_RAW, DAC_OVERRIDE, etc. |
| `hostNetworkSet` | danger | Pod uses host network namespace |
| `hostPIDSet` | danger | Pod uses host PID namespace |
| `hostIPCSet` | danger | Pod uses host IPC namespace |
| `notReadOnlyRootFilesystem` | warning | Container has writable root FS |

### ⚡ Efficiency Checks

| Check | Severity | What It Catches |
|---|---|---|
| `cpuRequestsMissing` | warning | No CPU requests set |
| `cpuLimitsMissing` | warning | No CPU limits set |
| `memoryRequestsMissing` | warning | No memory requests set |
| `memoryLimitsMissing` | warning | No memory limits set |

### 🎯 Reliability Checks

| Check | Severity | What It Catches |
|---|---|---|
| `readinessProbeMissing` | warning | No readiness probe configured |
| `livenessProbeMissing` | warning | No liveness probe configured |
| `tagNotSpecified` | danger | Image uses `:latest` or no tag |
| `pullPolicyNotAlways` | warning | Pull policy is not `Always` |
| `deploymentMissingReplicas` | warning | Only 1 replica configured |

**That's 30+ checks, zero policy writing, ready to go.**

---

## 7 Bad-Pod Variants (With Real Polaris Output)

Each bad pod in the demo is designed to trigger one or more specific checks:

### 🔴 1. Runs as Root — Security Violation

**The violation:** Container can run as UID 0 — full root access inside the container.

```bash
polaris audit --audit-path k8s/bad-pods/01-runs-as-root.yaml \
    --config polaris/config.yaml --format pretty --only-show-failed-tests
```

**Polaris flags:**
```
✗ runAsRootAllowed — Danger
  Container should not be allowed to run as root
```

**🏀 NBA analogy:** A player showing up without proper credentials — you don't know who they are or what they'll do.

**Why it matters:** Root inside a container is root on the node if you can escape the container. Kernel exploits like [CVE-2022-0185](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0185) require UID 0. Remove root, remove the attack vector.

---

### 🔴 2. Uses `:latest` Tag — Reliability Violation

**The violation:** The image tag is `:latest` — you don't know what version is actually running.

**Polaris flags:**
```
✗ tagNotSpecified — Danger
  Image tag should be specified
```

**🏀 NBA analogy:** An undrafted player walking onto the court — nobody knows their stats, their history, or what they'll do next.

---

### 🔴 3. Missing Health Probes — Reliability Violation

**The violation:** No readiness or liveness probes — Kubernetes has no idea if the app is healthy.

**Polaris flags:**
```
✗ readinessProbeMissing — Warning
  Readiness probe should be configured
✗ livenessProbeMissing — Warning
  Liveness probe should be configured
```

**🏀 NBA analogy:** A player who skipped their physical — coach doesn't know if they're injured or game-ready.

---

### 🔴 4. No Resource Limits — Efficiency Violation

**The violation:** No CPU or memory requests/limits — the container can consume unlimited resources.

**Polaris flags:**
```
✗ cpuRequestsMissing — Warning
✗ cpuLimitsMissing — Warning
✗ memoryRequestsMissing — Warning
✗ memoryLimitsMissing — Warning
```

**🏀 NBA analogy:** A player with unlimited minutes — they'll exhaust the whole team's rotation.

---

### 🔴 5. Privileged Container — Maximum Security Violation

**The violation:** Container runs privileged with `SYS_ADMIN` — effectively root on the host.

**Polaris flags:**
```
✗ runAsPrivileged — Danger
✗ privilegeEscalationAllowed — Danger
✗ dangerousCapabilities — Danger
```

**🏀 NBA analogy:** Someone bringing weapons into the arena — maximum threat level, immediate ejection.

---

### 🔴 6. Host Network Access — Security Violation

**The violation:** Pod uses `hostNetwork: true`, `hostPID: true`, and `hostIPC: true` — direct access to the node's network and process space.

**Polaris flags:**
```
✗ hostNetworkSet — Danger
✗ hostPIDSet — Danger
✗ hostIPCSet — Danger
```

**🏀 NBA analogy:** Someone tapping into the arena's internal PA system and security radio.

---

### 🔴 7. Insecure Capabilities — Security Violation

**The violation:** Container has `NET_RAW` and `DAC_OVERRIDE` capabilities with a writable filesystem.

**Polaris flags:**
```
✗ insecureCapabilities — Warning
✗ notReadOnlyRootFilesystem — Warning
```

**🏀 NBA analogy:** A player with lock-picking tools — they can get into places they shouldn't.

---

## The Dashboard: Seeing is Believing

When you deploy all seven bad pods alongside the compliant `game-day-api`, the Polaris Dashboard shows the damage in real-time:

```bash
kubectl port-forward svc/polaris-dashboard 8080:80 -n polaris
open http://localhost:8080
```

You'll see:

- **Cluster health score** dropping as violations accumulate
- Violations **grouped by category** — Security, Efficiency, Reliability
- **Per-workload details** — click any deployment to see which checks pass/fail
- **Namespace-level scores** — compare polaris-demo against kube-system

<!-- 📸 IMAGE PLACEHOLDER: Screenshot of Polaris Dashboard with violations -->

This is the "aha moment." Teams who couldn't get engineering attention for security concerns deploy the dashboard and suddenly *everyone* can see the score. Executives understand a health score dropping from 95% to 62%.

---

## The Webhook: From Visibility to Enforcement

Once the dashboard has shown you the state of the world, you're ready to enforce:

```bash
helm upgrade polaris fairwinds-stable/polaris --namespace polaris \
    --set dashboard.enable=true \
    --set webhook.enable=true \
    --set-file config=polaris/config.yaml
```

Now try deploying a bad pod:

```bash
kubectl apply -f k8s/bad-pods/05-privileged.yaml
```

```
Error from server (polaris): admission webhook "polaris.fairwinds.com" denied the request:
  Polaris prevented this deployment due to the following issues:
  - Container bench-warmer: runAsPrivileged is true
  - Container bench-warmer: privilegeEscalation is allowed
  - Container bench-warmer: dangerous capabilities found
```

**The bad pod never gets created.** It's rejected at the API server level — before a single byte hits etcd.

### Severity Controls Enforcement

Here's the key insight: **only `danger`-level checks block admission**. Warning-level checks (like missing probes) pass through the webhook but show up in the dashboard.

This is intentional. You don't want to break every deployment on day one. The adoption path:

1. **Week 1:** Deploy dashboard only. See the score.
2. **Week 2:** Enable webhook with default config. Block critical security issues.
3. **Month 2:** Promote warnings to danger. Block everything.

We include `config-strict.yaml` for that final step — all checks at danger level:

```bash
helm upgrade polaris fairwinds-stable/polaris --namespace polaris \
    --set-file config=polaris/config-strict.yaml
```

---

## Custom Checks: JSON Schema, Not Rego

When the 30+ built-in checks aren't enough, you write custom checks in **JSON Schema** — the same format used by OpenAPI, VS Code settings, and npm's `package.json`.

Here's a custom check from this demo that requires every pod to have a `team` label:

```yaml
customChecks:
  teamLabelRequired:
    successMessage: Pod has the required 'team' label
    failureMessage: Pod is missing the required 'team' label
    category: Reliability
    target: Pod
    schema:
      '$schema': http://json-schema.org/draft-07/schema
      type: object
      required: ["metadata"]
      properties:
        metadata:
          type: object
          required: ["labels"]
          properties:
            labels:
              type: object
              required: ["team"]
              properties:
                team:
                  type: string
                  minLength: 1
```

**No Rego. No custom CRDs. No new DSL.** Just JSON Schema — a format most engineers already know.

---

## CLI: Shift-Left into CI/CD

The Polaris CLI is the secret weapon for **catching violations before they reach the cluster**.

Add this to your CI/CD pipeline:

```bash
polaris audit \
    --audit-path ./k8s/ \
    --config polaris/config.yaml \
    --set-exit-code-on-danger \
    --format score
```

If any manifest fails a `danger`-level check, the pipeline fails. The developer fixes it in their PR — not in a 2 AM incident.

**This is the shift-left moment.** You don't need a cluster. You don't need Helm. You don't need to wait for deployment. The CLI checks YAML files locally, instantly.

---

## Polaris vs The Field

| Feature | Polaris | Kyverno | OPA/Gatekeeper |
|---------|---------|---------|----------------|
| **Built-in checks** | 30+ out of the box | None | None |
| **Policy language** | JSON Schema | YAML CRDs | Rego |
| **Dashboard** | Built-in | Via Policy Reporter | No |
| **CLI audit** | ✅ | ✅ `kyverno apply` | ✅ `conftest` |
| **Mutating webhook** | ✅ Auto-remediate | ✅ Mutate rules | ❌ |
| **Generate resources** | ❌ | ✅ | ❌ |
| **Image verification** | ❌ | ✅ Cosign | ❌ |
| **Learning curve** | Minimal — install & go | Moderate — write CRDs | Steep — learn Rego |

**The honest take:** Polaris is the fastest path from "we check nothing" to "we check everything." If you need advanced features like image signature verification or resource generation, add Kyverno alongside it. They complement each other perfectly.

---

## The Adoption Playbook

Based on what I've seen work in real teams:

### Week 1: Dashboard — See the Score

```bash
helm install polaris fairwinds-stable/polaris --namespace polaris \
    --set dashboard.enable=true --set webhook.enable=false
```

Share the dashboard URL with the team. Let them see the violations. Don't enforce anything yet.

### Week 2: CLI in CI — Catch It Early

```bash
# Add to your CI pipeline
polaris audit --audit-path ./k8s/ --set-exit-code-on-danger
```

Block PRs that introduce `danger`-level violations. Let warnings through with a notice.

### Month 1: Webhook — Enforce in Staging

Enable the webhook in staging/dev. Use the default config where only `danger`-level checks block.

### Month 2: Strict Mode — Full Lockdown

Promote all checks to danger. Enable in production. Nothing gets through without passing every check.

### Ongoing: Custom Checks

Add checks specific to your organization — required labels, naming conventions, annotation standards.

---

## Key Takeaways

1. **30+ checks, zero policy writing.** Polaris gives you best-practice enforcement out of the box. No YAML CRDs, no Rego, no learning curve. Install and go.

2. **Three modes, one tool.** Dashboard for visibility. Webhook for enforcement. CLI for CI/CD. The entire lifecycle covered.

3. **Severity levels are an adoption strategy.** Start with danger-only enforcement. Graduate to strict mode when the team is ready. This isn't a technical decision — it's a change management strategy.

4. **The dashboard sells security to leadership.** A health score dropping from 95% to 62% gets executive attention faster than a Jira ticket titled "improve pod security context."

5. **Shift-left with the CLI.** Catching a missing `readinessProbe` in a PR review is 100x cheaper than debugging a production outage caused by Kubernetes sending traffic to a pod that isn't ready.

6. **Custom checks via JSON Schema.** When built-in checks aren't enough, use JSON Schema — not a DSL nobody on your team knows.

7. **Polaris + Kyverno = complete coverage.** Polaris handles the 80% (built-in best practices). Kyverno handles the 20% (custom organizational policies, image verification, resource generation). Use both.

---

## Try It Yourself

The entire project is open source and runs on your laptop:

```bash
git clone https://github.com/23seriy/polaris-in-action.git
cd polaris-in-action
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh    # 10 interactive scenarios
```

⭐ Star the repo if you found this useful: [github.com/23seriy/polaris-in-action](https://github.com/23seriy/polaris-in-action)

---

## Resources

- [Polaris Documentation](https://polaris.docs.fairwinds.com)
- [Polaris GitHub Repository](https://github.com/FairwindsOps/polaris)
- [Fairwinds Kubernetes Benchmark Report](https://www.fairwinds.com/kubernetes-config-benchmark-report)
- [Polaris Helm Chart](https://github.com/FairwindsOps/charts/tree/master/stable/polaris)
- [JSON Schema Specification](https://json-schema.org/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

*This is part of my **"in Action" series** — hands-on Kubernetes projects you can clone and run on your laptop. Each one takes a CNCF/open-source tool, wraps it in a practical demo, and explains it through an NBA analogy because infrastructure shouldn't be boring.*

*More in the series:*
- *[Kyverno in Action](https://medium.com/@sergeiolshanetski/kyverno-in-action-policy-as-code-admission-control-for-kubernetes-from-free-for-all-to-17e41becf176) — Admission control & policy-as-code*
- *[Falco in Action](https://medium.com/@sergeiolshanetski/falco-in-action) — eBPF runtime security & threat detection*
- *[Cilium in Action](https://medium.com/@sergeiolshanetski/cilium-in-action) — eBPF networking, L7 policies, Hubble observability*
- *[Crossplane in Action](https://medium.com/@sergeiolshanetski/crossplane-in-action) — Kubernetes-native infrastructure management*
- *[Argo Rollouts in Action](https://medium.com/@sergeiolshanetski/argo-rollouts-in-action) — Progressive delivery & canary deployments*
- *[KEDA in Action](https://medium.com/@sergeiolshanetski/keda-in-action) — Event-driven autoscaling*

*Follow me on [Medium](https://medium.com/@sergeiolshanetski) for the next one. 🏀*
