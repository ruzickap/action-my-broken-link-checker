FROM alpine:3.16

LABEL maintainer="Petr Ruzicka <petr.ruzicka@gmail.com>"
LABEL repository="https://github.com/ruzickap/action-my-broken-link-checker"
LABEL homepage="https://github.com/ruzickap/action-my-broken-link-checker"

LABEL "com.github.actions.name"="My Broken Link Checker"
LABEL "com.github.actions.description"="Check broken links on web pages stored locally or remotely"
LABEL "com.github.actions.icon"="list"
LABEL "com.github.actions.color"="blue"

# renovate: datasource=github-tags depName=raviqqe/muffet
ENV MUFFET_VERSION="2.5.0"
# renovate: datasource=github-tags depName=caddyserver/caddy
ENV CADDY_VERSION="2.5.1"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN set -eux && \
    [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf && \
    apk add --no-cache bash ca-certificates wget && \
    if [ "${MUFFET_VERSION}" = "latest" ]; then \
      MUFFET_URL=$(wget -qO- https://api.github.com/repos/raviqqe/muffet/releases/latest | grep "browser_download_url.*muffet_.*_Linux_x86_64.tar.gz" | cut -d \" -f 4) ; \
    else \
      MUFFET_URL="https://github.com/raviqqe/muffet/releases/download/v${MUFFET_VERSION}/muffet_${MUFFET_VERSION}_Linux_x86_64.tar.gz" ; \
    fi && \
    wget -qO- "${MUFFET_URL}" | tar xzf - -C /usr/local/bin/ muffet && \
    if [ "${CADDY_VERSION}" = "latest" ]; then \
      CADDY_URL=$(wget --quiet https://api.github.com/repos/caddyserver/caddy/releases/latest -O - | grep "browser_download_url.*caddy_.*_linux_amd64.tar.gz" | cut -d \" -f 4) ; \
    else \
      CADDY_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" ; \
    fi && \
    wget --quiet "${CADDY_URL}" -O - | tar xzf - -C /usr/local/bin/ caddy

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
