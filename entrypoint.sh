#!/bin/bash

set -euo pipefail

# Command line parameters for muffet
export CMD_PARAMS="${INPUT_CMD_PARAMS:---buffer-size=8192 --concurrency=10}"
# Set path variable containing web pages
export PAGES_PATH=${INPUT_PAGES_PATH:-}
# URL to scan / check
export URL=${INPUT_URL:?}
# Domain where the web pages will be hosted (test.example.com), it will be stored in /etc/hosts
PAGES_DOMAIN=$( echo "${URL}" | awk -F[/:] '{print $4}' )
export PAGES_DOMAIN
# URI used by caddy to serve locally stored web pages (https://test.example.com)
PAGES_URI=$( echo "${URL}" | cut -d / -f 1,2,3 )
export PAGES_URI
# Maximum number of seconds that URL checker can be running
export RUN_TIMEOUT="${INPUT_RUN_TIMEOUT:-300}"
# Debug variable - enable by setting non-empty value
export DEBUG=${INPUT_DEBUG:-}

function print_error() {
  echo -e "\e[31m*** ERROR: ${1}\e[m"
}

function print_info() {
  echo -e "\e[36m*** INFO: ${1}\e[m"
}

# Remove all added files or changed /etc/hosts entry
function cleanup() {
  if [ -n "${PAGES_PATH}" ]; then
    # Manipulation with /etc/hosts using 'sed -i' doesn't work inside containers
    if ! grep -q docker /proc/1/cgroup ; then
      sudo sed -i "/127.0.0.1 ${PAGES_DOMAIN}  # Created by my-broken-link-checker/d" /etc/hosts
    fi
    [ -s "${CADDY_PIDFILE}" ] && sudo kill "$(cat "${CADDY_PIDFILE}")"
    [ -f "${CADDYFILE}" ] && rm "${CADDYFILE}"
  fi
}

function error_trap() {
  cleanup
  print_error "[$(date +'%F %T')] Something went wrong - see the errors above..."
}

################
# Main
################

trap error_trap ERR

[ -n "${DEBUG}" ] && set -x

# Install muffet if needed
if ! hash muffet &> /dev/null ; then
  MUFFET_URL=$(wget --quiet https://api.github.com/repos/raviqqe/muffet/releases/latest -O - | grep "browser_download_url.*muffet_.*_Linux_x86_64.tar.gz" | cut -d \" -f 4)
  wget --quiet "${MUFFET_URL}" -O - | sudo tar xzf - -C /usr/local/bin/ muffet
fi

# Install caddy if needed
if ! hash caddy &> /dev/null && [ -n "${PAGES_PATH}" ] ; then
  wget -qO- https://getcaddy.com | sudo bash -s personal > /dev/null
fi

# Use muffet in case of external URL check is required
if [ -z "${PAGES_PATH}" ] ; then
  # Run check
  print_info "[$(date +'%F %T')] Start checking: \"${URL}\""
  # shellcheck disable=SC2086
  timeout "${RUN_TIMEOUT}" muffet ${CMD_PARAMS} "${URL}"

else

  print_info "Using path \"${PAGES_PATH}\" as domain \"${PAGES_DOMAIN}\" with URI \"${PAGES_URI}\""

  # Die if the specified path which should contain local web pages doesn't exist
  if [ ! -d "${PAGES_PATH}" ]; then
    print_error "Path specified as 'INPUT_PAGES_PATH': '${PAGES_PATH}' doesn't exist!"
    exit 1
  fi

  # Add domain into /etc/hosts
  if ! grep -q "${PAGES_DOMAIN}" /etc/hosts ; then
    sudo bash -c "echo \"127.0.0.1 ${PAGES_DOMAIN}  # Created by my-broken-link-checker\" >> /etc/hosts"
  fi

  # Create caddy configuration to run web server using the domain set in PAGES_DOMAIN + /etc/hosts
  CADDYFILE=$( mktemp /tmp/Caddyfile.XXXXXX )
  CADDY_PIDFILE=$( mktemp -u /tmp/Caddy_pidfile.XXXXXX )
  echo -e "${PAGES_URI}\n root ${PAGES_PATH}\n tls self_signed" > "${CADDYFILE}"

  # Run caddy web server on the background
  sudo caddy -conf "${CADDYFILE}" -pidfile "${CADDY_PIDFILE}" -quiet &
  sleep 1

  # Run check
  print_info "[$(date +'%F %T')] Start checking: \"${URL}\""
  # shellcheck disable=SC2086
  timeout "${RUN_TIMEOUT}" muffet ${CMD_PARAMS} "${URL}"
  cleanup

fi

print_info "[$(date +'%F %T')] Checks completed..."
