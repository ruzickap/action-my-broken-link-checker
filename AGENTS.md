# AI Agent Guidelines

## Project Overview

GitHub Action (`ruzickap/action-my-broken-link-checker`) that checks
broken links in static files or web pages using
[muffet](https://github.com/raviqqe/muffet) and
[Caddy](https://caddyserver.com/) as a local web server. The codebase
is entirely **Bash** with Docker packaging.

## Build / Test / Lint Commands

### Build Docker image

```bash
docker build . -t my-broken-link-checker-test
```

### Run all tests

```bash
cd tests && ./run_tests.sh
```

### Run a single test (manual)

No test framework; tests are sequential script calls. Set env vars
and invoke the entrypoint directly:

```bash
export INPUT_DEBUG="true"
export INPUT_URL="https://xvx.cz"
export INPUT_CMD_PARAMS="--one-page-only --buffer-size=8192 \
  --max-connections=10 --verbose --color=always"
./entrypoint.sh
```

For local page tests, also set `INPUT_PAGES_PATH`:

```bash
export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}/tests"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose \
  --color=always"
./entrypoint.sh
```

### Lint shell scripts

```bash
shellcheck --exclude=SC2317 entrypoint.sh tests/*.sh
shfmt --case-indent --indent 2 --space-redirects -d entrypoint.sh
```

### Lint Markdown

```bash
rumdl *.md
```

### Validate GitHub Actions workflows

```bash
actionlint
```

## Shell Script Style Guide

### Shebang and strict mode

- Always start with `#!/usr/bin/env bash`
- Production scripts: `set -Eeuo pipefail`
- Test scripts: `set -euxo pipefail` (adds verbose tracing)

### Variables

- **UPPERCASE** for all variables: `${MY_VARIABLE}`
- Use `${VAR:-default}` for optional params with defaults
- Use `${VAR:?}` for required params (fails if unset)
- Always quote variable expansions: `"${VAR}"`
- Use `export` for variables passed to subprocesses

### Functions

- **lowercase_with_underscores**: `print_error()`, `cleanup()`
- Define before use; group utility functions near the top
- Use `trap` for cleanup and error handling

### Formatting (enforced by shfmt)

- **2 spaces** for indentation (no tabs)
- Indent `case` statement bodies (`--case-indent`)
- Space before redirect operators (`> file`, not `>file`)

### Error handling

- Use `trap error_trap ERR` for error trapping
- Print errors: `echo -e "\e[31m*** ERROR: ${1}\e[m"`
- Print info: `echo -e "\e[36m*** INFO: ${1}\e[m"`
- Always clean up temp files and `/etc/hosts` modifications

### Common patterns

**Conditional sudo** -- check `$EUID` and set `sudo_cmd=""` or
`sudo_cmd="sudo"`, then use `$sudo_cmd bash -c "command"`.

**Architecture detection** -- map `uname -m` to `ARCH_SUFFIX`
(`aarch64` -> `arm64`, `x86_64` -> `amd64`), exit on unsupported.

## Dockerfile Conventions

- Pin base image with SHA digest:
  `FROM alpine:3.23@sha256:abcdef...`
- Add security scanner skip annotations at the top
- Use `SHELL ["/bin/ash", "-eo", "pipefail", "-c"]`
- Include `HEALTHCHECK NONE`
- Add Renovate annotations for version tracking:
  `# renovate: datasource=github-tags depName=org/repo`

## Markdown Guidelines

- Pass `rumdl` checks (config in `.rumdl.toml`)
- Wrap lines at **72 characters**
- Proper heading hierarchy (no skipped levels)
- Include language identifiers in code fences
- Shell code blocks in Markdown must pass `shellcheck`

## GitHub Actions Workflows

- Pin all actions to **full SHA** with version comment:
  `uses: actions/checkout@de0fac2e4500d...  # v6.0.2`
- Use `permissions: read-all` as default
- Set `timeout-minutes` on all jobs
- Validate with `actionlint` after any workflow change

## Version Control

### Commit messages (conventional commits)

- Format: `<type>: <description>` (max 72 chars)
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`,
  `style`, `perf`, `ci`, `build`, `revert`
- Imperative mood, lowercase, no trailing period
- Body: wrap at 72 chars, explain what and why
- Reference issues: `Fixes: #123`, `Closes: #456`

### Branching (conventional branch)

- Format: `<type>/<description>` (e.g., `feat/add-retry`)
- Types: `feature/`, `feat/`, `bugfix/`, `fix/`, `hotfix/`,
  `release/`, `chore/`
- Lowercase, hyphens only, no consecutive/trailing hyphens

### Pull requests

- Create as **draft** initially
- Title must follow conventional commit format
- Include clear description and link related issues

## Security & CI

- **Checkov**: IaC scanner (skip `CKV_GHA_7`)
- **DevSkim**: Ignore DS162092, DS137138; exclude `CHANGELOG.md`
- **KICS**: Fails only on HIGH severity
- **Trivy**: HIGH/CRITICAL only, ignores unfixed vulnerabilities
- **ShellCheck**: Exclude SC2317 (unreachable command)

## Dependency Management

Versions managed by **Renovate** with `# renovate:` annotations.
Versions are declared in both `Dockerfile` and `entrypoint.sh` and
must stay in sync (Renovate handles this automatically).
