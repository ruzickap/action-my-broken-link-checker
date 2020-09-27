#!/usr/bin/env bash

# Record using: termtosvg --screen-geometry 93x30 --command ./my-broken-link-checker-demo.sh

set -u

################################################
# include the magic
################################################
test -s ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
# shellcheck disable=SC1091
. ./demo-magic.sh

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
export TYPE_SPEED=60

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=1

# No wait
export NO_WAIT=false

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
export DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

# hide the evidence
clear

p 'This is example of my-broken-link-checker usage...'

p ''

p 'Set the INPUT_URL variable to "google.com":'
pe 'export INPUT_URL="https://google.com"'

p ''

p 'Add some extra muffet parameters to INPUT_CMD_PARAMS variable:'
pe 'export INPUT_CMD_PARAMS="--ignore-fragments --one-page-only --max-connections=10 --verbose"'

p ''

p 'Run the container image "peru/my-broken-link-checker" to start checking:'
pe 'docker run --rm -t -e INPUT_URL -e INPUT_CMD_PARAMS peru/my-broken-link-checker'

sleep 3

p '...'

rm ./demo-magic.sh
