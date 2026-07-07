# Project Governance

## Overview

polaris-in-action is a community-driven educational project demonstrating Polaris's capabilities. This document outlines how we make decisions, manage contributions, and maintain the project.

## Project Goals

1. **Educate** — Provide clear, hands-on examples of Polaris's features
2. **Demonstrate** — Show real configurations and workflows that users can adapt
3. **Empower** — Enable users to build their own Kubernetes validation pipelines
4. **Maintain Quality** — Keep code, docs, and scripts clean and consistent

## Maintainers

The project is maintained by:
- **Sergei Olshanetski** (@23seriy) — Creator and primary maintainer

Maintainers handle:
- Reviewing pull requests
- Merging approved changes
- Managing releases
- Setting project direction
- Enforcing code standards

## Contributing

We welcome contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for:
- How to get started
- Development workflow
- Testing requirements
- PR conventions

## Decision Making

### Minor Changes (Docs, Bug Fixes, Tests)
- Open a PR with a clear description
- At least one maintainer approval needed
- CI checks must pass
- No formal review period required

### Major Changes (New Features, Architecture)
- Open an issue or discussion first
- Describe the change and motivation
- Get feedback from maintainers
- Then open a PR
- Allow 3-5 days for community feedback
- At least one maintainer approval needed

### Breaking Changes
- Only in major version bumps
- Clearly documented in CHANGELOG
- At least one maintainer approval
- Community discussion encouraged

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR** — Breaking changes (major Polaris version bump, script incompatibility)
- **MINOR** — New features (new scenarios, checks)
- **PATCH** — Bug fixes (script fixes, doc corrections)

### Release Steps

1. Update [CHANGELOG.md](../CHANGELOG.md) with all changes
2. Bump version in README.md and scripts
3. Create a git tag: `git tag v1.2.3`
4. Push tag: `git push origin v1.2.3`
5. GitHub Actions creates a release automatically
6. Announce on relevant channels

## Code Standards

All contributions must:
- Pass `shellcheck` (shell scripts)
- Pass `yamllint` (YAML files)
- Include comments for complex logic
- Update documentation if behavior changes
- Include clear commit messages: `[type] description`

See [.github/workflows/validate.yml](workflows/validate.yml) for all automated checks.

## Community Channels

- **Issues** — Bug reports, feature requests, questions
- **Discussions** — General conversations, ideas, feedback
- **Pull Requests** — Code review and collaboration
- **Commits** — Git history is the source of truth

## Licensing

All contributions are licensed under [MIT](../LICENSE). By submitting a PR, you agree to this license.

---

Questions about governance? Open an issue or discussion! 🔍
