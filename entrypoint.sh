#!/usr/bin/env bash

set -Eeuo pipefail

# renovate: datasource=github-tags depName=raviqqe/muffet
export MUFFET_VERSION="2.6.2"
# renovate: datasource=github-tags depName=caddyserver/caddy
export CADDY_VERSION="2.6.2"

# Command line parameters for muffet
export CMD_PARAMS="${INPUT_CMD_PARAMS:- --buffer-size=8192 --max-connections=10 --color=always --verbose}"
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
# Debug variable - enable by setting non-empty value
export DEBUG=${INPUT_DEBUG:-}
# Create caddy log file where will be all the log messages form the caddy server
CADDY_LOG=$( mktemp /tmp/Caddy-log.XXXXXX )
# Create caddy configuration to run web server using the domain set in PAGES_DOMAIN + /etc/hosts
CADDYFILE=$( mktemp /tmp/Caddyfile.XXXXXX )

if [ $EUID != 0 ]; then
  sudo_cmd="sudo"
else
  sudo_cmd=""
fi

print_error() {
  echo -e "\e[31m*** ERROR: ${1}\e[m"
}

print_info() {
  echo -e "\e[36m*** INFO: ${1}\e[m"
}

# Remove all added files or changed /etc/hosts entry
cleanup() {
  if [ -n "${PAGES_PATH}" ]; then
    $sudo_cmd sed -i "/127.0.0.1 ${PAGES_DOMAIN}  # Created by my-broken-link-checker/d" /etc/hosts || true
    $sudo_cmd caddy stop &> /dev/null
    [ -f "${CADDYFILE}" ] && rm "${CADDYFILE}"
    [ -f "${CADDY_LOG}" ] && rm "${CADDY_LOG}"
  fi
}

error_trap() {
  cat "${CADDY_LOG}"
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

  if [ "${MUFFET_VERSION}" = "latest" ]; then
    MUFFET_URL=$(wget -qO- https://api.github.com/repos/raviqqe/muffet/releases/latest | grep "browser_download_url.*muffet_.*_$(uname)_x86_64.tar.gz" | cut -d \" -f 4)
  else
    MUFFET_URL="https://github.com/raviqqe/muffet/releases/download/v${MUFFET_VERSION}/muffet_${MUFFET_VERSION}_$(uname)_x86_64.tar.gz"
  fi

  wget -qO- "${MUFFET_URL}" | $sudo_cmd tar xzf - -C /usr/local/bin/ muffet
fi

# Install caddy if needed
if ! hash caddy &> /dev/null && [ -n "${PAGES_PATH}" ] ; then

  if [[ $(uname) = "Darwin" ]]; then
    PLATFORM="mac"
  elif [[ $(uname) = "Linux" ]]; then
    PLATFORM="linux"
  fi

  if [ "${CADDY_VERSION}" = "latest" ]; then
    CADDY_URL=$(wget --quiet https://api.github.com/repos/caddyserver/caddy/releases/latest -O - | grep "browser_download_url.*caddy_.*_${PLATFORM}_amd64.tar.gz" | cut -d \" -f 4)
  else
    CADDY_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_${PLATFORM}_amd64.tar.gz"
  fi

  wget --quiet "${CADDY_URL}" -O - | $sudo_cmd tar xzf - -C /usr/local/bin/ caddy
fi

IFS=' ' read -r -a CMD_PARAMS <<< "$CMD_PARAMS"

# Use muffet in case of external URL check is required
if [ -z "${PAGES_PATH}" ] ; then
  # Run check
  print_info "[$(date +'%F %T')] Start checking: \"${URL}\""
  muffet "${CMD_PARAMS[@]}" "${URL}"

else

  print_info "Using path \"${PAGES_PATH}\" as domain \"${PAGES_DOMAIN}\" with URI \"${PAGES_URI}\""

  # Die if the specified path which should contain local web pages doesn't exist
  if [ ! -d "${PAGES_PATH}" ]; then
    print_error "Path specified as 'INPUT_PAGES_PATH': '${PAGES_PATH}' doesn't exist!"
    exit 1
  fi

  # Add domain into /etc/hosts
  if ! grep -q "${PAGES_DOMAIN}" /etc/hosts ; then
    $sudo_cmd bash -c "echo \"127.0.0.1 ${PAGES_DOMAIN}  # Created by my-broken-link-checker\" >> /etc/hosts"
  fi

  {
    echo "${PAGES_URI} {"
    echo "  root * ${PAGES_PATH}"
    echo "  file_server"
    if [[ "${PAGES_URI}" =~ ^https: ]]; then echo "  tls internal"; fi
    echo "}"
  } > "${CADDYFILE}"

  # Run caddy web server on the background
  $sudo_cmd caddy start --config "${CADDYFILE}" &> "${CADDY_LOG}"
  sleep 1

  # Run check
  print_info "[$(date +'%F %T')] Start checking: \"${URL}\""
  muffet "${CMD_PARAMS[@]}" "${URL}"
  cleanup

fi

print_info "[$(date +'%F %T')] Checks completed..."
