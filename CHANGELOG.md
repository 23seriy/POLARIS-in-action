# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Initial project setup with comprehensive GitHub standards

### Changed
- (Unreleased items go here)

### Deprecated
- (If any features are deprecated, list them here)

### Removed
- (If any features are removed, list them here)

### Fixed
- (Bug fixes go here)

### Security
- (Security fixes go here)

---

## [1.0.0] — 2026-07-06

### Added

#### Core Demo
- **game-day-api** — Compliant Flask app that passes all Polaris checks
- **bench-warmer** — Rogue Flask app used as base for bad-pod variants
- **7 bad-pod manifests** — Each violating specific Polaris checks:
  - `01-runs-as-root.yaml` — runAsRootAllowed
  - `02-uses-latest-tag.yaml` — tagNotSpecified
  - `03-no-probes.yaml` — readinessProbeMissing + livenessProbeMissing
  - `04-no-resources.yaml` — cpu/memory requests/limits missing
  - `05-privileged.yaml` — runAsPrivileged + dangerousCapabilities
  - `06-host-network.yaml` — hostNetworkSet + hostPIDSet + hostIPCSet
  - `07-insecure-capabilities.yaml` — insecureCapabilities + notReadOnlyRootFilesystem

#### Polaris Configurations
- **config.yaml** — Default config with danger + warning severity levels
- **config-strict.yaml** — All checks promoted to danger (full lockdown)
- **config-mutating.yaml** — Mutating webhook configuration for auto-remediation
- **Custom check** — `teamLabelRequired` via JSON Schema

#### Scripts
- **01-install-prerequisites.sh** — Install minikube, kubectl, helm, polaris CLI
- **02-start-cluster.sh** — Create Minikube profile, install Polaris dashboard
- **03-deploy-app.sh** — Build images, deploy compliant app
- **04-demo-scenarios.sh** — 10 interactive scenarios covering all three modes
- **05-teardown.sh** — Clean uninstall and cluster deletion

#### Documentation
- **CLAUDE.md** — Developer guide with architecture, file structure, and common tasks
- **CONTRIBUTING.md** — Contribution guidelines and development workflow
- **TESTING.md** — Manual and automated testing procedures
- **TROUBLESHOOTING.md** — Comprehensive troubleshooting guide
- **SECURITY.md** — Security policies and responsible disclosure
- **CODE_OF_CONDUCT.md** — Community standards
- **CHANGELOG.md** — This file

#### CI/CD
- **GitHub Actions workflow** (`.github/workflows/validate.yml`) with:
  - Shell script linting (shellcheck)
  - YAML validation (yamllint)
  - Polaris config syntax validation
  - Dockerfile linting (hadolint)
  - Python code validation
  - Markdown linting
- **GitHub issue templates** for bug reports and feature requests
- **Pull request template**
- **Dependabot configuration**
- **Governance document**
