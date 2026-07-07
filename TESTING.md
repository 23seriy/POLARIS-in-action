# Testing

This document describes how to test polaris-in-action, both manually and with automated checks.

## Manual Testing

### Full Demo Test

The most thorough test is running the complete demo:

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
./scripts/05-teardown.sh
```

Each scenario should produce clear output showing which Polaris checks pass or fail.

### Individual Scenario Testing

#### CLI Audit Tests

Test individual manifests against the Polaris config without a cluster:

```bash
# Compliant app should pass all checks
polaris audit --audit-path k8s/game-day-api.yaml --config polaris/config.yaml --format score
# Expected: high score (90+)

# Bad pods should fail specific checks
polaris audit --audit-path k8s/bad-pods/01-runs-as-root.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: runAsRootAllowed failure

polaris audit --audit-path k8s/bad-pods/02-uses-latest-tag.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: tagNotSpecified failure

polaris audit --audit-path k8s/bad-pods/03-no-probes.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: readinessProbeMissing + livenessProbeMissing

polaris audit --audit-path k8s/bad-pods/04-no-resources.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: cpu/memory requests/limits missing

polaris audit --audit-path k8s/bad-pods/05-privileged.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: runAsPrivileged + privilegeEscalationAllowed + dangerousCapabilities

polaris audit --audit-path k8s/bad-pods/06-host-network.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: hostNetworkSet + hostPIDSet + hostIPCSet

polaris audit --audit-path k8s/bad-pods/07-insecure-capabilities.yaml --config polaris/config.yaml --format pretty --only-show-failed-tests
# Expected: insecureCapabilities + notReadOnlyRootFilesystem
```

#### Dashboard Test

```bash
# Deploy bad pods, then open dashboard
kubectl apply -f k8s/bad-pods/
kubectl port-forward svc/polaris-dashboard 8080:80 -n polaris
open http://localhost:8080
# Expected: health score below 100%, violations visible by category
```

#### Webhook Test

```bash
# Enable webhook
helm upgrade polaris fairwinds-stable/polaris --namespace polaris \
    --set dashboard.enable=true --set webhook.enable=true \
    --set-file config=polaris/config.yaml --wait

# Try to deploy a bad pod
kubectl apply -f k8s/bad-pods/05-privileged.yaml
# Expected: rejected by webhook (danger-level checks)
```

### Configuration Testing

```bash
# Validate all Polaris configs parse correctly
polaris audit --audit-path k8s/game-day-api.yaml --config polaris/config.yaml --format score
polaris audit --audit-path k8s/game-day-api.yaml --config polaris/config-strict.yaml --format score
polaris audit --audit-path k8s/game-day-api.yaml --config polaris/config-mutating.yaml --format score
```

## Automated Testing (CI)

### Shell Script Validation

```bash
shellcheck scripts/*.sh
```

### YAML Validation

```bash
yamllint -d relaxed k8s/*.yaml k8s/bad-pods/*.yaml polaris/*.yaml
```

### Dockerfile Linting

```bash
hadolint apps/game-day-api/Dockerfile
hadolint apps/bench-warmer/Dockerfile
```

### Python Syntax

```bash
python -m py_compile apps/game-day-api/app.py
python -m py_compile apps/bench-warmer/app.py
```

## Expected Test Results

| Bad Pod | Expected Failures |
|---------|-------------------|
| 01-runs-as-root | runAsRootAllowed |
| 02-uses-latest-tag | tagNotSpecified |
| 03-no-probes | readinessProbeMissing, livenessProbeMissing |
| 04-no-resources | cpuRequestsMissing, memoryRequestsMissing, cpuLimitsMissing, memoryLimitsMissing |
| 05-privileged | runAsPrivileged, privilegeEscalationAllowed, dangerousCapabilities |
| 06-host-network | hostNetworkSet, hostPIDSet, hostIPCSet |
| 07-insecure-capabilities | insecureCapabilities, notReadOnlyRootFilesystem |
