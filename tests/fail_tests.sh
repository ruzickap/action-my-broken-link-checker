#!/usr/bin/env bash

set -euxo pipefail

# Every case must make entrypoint.sh fail - an unexpected success fails this script
export INPUT_DEBUG="true"

echo -e "\n\n\e[32m!!! Test nonexisting directory specified as PAGES_PATH\e[m"

export INPUT_PAGES_PATH="/non-existing-dir"
export INPUT_URL="https://www.mkdocs.org"
../entrypoint.sh && exit 1

echo -e "\n\n\e[32m!!! Test broken links by accessing wrong non existing domain\e[m"

export INPUT_PAGES_PATH="$PWD"
export INPUT_URL="https://non-existing-domain.test"
../entrypoint.sh && exit 1

echo -e "\n\n\e[32m!!! Test non existing page with '&' in the URL (it must not be run as shell code)\e[m"

export INPUT_PAGES_PATH="$PWD"
export INPUT_CMD_PARAMS="--skip-tls-verification --color=always --header='User-Agent:curl/7.54.0'"
export INPUT_URL="https://my-testing-domain.test/missing.html?a=1&b=2"
../entrypoint.sh && exit 1

echo -e "\n\n\e[32m!!! All cases failed as expected\e[m"
