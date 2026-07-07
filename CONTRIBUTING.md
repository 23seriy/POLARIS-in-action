# Contributing to polaris-in-action

Thank you for your interest in contributing! This project aims to be a clear, educational demonstration of Polaris's capabilities. Whether you're fixing a bug, improving documentation, or adding new scenarios, we appreciate your help.

## Getting Started

1. **Fork and clone** the repository
2. **Create a feature branch** from `main`: `git checkout -b feature/your-feature`
3. **Make your changes** and test them thoroughly
4. **Submit a pull request** with a clear description

## Code of Conduct

This project adheres to a Code of Conduct. Please review [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before participating.

## Development Workflow

### Before You Start

- Ensure you have the prerequisites installed: Docker Desktop, Minikube, and macOS (scripts use Homebrew)
- Familiarity with Kubernetes and Polaris is helpful but not required

### Testing Your Changes

For **script changes**:
```bash
chmod +x scripts/*.sh
./scripts/02-start-cluster.sh      # Fresh cluster
./scripts/03-deploy-app.sh         # Build and deploy apps
./scripts/04-demo-scenarios.sh     # Run through all scenarios
./scripts/05-teardown.sh           # Clean up
```

For **Polaris config changes**:
```bash
# Test a config against a YAML file
polaris audit --audit-path k8s/<manifest>.yaml --config polaris/config.yaml --format pretty
```

For **manifest changes**:
- Update the corresponding YAML in `k8s/` or `polaris/`
- Run the full demo to ensure nothing breaks

### Shell Script Standards

All shell scripts should:
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Use the project's `info()` and `warn()` helper functions for output
- Include descriptive comments for complex logic
- Pass `shellcheck` without warnings (run `shellcheck scripts/*.sh`)

### Polaris Configuration Standards

All configs in `polaris/` should:
- Have clear comments explaining check severity choices
- Include custom checks in the `customChecks` section
- Define exemptions for system namespaces
- Be testable with `polaris audit --config`

### Documentation Standards

- Keep the README.md up-to-date with the latest Kubernetes and Polaris versions
- Document new scenarios in the "Demo Scenarios" section
- Update CLAUDE.md if adding architectural concepts
- Use clear, jargon-free language where possible

## Reporting Issues

### Security Vulnerabilities

**Do not** open a public issue for security vulnerabilities. Please review [SECURITY.md](SECURITY.md) for responsible disclosure.

### Bugs and Feature Requests

Use GitHub Issues with:
- **Clear title**: "Script fails on Minikube M1" is better than "Something broken"
- **Steps to reproduce**: Exact commands and cluster state
- **Expected vs. actual behavior**
- **Environment**: macOS version, Minikube version, Kubernetes version

## Pull Request Process

1. **Update tests** if you change functionality
2. **Run the full demo** and confirm all scenarios pass
3. **Check with `shellcheck`**: `shellcheck scripts/*.sh`
4. **Update docs** if behavior changes
5. **Write a clear PR description** explaining *why* the change is needed

### PR Title Convention

Use the format: `[type] short description`

Types:
- `[docs]` — Documentation-only changes
- `[fix]` — Bug fixes
- `[feature]` — New scenarios or checks
- `[refactor]` — Code cleanup without behavior change
- `[ci]` — CI/CD workflow changes

Example: `[feature] add PDB check scenario with custom Polaris config`

## Project Goals & Philosophy

This project demonstrates Polaris through **hands-on examples**, not exhaustive feature coverage. When contributing:

- **Prefer clarity over cleverness** — a simple check demo is more educational than a complex one
- **Each scenario should teach one thing** — avoid mixing multiple concepts in a single scenario
- **Test scripts must be reproducible** — they should work the same way on any macOS machine with prerequisites installed
- **Keep the NBA arena metaphor consistent** — use the metaphor when explaining concepts in comments and docs

## Recognition

Contributors will be recognized in:
- The project README's acknowledgments section (if you'd like)
- Individual commit history via GitHub

## Questions?

Open a discussion or an issue if you're unsure about anything. We're here to help!

---

Thank you for helping make polaris-in-action a better learning resource. 🔍
