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

echo -e "\n\n\e[32m!!! Test host already mapped to another address in /etc/hosts\e[m"

SUDO=$([ "${EUID}" -eq 0 ] || echo sudo)
echo "192.0.2.1 my-testing-domain.test  # added by fail_tests.sh" | ${SUDO} tee -a /etc/hosts > /dev/null
export INPUT_URL="https://my-testing-domain.test"
OUTPUT=$(../entrypoint.sh 2>&1) || true
${SUDO} sed -i "/# added by fail_tests.sh/d" /etc/hosts
echo "${OUTPUT}"
grep -q "already maps" <<< "${OUTPUT}"

echo -e "\n\n\e[32m!!! All cases failed as expected\e[m"
