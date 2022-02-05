# GitHub Actions: My Broken Link Checker ✔

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-My%20Broken%20Link%20Checker-blue.svg?colorA=24292e&colorB=0366d6&style=flat&longCache=true&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAM6wAADOsB5dZE0gAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAERSURBVCiRhZG/SsMxFEZPfsVJ61jbxaF0cRQRcRJ9hlYn30IHN/+9iquDCOIsblIrOjqKgy5aKoJQj4O3EEtbPwhJbr6Te28CmdSKeqzeqr0YbfVIrTBKakvtOl5dtTkK+v4HfA9PEyBFCY9AGVgCBLaBp1jPAyfAJ/AAdIEG0dNAiyP7+K1qIfMdonZic6+WJoBJvQlvuwDqcXadUuqPA1NKAlexbRTAIMvMOCjTbMwl1LtI/6KWJ5Q6rT6Ht1MA58AX8Apcqqt5r2qhrgAXQC3CZ6i1+KMd9TRu3MvA3aH/fFPnBodb6oe6HM8+lYHrGdRXW8M9bMZtPXUji69lmf5Cmamq7quNLFZXD9Rq7v0Bpc1o/tp0fisAAAAASUVORK5CYII=)](https://github.com/marketplace/actions/my-broken-link-checker)
[![license](https://img.shields.io/github/license/ruzickap/action-my-broken-link-checker.svg)](https://github.com/ruzickap/action-my-broken-link-checker/blob/main/LICENSE)
[![release](https://img.shields.io/github/release/ruzickap/action-my-broken-link-checker.svg)](https://github.com/ruzickap/action-my-broken-link-checker/releases/latest)
[![GitHub release date](https://img.shields.io/github/release-date/ruzickap/action-my-broken-link-checker.svg)](https://github.com/ruzickap/action-my-broken-link-checker/releases)
![GitHub Actions status](https://github.com/ruzickap/action-my-broken-link-checker/workflows/docker-image/badge.svg)
[![Docker Hub Build Status](https://img.shields.io/docker/cloud/build/peru/my-broken-link-checker.svg)](https://hub.docker.com/r/peru/my-broken-link-checker)

This is a GitHub Action to check broken link in your static files or web pages.
The [muffet](https://github.com/raviqqe/muffet) is used for URL checking task.

See the basic GitHub Action example to run periodic checks (weekly)
against [google.com](https://google.com):

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
      - name: Check
        uses: ruzickap/action-my-broken-link-checker@v2
        with:
          url: https://www.google.com
          cmd_params: "--one-page-only --max-connections=3 --color=always"  # Check just one page
```

Check out the real demo:

[![My Broken Link Checker demo](https://img.youtube.com/vi/H6H523TMPXk/0.jpg)](https://youtu.be/H6H523TMPXk)

This deploy action can be combined with [Static Site Generators](https://www.staticgen.com/)
(Hugo, MkDocs, Gatsby, GitBook, mdBook, etc.). The following examples expects
to have the web page stored in `./build` directory. There is a [caddy](https://caddyserver.com/)
web server started during the tests which is using the hostname from the `URL`
parameter and serving the web pages (see the details in [entrypoint.sh](./entrypoint.sh)).

```yaml
- name: Check
  uses: ruzickap/action-my-broken-link-checker@v2
  with:
    url: https://www.example.com/test123
    pages_path: ./build/
    cmd_params: '--buffer-size=8192 --max-connections=10 --color=always --skip-tls-verification --header="User-Agent:curl/7.54.0" --timeout=20'  # muffet parameters
```

Do you want to skip the docker build step? OK, the script mode is also available:

```yaml
- name: Check
  env:
    INPUT_URL: https://www.example.com/test123
    INPUT_PAGES_PATH: ./build/
    INPUT_CMD_PARAMS: '--buffer-size=8192 --max-connections=10 --color=always --header="User-Agent:curl/7.54.0" --skip-tls-verification'  # --skip-tls-verification is mandatory parameter when using https and "PAGES_PATH"
  run: wget -qO- https://raw.githubusercontent.com/ruzickap/action-my-broken-link-checker/v2/entrypoint.sh | bash
```

## Parameters

Environment variables used by `./entrypoint.sh` script.

| Variable            | Default                                                            | Description                                                                                                                                                              |
| ------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `INPUT_CMD_PARAMS`  | `--buffer-size=8192 --max-connections=10 --color=always --verbose` | Command-line parameters for URL checker [muffet](https://github.com/raviqqe/muffet) - details [here](https://github.com/raviqqe/muffet/blob/master/arguments.go#L16-L34) |
| `INPUT_DEBUG`       | false                                                              | Enable debug mode for the `./entrypoint.sh` script (`set -x`)                                                                                                            |
| `INPUT_PAGES_PATH`  |                                                                    | Relative path to the directory with local web pages                                                                                                                      |
| `INPUT_URL`         | (**Mandatory / Required**)                                         | URL which will be checked                                                                                                                                                |

## Example of Periodic checks

Pipeline for periodic link checks:

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

      - name: Get GH Pages URL
        id: gh_pages_url
        uses: actions/github-script@v5
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            let result = await github.request('GET /repos/:owner/:repo/pages', {
              owner: context.repo.owner,
              repo: context.repo.repo
            });
            console.log(result.data.html_url);
            return result.data.html_url
          result-encoding: string

      - name: Check broken links
        uses: ruzickap/action-my-broken-link-checker@v2
        with:
          url: ${{ steps.gh_pages_url.outputs.result }}
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
              My page which will be stored on my-testing-domain.com domain
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
        run: wget -qO- https://raw.githubusercontent.com/ruzickap/action-my-broken-link-checker/v2/entrypoint.sh | bash

      - name: Check links using container
        uses: ruzickap/action-my-broken-link-checker@v2
        with:
          url: https://my-testing-domain.com
          pages_path: ./public/
          cmd_params: '--skip-tls-verification --verbose --color=always'
          debug: true
```

## Best practices

Let's try to automate the creating the web pages as much as possible.

The ideal situation require the repository naming convention, where the name of
the GitHub repository should match the URL where it will be hosted.

### GitHub Pages with custom domain

The mandatory part is the repository name `awsug.cz` which is the same as the
domain:

* Repository name: [awsugcz/awsug.cz](https://github.com/awsugcz/awsug.cz)
  \-> Web pages: [https://awsug.cz](https://awsug.cz)

The web pages will be stored as GitHub Pages on it's [own domain](https://help.github.com/en/github/working-with-github-pages/configuring-a-custom-domain-for-your-github-pages-site).

The GH Action file may looks like:

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
      - uses: actions/checkout@v2

      - name: Checkout submodules
        shell: bash
        run: |
          auth_header="$(git config --local --get http.https://github.com/.extraheader)"
          git submodule sync --recursive
          git -c "http.extraheader=$auth_header" -c protocol.version=2 submodule update --init --force --recursive --depth=1

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.62.0'

      - name: Build
        run: |
          hugo --gc
          cp LICENSE README.md public/
          echo "${{ github.event.repository.name }}" > public/CNAME

      - name: Check broken links
        env:
          INPUT_URL: https://${{ github.event.repository.name }}
          INPUT_PAGES_PATH: public
          INPUT_CMD_PARAMS: '--verbose --buffer-size=8192 --max-connections=10 --color=always --skip-tls-verification --exclude="(mylabs.dev|linkedin.com)"'
        run: |
          wget -qO- https://raw.githubusercontent.com/ruzickap/action-my-broken-link-checker/v2/entrypoint.sh | bash

      - name: Check links using container
        uses: ruzickap/action-my-broken-link-checker@v2
        with:
          url: https://my-testing-domain.com
          pages_path: ./public/
          cmd_params: '--verbose --buffer-size=8192 --max-connections=10 --color=always --skip-tls-verification --header="User-Agent:curl/7.54.0" --exclude="(mylabs.dev|linkedin.com)"'
          debug: true

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
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

The mandatory part is the repository name `k8s-harbor` which is the directory
part at the and of `ruzickap.github.io`:

* Repository name: [ruzickap/k8s-harbor](https://github.com/ruzickap/k8s-harbor)
  \-> Web pages: [https://ruzickap.github.io/k8s-harbor](https://ruzickap.github.io/k8s-harbor)

In the example the web pages will be using GitHub's domain [github.io](https://github.io).

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
      - uses: actions/checkout@v2

      - name: Install Node.js 12
        uses: actions/setup-node@v1
        with:
          node-version: 12.x

      - name: Install VuePress and build the document
        run: |
          npm install
          npm run build
          cp LICENSE docs/.vuepress/dist
          sed -e "s@(part-@(https://github.com/${GITHUB_REPOSITORY}/tree/main/docs/part-@" -e 's@.\/.vuepress\/public\/@./@' docs/README.md > docs/.vuepress/dist/README.md
          ln -s docs/.vuepress/dist ${{ github.event.repository.name }}

      - name: Check broken links
        uses: ruzickap/action-my-broken-link-checker@v2
        with:
          url: https://${{ github.repository_owner }}.github.io/${{ github.event.repository.name }}
          pages_path: .
          cmd_params: '--exclude=mylabs.dev --max-connections-per-host=5 --rate-limit=5 --timeout=20 --header="User-Agent:curl/7.54.0" --skip-tls-verification'

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        if: ${{ github.event_name }} == 'push' && github.ref == 'refs/heads/main'
        env:
          ACTIONS_DEPLOY_KEY: ${{ secrets.ACTIONS_DEPLOY_KEY }}
          PUBLISH_BRANCH: gh-pages
          PUBLISH_DIR: ./docs/.vuepress/dist
        with:
          forceOrphan: true
```

In this case I'm using [VuePress](https://vuepress.vuejs.org/) to create my
page.

![GitHub Action my-broken-link-checker](./images/actions-my-broken-link-checker.png
"GitHub Action my-broken-link-checker")

---

Both examples can be used as a **generic template**, and you do not need to
change them for your projects.

## Running locally

It's possible to use the checking script locally. It will install [caddy](https://caddyserver.com/)
and [muffet](https://github.com/raviqqe/muffet) binaries if they
are not already installed on your system.

```bash
export INPUT_URL="https://google.com"
export INPUT_CMD_PARAMS="--ignore-fragments --one-page-only --max-connections=10 --color=always --verbose"
./entrypoint.sh
```

Output:

```text
*** INFO: [2019-12-30 14:53:54] Start checking: "https://google.com"
https://www.google.com/
        200     http://www.google.cz/history/optout?hl=cs
        200     http://www.google.cz/intl/cs/services/
        200     https://accounts.google.com/ServiceLogin?hl=cs&passive=true&continue=https://www.google.com/
        200     https://drive.google.com/?tab=wo
        200     https://mail.google.com/mail/?tab=wm
        200     https://maps.google.cz/maps?hl=cs&tab=wl
        200     https://news.google.cz/nwshp?hl=cs&tab=wn
        200     https://play.google.com/?hl=cs&tab=w8
        200     https://www.google.com/advanced_search?hl=cs&authuser=0
        200     https://www.google.com/images/branding/googlelogo/1x/googlelogo_white_background_color_272x92dp.png
        200     https://www.google.com/intl/cs/about.html
        200     https://www.google.com/intl/cs/ads/
        200     https://www.google.com/intl/cs/policies/privacy/
        200     https://www.google.com/intl/cs/policies/terms/
        200     https://www.google.com/language_tools?hl=cs&authuser=0
        200     https://www.google.com/preferences?hl=cs
        200     https://www.google.com/setprefdomain?prefdom=CZ&prev=https://www.google.cz/&sig=K_WmKyDZc24PJiXFyTjsUeLLrG-P4%3D
        200     https://www.google.com/textinputassistant/tia.png
        200     https://www.google.cz/imghp?hl=cs&tab=wi
        200     https://www.google.cz/intl/cs/about/products?tab=wh
        200     https://www.youtube.com/?gl=CZ&tab=w1
*** INFO: [2019-12-30 14:53:55] Checks completed...
```

You can also use the advantage of the container to run the checks locally
without touching your system:

```bash
export INPUT_URL="https://google.com"
export INPUT_CMD_PARAMS="--ignore-fragments --one-page-only --max-connections=10 --color=always --verbose"
docker run --rm -t -e INPUT_URL -e INPUT_CMD_PARAMS peru/my-broken-link-checker
```

![my-broken-link-checker-demo](./demo/my-broken-link-checker-demo.svg "my-broken-link-checker-demo")

Another example when checking the the web page locally stored on your disk.
In this case I'm using the web page created in the `./tests/` directory from
this git repository:

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

The same example as above, but in this case I'm using the container:

```bash
export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}/tests/"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose"
docker run --rm -t -e INPUT_URL -e INPUT_CMD_PARAMS -e INPUT_PAGES_PATH -v "$INPUT_PAGES_PATH:$INPUT_PAGES_PATH" peru/my-broken-link-checker
```

## Examples

Some other examples of building and checking web pages using [Static Site Generators](https://www.staticgen.com/)
and GitHub Actions can be found here: [https://github.com/peaceiris/actions-gh-pages/](https://github.com/peaceiris/actions-gh-pages/)

The following links contains real examples of My Broken Link Checker:

* [hugo-build](https://github.com/awsugcz/awsug.cz/actions?query=workflow%3Ahugo-build)
  * Static page generated by [Hugo](https://gohugo.io/)
    with checked links: [hugo-build.yml](https://github.com/awsugcz/awsug.cz/blob/7754eca1efbf8d6d1028ddd93f5d8db98137186c/.github/workflows/hugo-build.yml#L29-L37)

* [vuepress-build-check-deploy](https://github.com/ruzickap/k8s-harbor/runs/1009697889)
  * Static page generated by [VuePress](https://vuepress.vuejs.org/)
    with checked links: [vuepress-build-check-deploy.yml](https://github.com/ruzickap/k8s-harbor/blob/7973e8c2df395999e38271ba863e307a5da07f49/.github/workflows/vuepress-build-check-deploy.yml#L93-L100)

* [periodic-broken-link-checks](https://github.com/ruzickap/xvx.cz/actions?query=workflow%3Aperiodic-broken-link-checks)
  * Periodic link checks of [xvx.cz](http://xvx.cz) website
    using: [periodic-broken-link-checks.yml](https://github.com/ruzickap/xvx.cz/blob/dc2501725f05b59f64f990d4f478609a982e669a/.github/workflows/periodic-broken-link-checks.yml#L11-L34)
