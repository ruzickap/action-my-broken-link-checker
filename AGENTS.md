# AGENTS.md

Guidance for AI agents working in this repo. Keep edits high-signal and
repo-specific.

## What this repo is

A **Docker-based GitHub Action** ("My Broken Link Checker") that checks web
pages for broken links. It wraps two upstream binaries:

- [`muffet`](https://github.com/raviqqe/muffet) — the actual link checker
- [`caddy`](https://caddyserver.com/) — only started when checking **local**
  pages (`INPUT_PAGES_PATH`), to serve them over the hostname from the URL

There is no application source code. The entire logic lives in
`entrypoint.sh` (~150 lines of Bash). `action.yml` + `Dockerfile` package it
as a container action; the same script also runs standalone via `bash`.

## Architecture / key files

- `entrypoint.sh` — all logic. Reads config from `INPUT_*` env vars, installs
  `muffet`/`caddy` if missing, optionally starts caddy + edits `/etc/hosts`,
  runs `muffet`, then cleans up. Non-zero exit = broken links found.
- `action.yml` — Docker action. Inputs (`url`, `pages_path`, `cmd_params`,
  `debug`) auto-map to `INPUT_URL` / `INPUT_PAGES_PATH` / `INPUT_CMD_PARAMS` /
  `INPUT_DEBUG` that the script reads. Only `url` is required.
- `Dockerfile` — Alpine base; pre-installs `muffet` + `caddy`.
- `tests/` — test fixtures (`index.html`, `index2.html`) + runner scripts.
- `entrypoint.sh` is also published for "script mode": users `wget … | bash`
  it directly, so it must keep working outside a container.

## Critical gotchas

- **Tool versions are duplicated.** `MUFFET_VERSION` and `CADDY_VERSION` are
  hardcoded in **both** `entrypoint.sh` and `Dockerfile` and must stay in
  lockstep. Both are bumped by Renovate via the `# renovate:` comment lines —
  if you change one by hand, change the other too.
- **README bash blocks are executed in CI.** `readme-commands-check.yml`
  extracts every ` ```bash ` fenced block from `README.md` and runs it with
  `bash -euxo pipefail`. Do not put illustrative-but-broken commands in `bash`
  blocks — use another language tag (e.g. `yaml`, `text`) or make them runnable.
- **`tests/CHANGELOG.md` is a leftover fixture**, frozen at v2.2.0 (2021). It
  is only served as test content and is excluded from linting. The real
  changelog is root `CHANGELOG.md`, managed by release-please — do not hand-edit
  either.

## Tests

Tests hit **real external sites** and build the Docker image; they are not
hermetic. Run from inside `tests/`:

```bash
cd tests
./run_tests.sh    # external URLs, local PAGES_PATH, and docker build+run
./fail_tests.sh   # cases that are EXPECTED to fail (broken links / bad paths)
```

CI runs `run_tests.sh` on a matrix (`ubuntu-latest`, `ubuntu-24.04`) only when
`tests/`, `entrypoint.sh`, `Dockerfile`, or `.dockerignore` change.

## Running the action locally

```bash
export INPUT_URL="https://example.com"
export INPUT_CMD_PARAMS="--one-page-only --color=always --verbose"
# export INPUT_PAGES_PATH="${PWD}/tests/"   # to serve local pages via caddy
./entrypoint.sh
```

## Lint / CI

Linting is **MegaLinter** (`.mega-linter.yml`), which runs only on **non-`main`
push branches** and skips `chore/renovate/*` and `release-please--*` branches.
There is no Makefile or lint script — match these tools when editing:

- Shell: `shellcheck` (`SC2317` excluded) and `shfmt --case-indent --indent 2
  --space-redirects`.
- Markdown: `rumdl` (not markdownlint); wrap prose at 80 cols (code blocks
  exempt). Links checked with `lychee`.
- `CHANGELOG.md` is excluded from all linters.

Other PR checks: `docker-image` (build on amd64 + arm64), `commit-check`,
`semantic-pull-request`, CodeQL, scorecards.

## Conventions

- **Commits & PR titles**: Conventional Commits (`feat:`, `fix:`, `chore:`,
  `docs:`, …). Subject ≤ 72 chars. PR titles are validated.
- **Branches**: Conventional Branch (`feature/`, `bugfix/`, `chore/`, …),
  lowercase + hyphens.
- **Releases**: automated by release-please (`release-type: simple`) on push to
  `main`; it also force-moves the `vMAJOR` and `vMAJOR.MINOR` tags. Do not tag
  or edit `CHANGELOG.md` manually.
- Pin GitHub Actions to full commit SHAs; keep workflow `permissions` minimal.
