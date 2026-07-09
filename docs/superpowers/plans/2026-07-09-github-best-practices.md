# GitHub Best Practices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `.github/` and CI configuration up to GitHub best practices: fix dead config, enforce quality checks, add release automation, harden supply chain, and complete repo hygiene files.

**Architecture:** Five independent file-level changes applied in order. Tasks 1–2 touch `.github/workflows/`; Tasks 3–5 add/modify standalone files. No shared interfaces — each task is self-contained and commit-able independently.

**Tech Stack:** GitHub Actions (YAML), Python 3.12, shellcheck, yamllint, hadolint, markdownlint, gh CLI

## Global Constraints

- All YAML files must pass `yamllint -d relaxed` without errors
- All action `uses:` fields must reference a commit SHA with an inline `# vX.Y.Z` comment
- Shell steps in workflows must not introduce new `set -e` violations
- Commit messages follow project convention: `[type] short description`
- Do not modify any file outside `.github/` or `docs/`

## Resolved SHAs (as of 2026-07-09)

| Action | SHA | Tag |
|---|---|---|
| `actions/checkout` | `9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` | v7.0.0 |
| `actions/setup-python` | `ece7cb06caefa5fff74198d8649806c4678c61a1` | v6.3.0 |
| `actions/cache` | `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` | v6.1.0 |
| `nosborn/github-action-markdown-cli` | `508d6cefd8f0cc99eab5d2d4685b1d5f470042c1` | v3.5.0 |

---

## Task 1: Rewrite `validate.yml` (CI fixes + SHA pinning)

**Files:**
- Modify: `.github/workflows/validate.yml` (full rewrite)

