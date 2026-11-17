#!/usr/bin/env bash

set -Eeuo pipefail

# renovate: datasource=github-tags depName=raviqqe/muffet
export MUFFET_VERSION="2.11.8"
# renovate: datasource=github-tags depName=caddyserver/caddy
export CADDY_VERSION="2.11.9"

# Command line parameters for muffet
export CMD_PARAMS="${INPUT_CMD_PARAMS:- --buffer-size=8192 --max-connections=10 --color=always --verbose}"
# Set path variable containing web pages
export PAGES_PATH=${INPUT_PAGES_PATH:-}
# URL to scan / check
export URL=${INPUT_URL:?}
# Domain where the web pages will be hosted (test.example.com), it will be stored in /etc/hosts
PAGES_DOMAIN=$(echo "${URL}" | awk -F[/:] '{print $4}')
export PAGES_DOMAIN
# URI used by caddy to serve locally stored web pages (https://test.example.com)
PAGES_URI=$(echo "${URL}" | cut -d / -f 1,2,3)
export PAGES_URI
# Debug variable - enable by setting non-empty value
export DEBUG=${INPUT_DEBUG:-}
# Create caddy log file where will be all the log messages form the caddy server
CADDY_LOG=$(mktemp /tmp/Caddy-log.XXXXXX)
# Create caddy configuration to run web server using the domain set in PAGES_DOMAIN + /etc/hosts
CADDYFILE=$(mktemp /tmp/Caddyfile.XXXXXX)

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

# Remove the /etc/hosts entry, CA trust and caddy added by this script
cleanup() {
  if [ -n "${PAGES_PATH}" ]; then
    $sudo_cmd sed -i "/127.0.0.1 ${PAGES_DOMAIN}  # Created by my-broken-link-checker/d" /etc/hosts || true
    # Untrust the CA only if this run installed it - by path, as caddy may have failed to start
    if grep -q "installing root certificate" "${CADDY_LOG}"; then
      $sudo_cmd caddy untrust --cert "$($sudo_cmd caddy environ | sed -n 's/^caddy.AppDataDir=//p')/pki/authorities/local/root.crt" &> /dev/null || true
    fi
    # Never touch a caddy that was already running on this machine
    if [ -n "${CADDY_STARTED:-}" ]; then
      $sudo_cmd caddy stop &> /dev/null
    fi
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
trap 'rm -f "${CADDYFILE}" "${CADDY_LOG}"' EXIT

[[ -n "${DEBUG}" && "${DEBUG}" != "false" ]] && set -x

# Script mode needs GNU sed and the Linux muffet/caddy builds
if [ "$(uname)" != "Linux" ]; then
  print_error "Only Linux is supported - use the container image on other systems"
  exit 1
fi

# Detect architecture
ARCH=$(uname -m)
if [ "${ARCH}" = "aarch64" ]; then
  ARCH_SUFFIX="arm64"
elif [ "${ARCH}" = "x86_64" ]; then
  ARCH_SUFFIX="amd64"
else
  print_error "Unsupported architecture: ${ARCH}"
  exit 1
fi

# Install muffet if needed
if ! hash muffet &> /dev/null; then
  MUFFET_URL="https://github.com/raviqqe/muffet/releases/download/v${MUFFET_VERSION}/muffet_linux_${ARCH_SUFFIX}.tar.gz"
  wget -qO- "${MUFFET_URL}" | $sudo_cmd tar xzf - -C /usr/local/bin/ muffet
fi

# Install caddy if needed
if ! hash caddy &> /dev/null && [ -n "${PAGES_PATH}" ]; then
  CADDY_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${ARCH_SUFFIX}.tar.gz"
  wget --quiet "${CADDY_URL}" -O - | $sudo_cmd tar xzf - -C /usr/local/bin/ caddy
fi

# Use muffet in case of external URL check is required
if [ -z "${PAGES_PATH}" ]; then
  # Run check
  print_info "[$(date +'%F %T')] Start checking: \"${URL}\""
  # eval only parses the quoted options in CMD_PARAMS, the URL is passed as data
  eval muffet "${CMD_PARAMS}" '"${URL}"'

else

  print_info "Using path \"${PAGES_PATH}\" as domain \"${PAGES_DOMAIN}\" with URI \"${PAGES_URI}\""

  # Die if the specified path which should contain local web pages doesn't exist
  if [ ! -d "${PAGES_PATH}" ]; then
    print_error "Path specified as 'INPUT_PAGES_PATH': '${PAGES_PATH}' doesn't exist!"
    exit 1
  fi

  # Add domain into /etc/hosts
  echo "127.0.0.1 ${PAGES_DOMAIN}  # Created by my-broken-link-checker" | $sudo_cmd tee -a /etc/hosts > /dev/null

  {
    echo "${PAGES_URI} {"
    echo "  root * ${PAGES_PATH}"
    echo "  file_server"
    if [[ "${PAGES_URI}" =~ ^https: ]]; then echo "  tls internal"; fi
    echo "}"
  } > "${CADDYFILE}"

  # Run caddy web server on the background
  $sudo_cmd caddy start --config "${CADDYFILE}" --adapter caddyfile &> "${CADDY_LOG}"
  CADDY_STARTED=1
  sleep 1

  # Run check
  print_info "[$(date +'%F %T')] Start checking: \"${URL}\""
  eval muffet "${CMD_PARAMS}" '"${URL}"'
  cleanup

fi

print_info "[$(date +'%F %T')] Checks completed..."
