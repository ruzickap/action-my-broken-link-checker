# checkov:skip=CKV_DOCKER_3: Ensure that a user for the container has been created

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

LABEL maintainer="Petr Ruzicka <petr.ruzicka@gmail.com>"
LABEL repository="https://github.com/ruzickap/action-my-broken-link-checker"
LABEL homepage="https://github.com/ruzickap/action-my-broken-link-checker"

# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN set -eux && \
    test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf && \
    apk add --no-cache bash ca-certificates wget

# entrypoint.sh installs muffet (and caddy when needed) at run time, GitHub rebuilds this image on every run anyway
COPY entrypoint.sh /entrypoint.sh

HEALTHCHECK NONE

ENTRYPOINT [ "/entrypoint.sh" ]
