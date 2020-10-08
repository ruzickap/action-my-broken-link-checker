#!/bin/bash -ux

export INPUT_DEBUG="true"

echo -e "\n\n\e[32m!!! Test when RUN_TIMEOUT is too tight\e[m"

export INPUT_CMD_PARAMS="--one-page-only --max-connections=1 --verbose --color=always"
export INPUT_RUN_TIMEOUT="1"
export INPUT_URL="https://google.com"
../entrypoint.sh
unset INPUT_RUN_TIMEOUT

echo -e "\n\n\e[32m!!! Test nonexisting directory specified as PAGES_PATH\e[m"

export INPUT_PAGES_PATH="/non-existing-dir"
export INPUT_URL="https://google.com"
../entrypoint.sh

echo -e "\n\n\e[32m!!! Test broken links by accessing wrong non existing domain\e[m"

export INPUT_PAGES_PATH="$PWD"
export INPUT_URL="https://non-existing-domain.com"
../entrypoint.sh

echo -e "\n\n\e[32m!!! Test broken links by accessing non existing links\e[m"

export INPUT_PAGES_PATH="$PWD"
export INPUT_CMD_PARAMS="--skip-tls-verification --color=always"
export INPUT_URL="https://my-testing-domain.com/index2.html"
../entrypoint.sh
