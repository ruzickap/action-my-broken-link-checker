# GitHub Actions: My Broken Link Checker ✔

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-My%20Broken%20Link%20Checker-blue.svg?colorA=24292e&colorB=0366d6&style=flat&longCache=true&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAM6wAADOsB5dZE0gAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAERSURBVCiRhZG/SsMxFEZPfsVJ61jbxaF0cRQRcRJ9hlYn30IHN/+9iquDCOIsblIrOjqKgy5aKoJQj4O3EEtbPwhJbr6Te28CmdSKeqzeqr0YbfVIrTBKakvtOl5dtTkK+v4HfA9PEyBFCY9AGVgCBLaBp1jPAyfAJ/AAdIEG0dNAiyP7+K1qIfMdonZic6+WJoBJvQlvuwDqcXadUuqPA1NKAlexbRTAIMvMOCjTbMwl1LtI/6KWJ5Q6rT6Ht1MA58AX8Apcqqt5r2qhrgAXQC3CZ6i1+KMd9TRu3MvA3aH/fFPnBodb6oe6HM8+lYHrGdRXW8M9bMZtPXUji69lmf5Cmamq7quNLFZXD9Rq7v0Bpc1o/tp0fisAAAAASUVORK5CYII=)](https://github.com/marketplace/actions/my-broken-link-checker)
[![license](https://img.shields.io/github/license/ruzickap/action-my-broken-link-checker.svg)](https://github.com/ruzickap/action-my-broken-link-checker/blob/main/LICENSE)
[![release](https://img.shields.io/github/release/ruzickap/action-my-broken-link-checker.svg)](https://github.com/ruzickap/action-my-broken-link-checker/releases/latest)
[![GitHub release date](https://img.shields.io/github/release-date/ruzickap/action-my-broken-link-checker.svg)](https://github.com/ruzickap/action-my-broken-link-checker/releases)
![GitHub Actions status](https://github.com/ruzickap/action-my-broken-link-checker/workflows/docker-image/badge.svg)

This is a GitHub Action to check for broken links in your static files or web
pages. It uses [muffet](https://github.com/raviqqe/muffet) for the URL checking
task.

See the basic GitHub Action example to run periodic checks (weekly) against
[mkdocs.org](https://www.mkdocs.org):

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'

name: Check markdown links
jobs:
  my-broken-link-checker:
    name: Check broken links
    runs-on: ubuntu-latest
    steps:
      - name: Check for broken links
        uses: ruzickap/action-my-broken-link-checker@v3
        with:
          url: https://www.mkdocs.org
          cmd_params: "--one-page-only --max-connections=3 --color=always"  # Check just one page
```

Check out the real demo:

[![My Broken Link Checker demo](https://img.youtube.com/vi/H6H523TMPXk/0.jpg)](https://youtu.be/H6H523TMPXk)

This deploy action can be combined with
[Static Site Generators](https://www.staticgen.com/) (Hugo, MkDocs, Gatsby,
GitBook, mdBook, etc.). The following examples expect the web pages
to be stored in the `./build` directory. A [caddy](https://caddyserver.com/) web
server is started during the tests, using the hostname from the `URL` parameter
and serving the web pages (see details in [entrypoint.sh](./entrypoint.sh)).

```yaml
- name: Check for broken links
  uses: ruzickap/action-my-broken-link-checker@v3
  with:
    url: https://www.example.com/test123
    pages_path: ./build/
    cmd_params: '--buffer-size=8192 --max-connections=10 --color=always --skip-tls-verification --header="User-Agent:curl/7.54.0" --timeout=20'  # muffet parameters
```

Do you want to skip the Docker build step? OK, script mode is also available:

```yaml
- name: Check for broken links
  env:
    INPUT_URL: https://www.example.com/test123
    INPUT_PAGES_PATH: ./build/
    INPUT_CMD_PARAMS: '--buffer-size=8192 --max-connections=10 --color=always --header="User-Agent:curl/7.54.0" --skip-tls-verification'  # --skip-tls-verification is mandatory parameter when using https and "PAGES_PATH"
  run: wget -qO- https://raw.githubusercontent.com/ruzickap/action-my-broken-link-checker/v3/entrypoint.sh | bash
```

## Parameters

Environment variables used by `./entrypoint.sh` script.

| Variable           | Default                                                            | Description                                                                             |
|--------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `INPUT_CMD_PARAMS` | `--buffer-size=8192 --max-connections=10 --color=always --verbose` | Command-line parameters for the URL checker [muffet](https://github.com/raviqqe/muffet) |
| `INPUT_DEBUG`      | false                                                              | Enable debug mode for the `./entrypoint.sh` script (`set -x`)                           |
| `INPUT_PAGES_PATH` |                                                                    | Relative path to the directory containing local web pages                               |
| `INPUT_URL`        | (**Mandatory / Required**)                                         | URL that will be checked                                                                |

## Example of Periodic checks

Pipeline for periodic link checking:

```yaml
name: periodic-broken-link-checks

on:
  workflow_dispatch:
  push:
    paths:
      - .github/workflows/periodic-broken-link-checks.yml
  schedule:
    - cron: '3 3 * * 3'

jobs:
  broken-link-checker:
    runs-on: ubuntu-latest
    steps:

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v3

      - name: Check for broken links
        uses: ruzickap/action-my-broken-link-checker@v3
        with:
          url: ${{ steps.pages.outputs.base_url }}
          cmd_params: '--buffer-size=8192 --max-connections=10 --color=always --header="User-Agent:curl/7.54.0" --timeout=20'
```

## Full example

GitHub Action example:

```yaml
name: Checks

on:
  push:
    branches:
      - main

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Create web page
        run: |
          mkdir -v public
          cat > public/index.html << EOF
          <!DOCTYPE html>
          <html>
            <head>
              My page, which will be stored on the my-testing-domain.com domain
            </head>
            <body>
              Links:
              <ul>
                <li><a href="https://my-testing-domain.com">https://my-testing-domain.com</a></li>
                <li><a href="https://my-testing-domain.com:443">https://my-testing-domain.com:443</a></li>
              </ul>
            </body>
          </html>
          EOF

      - name: Check links using script
        env:
          INPUT_URL: https://my-testing-domain.com
          INPUT_PAGES_PATH: ./public/
          INPUT_CMD_PARAMS: '--skip-tls-verification --verbose --color=always'
          INPUT_DEBUG: true
        run: wget -qO- https://raw.githubusercontent.com/ruzickap/action-my-broken-link-checker/v3/entrypoint.sh | bash

      - name: Check links using container
        uses: ruzickap/action-my-broken-link-checker@v3
        with:
          url: https://my-testing-domain.com
          pages_path: ./public/
          cmd_params: '--skip-tls-verification --verbose --color=always'
          debug: true
```

## Best practices

Let's try to automate the creation of web pages as much as possible.

The ideal situation requires a repository naming convention where the name
of the GitHub repository matches the URL where it will be hosted.

### GitHub Pages with custom domain

The mandatory part is the repository name `awsug.cz`, which is the same as the
domain:

* Repository name: [awsugcz/awsug.cz](https://github.com/awsugcz/awsug.cz)
  -> Web pages: [https://awsug.cz](https://awsug.cz)

The web pages will be stored as GitHub Pages on their
[own domain](https://help.github.com/en/github/working-with-github-pages/configuring-a-custom-domain-for-your-github-pages-site).

The GitHub Action file may look like:

```yaml
name: hugo-build

on:
  pull_request:
    types: [opened, synchronize]
  push:

jobs:
  hugo-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Checkout submodules
        shell: bash
        run: |
          auth_header="$(git config --local --get http.https://github.com/.extraheader)"
          git submodule sync --recursive
          git -c "http.extraheader=$auth_header" -c protocol.version=2 submodule update --init --force --recursive --depth=1

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3

      - name: Build
        run: |
          hugo --gc
          cp LICENSE README.md public/
          echo "${{ github.event.repository.name }}" > public/CNAME

      - name: Check for broken links
        env:
          INPUT_URL: https://${{ github.event.repository.name }}
          INPUT_PAGES_PATH: public
          INPUT_CMD_PARAMS: '--verbose --buffer-size=8192 --max-connections=10 --color=always --skip-tls-verification --exclude="(mylabs.dev|linkedin.com)"'
        run: |
          wget -qO- https://raw.githubusercontent.com/ruzickap/action-my-broken-link-checker/v3/entrypoint.sh | bash

      - name: Check links using container
        uses: ruzickap/action-my-broken-link-checker@v3
        with:
          url: https://my-testing-domain.com
          pages_path: ./public/
          cmd_params: '--verbose --buffer-size=8192 --max-connections=10 --color=always --skip-tls-verification --header="User-Agent:curl/7.54.0" --exclude="(mylabs.dev|linkedin.com)"'
          debug: true

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v4
        if: ${{ github.event_name }} == 'push' && github.ref == 'refs/heads/main'
        env:
          ACTIONS_DEPLOY_KEY: ${{ secrets.ACTIONS_DEPLOY_KEY }}
          PUBLISH_BRANCH: gh-pages
          PUBLISH_DIR: public
        with:
          forceOrphan: true
```

The example is using [Hugo](https://gohugo.io/).

### GitHub Pages with [github.io](https://github.io) domain

The mandatory part is the repository name `k8s-harbor`, which is the directory
part at the end of `ruzickap.github.io`:

* Repository name: [ruzickap/k8s-harbor](https://github.com/ruzickap/k8s-harbor)
  -> Web pages: [https://ruzickap.github.io/k8s-harbor](https://ruzickap.github.io/k8s-harbor)

In this example, the web pages will use GitHub's domain [github.io](https://github.io).

```yaml
name: vuepress-build-check-deploy

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - .github/workflows/vuepress-build-check-deploy.yml
      - docs/**
      - package.json
      - package-lock.json
  push:
    paths:
      - .github/workflows/vuepress-build-check-deploy.yml
      - docs/**
      - package.json
      - package-lock.json

jobs:
  vuepress-build-check-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Install Node.js
        uses: actions/setup-node@v6

      - name: Install VuePress and build the document
        run: |
          npm install
          npm run build
          cp LICENSE docs/.vuepress/dist
          sed -e "s@(part-@(https://github.com/${GITHUB_REPOSITORY}/tree/main/docs/part-@" -e 's@.\/.vuepress\/public\/@./@' docs/README.md > docs/.vuepress/dist/README.md
          ln -s docs/.vuepress/dist ${{ github.event.repository.name }}

      - name: Check for broken links
        uses: ruzickap/action-my-broken-link-checker@v3
        with:
          url: https://${{ github.repository_owner }}.github.io/${{ github.event.repository.name }}
          pages_path: .
          cmd_params: '--exclude=mylabs.dev --max-connections-per-host=5 --rate-limit=5 --timeout=20 --header="User-Agent:curl/7.54.0" --skip-tls-verification'

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v4
        if: ${{ github.event_name }} == 'push' && github.ref == 'refs/heads/main'
        env:
          ACTIONS_DEPLOY_KEY: ${{ secrets.ACTIONS_DEPLOY_KEY }}
          PUBLISH_BRANCH: gh-pages
          PUBLISH_DIR: ./docs/.vuepress/dist
        with:
          forceOrphan: true
```

In this case, I'm using [VuePress](https://vuepress.vuejs.org/) to create my
page.

![GitHub Action my-broken-link-checker](./images/actions-my-broken-link-checker.png
"GitHub Action my-broken-link-checker")

---

Both examples can be used as a **generic template**, and you do not need to
change them for your projects.

## Running locally

It's possible to use the checking script locally. It will install [Caddy](https://caddyserver.com/)
and [Muffet](https://github.com/raviqqe/muffet) binaries if they are not already
installed on your system.

```bash
export INPUT_URL="https://debian.cz/info/"
export INPUT_CMD_PARAMS="--buffer-size=8192 --ignore-fragments --one-page-only --max-connections=10 --color=always --verbose"
./entrypoint.sh
```

Output:

```text
*** INFO: [2024-01-26 05:12:20] Start checking: "https://www.mkdocs.org"
https://www.mkdocs.org/
    200 https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js
    200 https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/django.min.js
    200 https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/yaml.min.js
    200 https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/github.min.css
    200 https://github.com/mkdocs/catalog#-theming
    200 https://github.com/mkdocs/mkdocs/blob/master/docs/index.md
    200 https://github.com/mkdocs/mkdocs/wiki/MkDocs-Themes
    200 https://twitter.com/starletdreaming
    200 https://www.googletagmanager.com/gtag/js?id=G-274394082
    200 https://www.mkdocs.org/
    200 https://www.mkdocs.org/#mkdocs
    200 https://www.mkdocs.org/about/contributing/
    200 https://www.mkdocs.org/about/license/
    200 https://www.mkdocs.org/about/release-notes/
    200 https://www.mkdocs.org/about/release-notes/#maintenance-team
    200 https://www.mkdocs.org/assets/_mkdocstrings.css
    200 https://www.mkdocs.org/css/base.css
    200 https://www.mkdocs.org/css/bootstrap.min.css
    200 https://www.mkdocs.org/css/extra.css
    200 https://www.mkdocs.org/css/font-awesome.min.css
    200 https://www.mkdocs.org/dev-guide/
    200 https://www.mkdocs.org/dev-guide/api/
    200 https://www.mkdocs.org/dev-guide/plugins/
    200 https://www.mkdocs.org/dev-guide/themes/
    200 https://www.mkdocs.org/dev-guide/translations/
    200 https://www.mkdocs.org/getting-started/
    200 https://www.mkdocs.org/img/favicon.ico
    200 https://www.mkdocs.org/js/base.js
    200 https://www.mkdocs.org/js/bootstrap.min.js
    200 https://www.mkdocs.org/js/jquery-3.6.0.min.js
    200 https://www.mkdocs.org/search/main.js
    200 https://www.mkdocs.org/user-guide/
    200 https://www.mkdocs.org/user-guide/choosing-your-theme
    200 https://www.mkdocs.org/user-guide/choosing-your-theme/
    200 https://www.mkdocs.org/user-guide/choosing-your-theme/#mkdocs
    200 https://www.mkdocs.org/user-guide/choosing-your-theme/#readthedocs
    200 https://www.mkdocs.org/user-guide/cli/
    200 https://www.mkdocs.org/user-guide/configuration/
    200 https://www.mkdocs.org/user-guide/configuration/#markdown_extensions
    200 https://www.mkdocs.org/user-guide/configuration/#plugins
    200 https://www.mkdocs.org/user-guide/customizing-your-theme/
    200 https://www.mkdocs.org/user-guide/deploying-your-docs/
    200 https://www.mkdocs.org/user-guide/installation/
    200 https://www.mkdocs.org/user-guide/localizing-your-theme/
    200 https://www.mkdocs.org/user-guide/writing-your-docs/
*** INFO: [2024-01-26 05:12:21] Checks completed...
```

![my-broken-link-checker-demo](./demo/my-broken-link-checker-demo.svg "my-broken-link-checker-demo")

Another example is checking a web page stored locally on your disk. In this
case, I'm using the web page created in the `./tests/` directory from this
Git repository:

```bash
export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}/tests/"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose --color=always"
./entrypoint.sh
```

Output:

```text
*** INFO: Using path "/home/pruzicka/git/action-my-broken-link-checker/tests/" as domain "my-testing-domain.com" with URI "https://my-testing-domain.com"
*** INFO: [2019-12-30 14:54:22] Start checking: "https://my-testing-domain.com"
https://my-testing-domain.com/
        200     https://my-testing-domain.com
        200     https://my-testing-domain.com/run_tests.sh
        200     https://my-testing-domain.com:443
        200     https://my-testing-domain.com:443/run_tests.sh
https://my-testing-domain.com:443/
        200     https://my-testing-domain.com
        200     https://my-testing-domain.com/run_tests.sh
        200     https://my-testing-domain.com:443
        200     https://my-testing-domain.com:443/run_tests.sh
*** INFO: [2019-12-30 14:54:22] Checks completed...
```

## Examples

Some other examples of building and checking web pages using
[Static Site Generators](https://www.staticgen.com/) and GitHub Actions can be
found here: [https://github.com/peaceiris/actions-gh-pages/](https://github.com/peaceiris/actions-gh-pages/).

The following links contain real examples of My Broken Link Checker:

* [hugo-build](https://github.com/awsugcz/awsug.cz/actions?query=workflow%3Ahugo-build)
  * Static page generated by [Hugo](https://gohugo.io/) with checked links: [hugo-build.yml](https://github.com/awsugcz/awsug.cz/blob/7754eca1efbf8d6d1028ddd93f5d8db98137186c/.github/workflows/hugo-build.yml#L29-L37).

* [vuepress-build-check-deploy](https://github.com/ruzickap/k8s-harbor/actions/workflows/vuepress-build-check-deploy.yml)
  * Static page generated by [VuePress](https://vuepress.vuejs.org/) with
    checked links: [vuepress-build-check-deploy.yml](https://github.com/ruzickap/k8s-harbor/blob/7973e8c2df395999e38271ba863e307a5da07f49/.github/workflows/vuepress-build-check-deploy.yml#L93-L100).

* [periodic-broken-link-checks](https://github.com/ruzickap/xvx.cz/actions?query=workflow%3Aperiodic-broken-link-checks)
  * Periodic link checks of the [xvx.cz](http://xvx.cz) website using: [periodic-broken-link-checks.yml](https://github.com/ruzickap/xvx.cz/blob/dc2501725f05b59f64f990d4f478609a982e669a/.github/workflows/periodic-broken-link-checks.yml#L11-L34).
