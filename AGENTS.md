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
- `Dockerfile` — Alpine base with `bash`, `ca-certificates` and `wget` only.
  `entrypoint.sh` installs `muffet` (and `caddy` when needed) at run time;
  GitHub rebuilds the image on every run, so pre-installing saves nothing.
- `tests/` — test fixtures (`index.html`, `index2.html`) + runner scripts.
- `entrypoint.sh` is also published for "script mode": users `wget … | bash`
  it directly, so it must keep working outside a container (Linux only; it
  exits early on other systems).

## Critical gotchas

- **Tool versions live only in `entrypoint.sh`** (`MUFFET_VERSION`,
  `CADDY_VERSION`), bumped by Renovate via the `# renovate:` comment lines.
- **Inputs are data, not code.** `eval` exists only so quoted options in
  `CMD_PARAMS` work (`--header="…"`, #83). The URL is passed as
  `'"${URL}"'` and `/etc/hosts` is edited with `sed`/`tee`, never `bash -c`
  strings — a `&` or `$(…)` in the URL must not reach the shell.
- **README bash blocks are executed in CI.** `readme-commands-check.yml`
  extracts every ` ```bash ` fenced block from `README.md` and runs it with
  `bash -euxo pipefail`. Do not put illustrative-but-broken commands in `bash`
  blocks — use another language tag (e.g. `yaml`, `text`) or make them runnable.
- **Test domains use the reserved `.test` TLD** (`my-testing-domain.test`),
  which never resolves publicly — the old `.com` names are owned by others.

## Tests

Tests hit **real external sites** and build the Docker image; they are not
hermetic. Run from inside `tests/`:

```bash
cd tests || exit
./run_tests.sh  # external URLs, local PAGES_PATH, and docker build+run
./fail_tests.sh # every case must fail; an unexpected pass exits 1
```

CI runs both scripts on `ubuntu-latest` (amd64) and `ubuntu-24.04-arm` only
when `tests/`, `entrypoint.sh`, `Dockerfile`, or `.dockerignore` change.

## Running the action locally

Script mode needs Linux (it uses `sudo`, GNU `sed` and Linux binaries); on
macOS build and run the Docker image instead.

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
  `main`; it also force-moves the `vMAJOR` and `vMAJOR.MINOR` tags to the
  released commit. Do not tag or edit `CHANGELOG.md` manually.
  `release-please.yml`, `docker-image.yml`, `readme-commands-check.yml` and
  `.dockerignore` are synced from `gh-repo-defaults/action` — change them there
  too, or the next multi-gitter run reverts the edit.
- Pin GitHub Actions to full commit SHAs; keep workflow `permissions` minimal.
