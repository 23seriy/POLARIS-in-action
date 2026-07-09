# GitHub Best Practices — Design Spec

**Date:** 2026-07-09  
**Approach:** Single comprehensive PR (Approach B)  
**Scope:** CI fixes, action security, release automation, repo hygiene

---

## 1. CI Workflow Fixes (`validate.yml`)

### 1.1 Remove dead `develop` branch trigger

The workflow currently fires on pushes to `develop`, which does not exist. Remove it.

**Before:**
```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
```

**After:**
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
```

### 1.2 Add `workflow_dispatch`

Allows manually triggering the CI pipeline from the GitHub Actions UI. Added to the `on:` block above.

### 1.3 Add `concurrency` group

Cancels in-progress runs for the same PR or branch when a new push arrives.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 1.4 Fix `continue-on-error` on enforcement jobs

| Job | Current | New | Rationale |
|---|---|---|---|
| `docker-lint` | `continue-on-error: true` | `false` | Dockerfile issues should block |
| `markdown-lint` | `continue-on-error: true` | `false` | Doc quality is enforceable |
| `python-lint` (flake8/black) | `continue-on-error: true` | stays `true` | Style opinions — advisory only, clearly commented |

### 1.5 Add pip caching

Wrap each job that runs `pip install` with `actions/cache` keyed on the `requirements.txt` hash. Reduces job time by ~30–60 seconds per run.

```yaml
- uses: actions/cache@<SHA> # v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

### 1.6 Fix hadolint download — integrity verification

Current approach downloads a binary from GitHub and executes it without verification. Replace with SHA256 check:

```bash
HADOLINT_SHA256="56a8859a0d47ee12a2cebfabba6bdef7ab48cc0b3f1f3b12d91218d6149afbd5"
wget -q -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
echo "${HADOLINT_SHA256}  /tmp/hadolint" | sha256sum -c -
chmod +x /tmp/hadolint
sudo mv /tmp/hadolint /usr/local/bin/hadolint
```

---

## 2. Action Security — SHA Pinning

Pin all third-party actions to their commit SHA with an inline version comment. This prevents a compromised or force-pushed tag from silently redirecting to malicious code.

| Action | Mutable Tag | Resolution |
|---|---|---|
| `actions/checkout` | `@v7` | resolved to latest v4 stable SHA at implementation time |
| `actions/setup-python` | `@v6` | resolved to latest v5 stable SHA at implementation time |
| `actions/cache` (new) | — | resolved to latest v4 stable SHA at implementation time |
| `nosborn/github-action-markdown-cli` | `@v3.5.0` | resolved to commit SHA for v3.5.0 at implementation time |

All four actions get the same treatment: commit SHA in the `uses:` field, human-readable tag in an inline comment. SHAs are looked up from each action's GitHub tags page at implementation time and pinned explicitly — not inferred.

> **Note on hadolint SHA:** The SHA256 in section 1.6 must be verified against the published checksum file at `https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64.sha256` at implementation time — the value in section 1.6 is a placeholder.

---

## 3. Release Workflow (new file: `.github/workflows/release.yml`)

### Trigger

```yaml
on:
  push:
    tags:
      - 'v*'
```

### Steps

1. `actions/checkout@<SHA>` — full history for changelog extraction
2. Extract release notes — shell script that reads `CHANGELOG.md` and outputs the block between the pushed tag's `## [x.y.z]` header and the next `## [` line
3. `gh release create` — creates the GitHub Release with the extracted notes as body, no artifacts

### Permissions

```yaml
permissions:
  contents: write  # needed to create releases
```

This fulfills the promise in `GOVERNANCE.md` ("GitHub Actions creates a release automatically when a tag is pushed").

### Release process (no change to existing docs)

GOVERNANCE.md already documents the correct steps:
1. Update CHANGELOG.md
2. Create tag `git tag vX.Y.Z`
3. Push tag `git push origin vX.Y.Z`
4. Workflow fires automatically

---

## 4. Repo Hygiene Files

### 4.1 `CODEOWNERS` (`.github/CODEOWNERS`)

```
* @23seriy
```

Every PR auto-requests review from the repo owner. GitHub enforces this if branch protection is enabled.

### 4.2 Issue template `config.yml` (`.github/ISSUE_TEMPLATE/config.yml`)

```yaml
blank_issues_enabled: false
contact_links:
  - name: Ask a Question
    url: https://github.com/23seriy/polaris-in-action/discussions/new
    about: Use GitHub Discussions for general questions and ideas
```

- Disables blank issues (forces template selection)
- Adds a "Ask a Question" link → Discussions
- Keeps existing Bug Report and Feature Request templates

**Prerequisite:** Enable GitHub Discussions in repo Settings → Features (one click).

---

## 5. Dependabot Docker Coverage

Add two Docker entries to `.github/dependabot.yml`:

```yaml
- package-ecosystem: "docker"
  directory: "/apps/game-day-api"
  schedule:
    interval: "weekly"
    day: "monday"
  commit-message:
    prefix: "[deps] "

- package-ecosystem: "docker"
  directory: "/apps/bench-warmer"
  schedule:
    interval: "weekly"
    day: "monday"
  commit-message:
    prefix: "[deps] "
```

Tracks `FROM python:3.12-slim` in both Dockerfiles. Same weekly-Monday cadence as existing entries.

---

## Files Changed

| File | Action |
|---|---|
| `.github/workflows/validate.yml` | Modify — trigger cleanup, concurrency, caching, hadolint hash, `continue-on-error` fixes, SHA pins |
| `.github/workflows/release.yml` | Create — tag-triggered release automation |
| `.github/CODEOWNERS` | Create — `* @23seriy` |
| `.github/ISSUE_TEMPLATE/config.yml` | Create — blank issue disable + Discussions redirect |
| `.github/dependabot.yml` | Modify — add two Docker ecosystem entries |

---

## Out of Scope

- Branch protection rules (configured in GitHub UI, not files)
- `Taskfile`/`Makefile` for local CI parity (Approach C — deferred)
- GitHub Discussions setup guide in CONTRIBUTING (Approach C — deferred)
- Changing the CHANGELOG format or semver tooling
