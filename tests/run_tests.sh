#!/bin/bash -eux

# Test entrypoint.sh script
export INPUT_DEBUG="true"


echo -e "\n\n\e[32m!!! Check differnet URLs types\e[m"
export INPUT_CMD_PARAMS="--one-page-only --buffer-size=8192 --concurrency=10 --verbose"

export INPUT_URL="https://google.com"
../entrypoint.sh

export INPUT_URL="https://google.com:443"
../entrypoint.sh

export INPUT_URL="https://google.com:443/search"
../entrypoint.sh


echo -e "\n\n\e[32m!!! Test locally stored web pages (PAGES_PATH)\e[m"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose"

export INPUT_URL="http://my-testing-domain.com/index2.html"
export INPUT_PAGES_PATH="${PWD}"
../entrypoint.sh

export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}"
../entrypoint.sh


echo -e "\n\n\e[32m!!! Test docker image\e[m"
docker build .. -t my-broken-link-checker-test

export INPUT_URL="https://google.com"
export INPUT_CMD_PARAMS="--one-page-only --buffer-size=8192 --concurrency=10 --verbose"
docker run --rm -t -e INPUT_DEBUG -e INPUT_URL -e INPUT_CMD_PARAMS my-broken-link-checker-test

export INPUT_URL="https://my-testing-domain.com"
export INPUT_PAGES_PATH="${PWD}"
export INPUT_CMD_PARAMS="--skip-tls-verification --verbose"
docker run --rm -t -e INPUT_DEBUG -e INPUT_URL -e INPUT_CMD_PARAMS -e INPUT_PAGES_PATH -v "$INPUT_PAGES_PATH:$INPUT_PAGES_PATH" my-broken-link-checker-test

export INPUT_URL="http://my-testing-domain.com/index2.html"
export INPUT_PAGES_PATH="${PWD}"
export INPUT_CMD_PARAMS="--verbose"
docker run --rm -t -e INPUT_DEBUG -e INPUT_URL -e INPUT_CMD_PARAMS -e INPUT_PAGES_PATH -v "$INPUT_PAGES_PATH:$INPUT_PAGES_PATH" my-broken-link-checker-test
