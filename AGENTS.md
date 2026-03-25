# Agent Guidelines for g2-action Repository

This repository is a GitHub composite action (`g2-action`) for downloading, installing, and executing `g2` (Gentoo Tools by arran4).

When working on this codebase, please adhere to the following rules and guidelines.

## 1. Updating `AGENTS.md`
- **Always update `AGENTS.md`** when you discover new insights, patterns, or critical information about the repository. This ensures future agents have the necessary context.

## 2. CI Workflows and Matrices
- The CI workflow (e.g., `.github/workflows/ci.yml`) uses a `route` job to dynamically generate workflow parameters and test matrices (such as `os_matrix`). These are passed to downstream jobs via outputs.

## 3. Testing `g2` CLI
- The `g2` CLI tool returns an exit code of `255` when run with `--help` or no arguments.
- **Do not** use `g2 --help` or just `g2` to test installation in CI environments.
- **Instead**, to verify its installation without triggering false failures, use a specific valid subcommand such as `g2 lint --help`, which returns an exit code of `0`.

## 4. Release and Versioning
- Releases for this GitHub action rely on semantic tagging.
- **Major version tags** (e.g., `v1`, `v2`) must be updated to point to the latest minor/patch release.

## 5. Shell Script Execution in Composite Actions
- In this repository's composite action configurations (like `action.yml`), shell scripts should be executed explicitly using `bash`.
- For example, use: `bash $GITHUB_ACTION_PATH/setup.sh`.
- **Do not** call them directly. This prevents "Permission denied" (exit code 126) errors caused by lost executable bits in the runner environment.

## 6. Local Execution of Setup Scripts
- Local execution of `setup.sh` requires simulating the GitHub Actions runner environment.
- You must set variables like `RUNNER_OS` and `RUNNER_ARCH`.
- Example: `RUNNER_OS=Linux RUNNER_ARCH=X86 ./setup.sh latest ""`

## 7. Validation Techniques
- **YAML configurations**: Can be validated using PyYAML (installable via `python3 -m pip install pyyaml`) and evaluated with `python3 -c 'import yaml; yaml.safe_load(open("filename.yml"))'`.
- **Shell scripts**: Can be syntax-checked using `bash -n`.
