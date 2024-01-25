#!/usr/bin/env bash

set -euxo pipefail

# Test entrypoint.sh script
export INPUT_DEBUG="true"

echo -e "\n\n\e[32m!!! Check differnet URLs types\e[m"
export INPUT_CMD_PARAMS="--one-page-only --buffer-size=8192 --max-connections=10 --verbose --color=always"

export INPUT_URL="https://xvx.cz"
../entrypoint.sh

export INPUT_URL="https://xvx.cz:443"
../entrypoint.sh

export INPUT_URL="https://debian.cz:443/info/"
../entrypoint.sh

export INPUT_URL="http://debian.cz/info"
../entrypoint.sh

echo -e "\n\n\e[32m!!! Test locally stored web pages (PAGES_PATH)\e[m"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose --color=always"

export INPUT_URL="http://my-testing-domain.com/index2.html"
export INPUT_PAGES_PATH="${PWD}"
../entrypoint.sh

export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}"
../entrypoint.sh

echo -e "\n\n\e[32m!!! Test docker image\e[m"
docker build .. -t my-broken-link-checker-test

export INPUT_URL="https://debian.cz/develop/"
export INPUT_CMD_PARAMS="--one-page-only --buffer-size=8192 --max-connections=10 --verbose --color=always"
docker run --rm -t -e INPUT_DEBUG -e INPUT_URL -e INPUT_CMD_PARAMS my-broken-link-checker-test

export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose --color=always"
docker run --rm -t -e INPUT_DEBUG -e INPUT_URL -e INPUT_CMD_PARAMS -e INPUT_PAGES_PATH -v "$INPUT_PAGES_PATH:$INPUT_PAGES_PATH" my-broken-link-checker-test

export INPUT_URL="http://my-testing-domain.com/index2.html"
export INPUT_PAGES_PATH="${PWD}"
export INPUT_CMD_PARAMS="--verbose --color=always"
docker run --rm -t -e INPUT_DEBUG -e INPUT_URL -e INPUT_CMD_PARAMS -e INPUT_PAGES_PATH -v "$INPUT_PAGES_PATH:$INPUT_PAGES_PATH" my-broken-link-checker-test
