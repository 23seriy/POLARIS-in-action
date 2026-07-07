# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in polaris-in-action, please **do not** open a public GitHub issue. Instead, please report it responsibly by emailing [23seriy@gmail.com](mailto:23seriy@gmail.com) with:

- A description of the vulnerability
- Steps to reproduce it
- Potential impact
- Any suggested fixes (if you have them)

**Please do not disclose the vulnerability publicly until we've had time to address it.**

We will:
1. Acknowledge receipt of your report within 48 hours
2. Provide a timeline for a fix
3. Work with you on the patch if needed
4. Coordinate a disclosure date with you
5. Credit you in the security advisory (unless you prefer anonymity)

## Scope

This security policy covers the polaris-in-action repository itself. It does **not** cover:

- **Polaris itself** — please report Polaris vulnerabilities to the [Polaris project](https://github.com/FairwindsOps/polaris/security)
- **Kubernetes** — please report Kubernetes vulnerabilities through their [security disclosure process](https://kubernetes.io/security/)

## What We Fix

We consider the following as potential security issues:

- **Code injection** in scripts (shell, Python)
- **Unsafe defaults** that could allow unintended policy bypasses
- **Unintended credential leakage** (e.g., secrets in git history)
- **Insecure Polaris configurations** that could weaken cluster security

We do **not** consider the following as security issues (please file them as bugs instead):

- Demo scenarios that intentionally violate Polaris checks (the point of this project)
- Polaris configuration misconfigurations (report to Polaris)
- Kubernetes API vulnerabilities (report to Kubernetes)

## Security Best Practices When Using This Project

### For Demo/Learning Environments

- **Use Minikube, not production clusters** — this project is a demo, not a production-hardened system
- **Run in isolated networks** — don't expose the Minikube cluster to the internet
- **Clean up after demos** — run `./scripts/05-teardown.sh` to delete the test cluster

### For Extending to Production

If you're using this project as a blueprint for production policies:

- **Review all Polaris configurations** — ensure checks match your organization's requirements
- **Enable strict mode** — promote all checks to danger level
- **Enable the mutating webhook** — auto-remediate common issues
- **Add comprehensive logging** — monitor webhook decisions
- **Keep Polaris updated** — regularly update to the latest version
- **Test thoroughly** — run checks against real workloads in staging before production

## Security Advisories

We will publish security advisories for any reported vulnerabilities that we confirm. Check the [GitHub Security Advisories](https://github.com/23seriy/polaris-in-action/security/advisories) page.

## Questions?

If you have questions about security practices in this project, feel free to open a **private security advisory** on GitHub instead of a public issue.

---

Thank you for helping keep polaris-in-action secure. 🔍
