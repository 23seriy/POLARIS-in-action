# Troubleshooting

Common issues and solutions for polaris-in-action.

## Minikube Issues

### Minikube won't start

**Symptoms**: `minikube start` hangs or fails with resource errors.

**Fix**:

```bash
# Check available resources
docker system df
# Clean up if needed
docker system prune -af && docker volume prune -af
# Retry
minikube delete -p polaris-demo
./scripts/02-start-cluster.sh
```

### Minikube profile already exists

**Symptoms**: Script warns about existing profile.

**Fix**: The script will prompt you to delete and recreate. Choose `y` for a fresh start.

## Polaris Issues

### Dashboard not accessible

**Symptoms**: `kubectl port-forward` fails or dashboard doesn't load.

**Fix**:

```bash
# Check Polaris pods are running
kubectl get pods -n polaris
# Check for errors
kubectl describe pod -n polaris -l app.kubernetes.io/name=polaris
# Restart port-forward
kubectl port-forward svc/polaris-dashboard 8080:80 -n polaris
```

### Webhook not rejecting pods

**Symptoms**: Bad pods are admitted even with webhook enabled.

**Fix**:

```bash
# Verify webhook is enabled
kubectl get validatingwebhookconfigurations | grep polaris
# Check webhook logs
kubectl logs -n polaris deploy/polaris-webhook -f
# Ensure config is loaded
helm get values polaris -n polaris
```

**Note**: Only `danger`-level checks block admission. `warning`-level checks pass through the webhook
but appear in the dashboard. Use `config-strict.yaml` to promote all checks to danger.

### Polaris CLI not found

**Symptoms**: `polaris: command not found`

**Fix**:

```bash
brew tap FairwindsOps/tap
brew install FairwindsOps/tap/polaris
```

### Custom check not working

**Symptoms**: Custom `teamLabelRequired` check doesn't appear in results.

**Fix**:

```bash
# Verify config is loaded with custom checks
polaris audit --audit-path k8s/game-day-api.yaml \
    --config polaris/config.yaml --format pretty | grep team
# Ensure the config file is passed to Helm
helm upgrade polaris fairwinds-stable/polaris \
    --namespace polaris --set-file config=polaris/config.yaml
```

## Docker Issues

### Images not available in Minikube

**Symptoms**: Pods stuck in `ImagePullBackOff` or `ErrImagePull`.

**Fix**:

```bash
# Ensure you're using Minikube's Docker daemon
eval "$(minikube docker-env -p polaris-demo)"
# Rebuild images
docker build -t game-day-api:v1 apps/game-day-api
docker build -t bench-warmer:v1 apps/bench-warmer
# Verify images exist in Minikube's daemon
docker images | grep -E "game-day|bench-warmer"
```

### Docker Desktop not running

**Symptoms**: `Cannot connect to the Docker daemon`

**Fix**: Start Docker Desktop from Applications. Wait for it to initialize.

## Helm Issues

### Helm repo not found

**Symptoms**: `Error: repo "fairwinds-stable" not found`

**Fix**:

```bash
helm repo add fairwinds-stable https://charts.fairwinds.com/stable --force-update
helm repo update
```

### Helm upgrade fails

**Symptoms**: `Error: UPGRADE FAILED`

**Fix**:

```bash
# Check current release status
helm list -n polaris
# Force uninstall and reinstall
helm uninstall polaris -n polaris
helm upgrade --install polaris fairwinds-stable/polaris --namespace polaris --create-namespace \
    --set dashboard.enable=true --set-file config=polaris/config.yaml
```

## App Issues

### game-day-api returns 404

**Symptoms**: `curl http://localhost:9080/games` returns connection refused.

**Fix**:

```bash
# Check pod status
kubectl get pods -n polaris-demo -l app=game-day-api
# Restart port-forward
kubectl port-forward svc/game-day-api 9080:8080 -n polaris-demo
```

## Getting Help

If none of the above solutions work:

1. **Check pod events**: `kubectl describe pod <name> -n polaris-demo`
2. **Check Polaris logs**: `kubectl logs -n polaris deploy/polaris-dashboard`
3. **Check Minikube logs**: `minikube logs -p polaris-demo --tail=50`
4. **Open an issue** on the GitHub repository with the output from these commands