**What changes:**
1. Remove `develop` from branch triggers (branch doesn't exist)
2. Add `workflow_dispatch` for manual runs
3. Add `concurrency` group to cancel stale PR runs
4. Pin all `uses:` to commit SHAs (see Global Constraints table)
5. Add `actions/cache` to `yaml-lint`, `polaris-config-validation`, and `python-lint` jobs
6. Harden hadolint download with SHA256 verification
7. Set `docker-lint` and `markdown-lint` to `continue-on-error: false` (enforcing)
8. Keep `python-lint` flake8/black steps at `continue-on-error: true` with explanatory comments

- [ ] **Step 1: Overwrite `.github/workflows/validate.yml` with the following content**

```yaml
name: Validate

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  shellcheck:
    name: Shell Script Linting
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck

      - name: Run shellcheck on all scripts
        run: shellcheck -x scripts/*.sh

  yaml-lint:
    name: YAML Validation
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-yamllint
          restore-keys: ${{ runner.os }}-pip-

      - name: Install yamllint
        run: pip install yamllint

      - name: Lint Kubernetes manifests
        run: |
          find k8s -name '*.yaml' -print0 | xargs -0 yamllint -d relaxed
          yamllint -d relaxed polaris/*.yaml

  polaris-config-validation:
    name: Polaris Config Syntax
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - uses: actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1 # v6.3.0
        with:
          python-version: '3.12'

      - uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-pyyaml
          restore-keys: ${{ runner.os }}-pip-

      - name: Install PyYAML
        run: pip install pyyaml

      - name: Validate Polaris config YAML structure
        run: |
          python3 << 'EOF'
          import yaml
          import glob
          import sys

          errors = 0
          for config in sorted(glob.glob('polaris/*.yaml')):
              print(f"Validating {config}")
              try:
                  with open(config) as f:
                      doc = yaml.safe_load(f)
                  if not doc:
                      print(f"  ERROR: {config} is empty")
                      errors += 1
                      continue
                  if 'checks' not in doc:
                      print(f"  ERROR: {config} missing 'checks' section")
                      errors += 1
                      continue
                  check_count = len(doc['checks'])
                  custom_count = len(doc.get('customChecks', {}))
                  print(f"  OK — {check_count} checks, {custom_count} custom checks")
              except Exception as e:
                  print(f"  ERROR: {e}")
                  errors += 1

          if errors:
              print(f"\n✗ {errors} config file(s) failed validation")
              sys.exit(1)
          print("\n✓ All Polaris configs have valid YAML syntax and proper structure")
          EOF

  docker-lint:
    name: Dockerfile Linting
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Install hadolint (integrity-verified)
        run: |
          EXPECTED_SHA=$(wget -qO- https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64.sha256 | awk '{print $1}')
          wget -q -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
          ACTUAL_SHA=$(sha256sum /tmp/hadolint | awk '{print $1}')
          if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            echo "SHA256 mismatch for hadolint binary — aborting"
            exit 1
          fi
          chmod +x /tmp/hadolint
          sudo mv /tmp/hadolint /usr/local/bin/hadolint

      - name: Lint Dockerfiles
        run: |
          hadolint apps/game-day-api/Dockerfile
          hadolint apps/bench-warmer/Dockerfile

  docs-check:
    name: Documentation Completeness
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Check required docs exist
        run: |
          files=(
            "README.md"
            "LICENSE"
            ".gitignore"
            "CONTRIBUTING.md"
            "CODE_OF_CONDUCT.md"
            "SECURITY.md"
            "TROUBLESHOOTING.md"
            "CLAUDE.md"
          )
          for file in "${files[@]}"; do
            if [ ! -f "$file" ]; then
              echo "Missing: $file"
              exit 1
            fi
          done
          echo "All required documentation files present"

  script-syntax:
    name: Script Syntax Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Check bash syntax
        run: |
          for script in scripts/*.sh; do
            echo "Checking $script"
            bash -n "$script"
          done

  python-lint:
    name: Python Code Quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - uses: actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1 # v6.3.0
        with:
          python-version: '3.12'

      - uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-lint-${{ hashFiles('**/requirements*.txt') }}
          restore-keys: ${{ runner.os }}-pip-

      - name: Install linting tools
        run: pip install flake8 pylint black

      - name: Check Python syntax
        run: |
          python -m py_compile apps/game-day-api/app.py
          python -m py_compile apps/bench-warmer/app.py

      - name: Run flake8
        # Advisory: style preferences, not a quality gate
        run: flake8 apps/ --max-line-length=100
        continue-on-error: true

      - name: Check code formatting with black
        # Advisory: style preferences, not a quality gate
        run: black --check apps/
        continue-on-error: true

  markdown-lint:
    name: Markdown Linting
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - uses: nosborn/github-action-markdown-cli@508d6cefd8f0cc99eab5d2d4685b1d5f470042c1 # v3.5.0
        with:
          files: .
          config_file: .markdownlint.json
```

- [ ] **Step 2: Validate YAML syntax locally**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate.yml'))" && echo "OK"
```

Expected: `OK` with no errors.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/validate.yml
git commit -m "[ci] fix validate.yml: triggers, concurrency, caching, SHA pins, enforce linting"
```

---

## Task 2: Create `release.yml` workflow

**Files:**
- Create: `.github/workflows/release.yml`

**What it does:** Fires on any `v*` tag push. Extracts the matching section from `CHANGELOG.md` and creates a GitHub Release with that text as the body.

- [ ] **Step 1: Create `.github/workflows/release.yml` with the following content**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    name: Create GitHub Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
        with:
          fetch-depth: 0

      - name: Extract changelog section
        id: changelog
        run: |
          TAG="${GITHUB_REF_NAME}"
          VERSION="${TAG#v}"

          # Extract the block between "## [VERSION]" and the next "## [" line
          NOTES=$(awk "/^## \[${VERSION}\]/{found=1; next} found && /^## \[/{exit} found{print}" CHANGELOG.md)

          if [ -z "$NOTES" ]; then
            NOTES="Release ${TAG}. See CHANGELOG.md for details."
          fi

          {
            echo "notes<<EOF"
            echo "$NOTES"
            echo "EOF"
          } >> "$GITHUB_OUTPUT"

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh release create "$GITHUB_REF_NAME" \
            --title "$GITHUB_REF_NAME" \
            --notes "${{ steps.changelog.outputs.notes }}"
```

- [ ] **Step 2: Validate YAML syntax locally**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))" && echo "OK"
```

Expected: `OK` with no errors.

- [ ] **Step 3: Test the changelog extraction script locally**

Run this to simulate what the workflow does for tag `v1.0.0`:

```bash
VERSION="1.0.0"
awk "/^\#\# \[${VERSION}\]/{found=1; next} found && /^\#\# \[/{exit} found{print}" CHANGELOG.md
```

Expected: several lines of release notes from the `## [1.0.0]` section, ending before `---`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "[ci] add release.yml — auto-create GitHub Release on v* tag push"
```

---

## Task 3: Create `CODEOWNERS`

**Files:**
- Create: `.github/CODEOWNERS`

**What it does:** GitHub reads this file to auto-request a review from `@23seriy` on every PR.

- [ ] **Step 1: Create `.github/CODEOWNERS` with the following content**

```
# All files: request review from the project owner
* @23seriy
```

- [ ] **Step 2: Verify the file exists and has the right content**

```bash
cat .github/CODEOWNERS
```

Expected output:
```
# All files: request review from the project owner
* @23seriy
```

- [ ] **Step 3: Commit**

```bash
git add .github/CODEOWNERS
git commit -m "[ci] add CODEOWNERS — auto-request review from @23seriy on all PRs"
```

---

## Task 4: Create Issue Template `config.yml`

**Files:**
- Create: `.github/ISSUE_TEMPLATE/config.yml`

**What it does:** Disables blank issues (forces template selection) and adds a "Ask a Question" link that routes to GitHub Discussions instead of Issues.

**Prerequisite:** GitHub Discussions must be enabled on the repo. Go to repo **Settings → Features → Discussions** and toggle it on. This is a one-time manual step in the GitHub UI.

- [ ] **Step 1: Create `.github/ISSUE_TEMPLATE/config.yml` with the following content**

```yaml
blank_issues_enabled: false
contact_links:
  - name: Ask a Question
    url: https://github.com/23seriy/polaris-in-action/discussions/new
    about: Use GitHub Discussions for general questions, ideas, and feedback
```

- [ ] **Step 2: Validate YAML syntax locally**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/config.yml'))" && echo "OK"
```

Expected: `OK` with no errors.

- [ ] **Step 3: Commit**

```bash
git add .github/ISSUE_TEMPLATE/config.yml
git commit -m "[ci] add issue template config — disable blank issues, redirect questions to Discussions"
```

---

## Task 5: Add Docker ecosystem to `dependabot.yml`

**Files:**
- Modify: `.github/dependabot.yml`

**What changes:** Append two `docker` ecosystem entries — one per app directory — so Dependabot tracks the `FROM python:3.12-slim` base image in both Dockerfiles.

- [ ] **Step 1: Open `.github/dependabot.yml` and append the following two entries at the end of the `updates:` list**

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

The full file after the edit should have 5 entries under `updates:`: `github-actions`, `pip` (game-day-api), `pip` (bench-warmer), `docker` (game-day-api), `docker` (bench-warmer).

- [ ] **Step 2: Validate YAML syntax locally**

```bash
python3 -c "import yaml; data = yaml.safe_load(open('.github/dependabot.yml')); print(f'OK — {len(data[\"updates\"])} update entries')"
```

Expected: `OK — 5 update entries`

- [ ] **Step 3: Commit**

```bash
git add .github/dependabot.yml
git commit -m "[ci] add Docker ecosystem to Dependabot — track base image updates in both apps"
```
