FROM alpine:3.11

LABEL maintainer="Petr Ruzicka <petr.ruzicka@gmail.com>"
LABEL repository="https://github.com/ruzickap/action-my-broken-link-checker"
LABEL homepage="https://github.com/ruzickap/action-my-broken-link-checker"

LABEL "com.github.actions.name"="My Broken Link Checker"
LABEL "com.github.actions.description"="Check broken links on web pages stored locally or remotely"
LABEL "com.github.actions.icon"="list"
LABEL "com.github.actions.color"="blue"

ENV MUFFET_VERSION="1.3.2"
#ENV MUFFET_VERSION="latest"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

RUN set -eux && \
    apk add --no-cache bash ca-certificates sudo wget && \
    if [ "${MUFFET_VERSION}" = "latest" ]; then \
      MUFFET_URL=$(wget -qO- https://api.github.com/repos/raviqqe/muffet/releases/latest | grep "browser_download_url.*muffet_.*_Linux_x86_64.tar.gz" | cut -d \" -f 4) ; \
    else \
      MUFFET_URL="https://github.com/raviqqe/muffet/releases/download/${MUFFET_VERSION}/muffet_${MUFFET_VERSION}_Linux_x86_64.tar.gz" ; \
    fi && \
    wget -qO- "${MUFFET_URL}" | tar xzf - -C /usr/local/bin/ muffet && \
    wget -qO- https://getcaddy.com | bash -s personal

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
