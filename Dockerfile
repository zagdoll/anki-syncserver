FROM rust:1.85.0-alpine3.20 AS builder

ARG ANKI_VERSION

RUN apk update && apk add --no-cache build-base protobuf && rm -rf /var/cache/apk/*

RUN cargo install --git https://github.com/ankitects/anki.git \
--tag ${ANKI_VERSION} \
--root /anki-server  \
--locked \
anki-sync-server

FROM alpine:3.21.0

# Default PUID and PGID values (can be overridden at runtime). Use these to
# ensure the files on the volume have the permissions you need.
ENV PUID=1000
ENV PGID=1000

COPY --from=builder /anki-server/bin/anki-sync-server /usr/local/bin/anki-sync-server

RUN apk update && apk add --no-cache bash su-exec && rm -rf /var/cache/apk/*


EXPOSE 8080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["anki-sync-server"]

# This health check will work for Anki versions 24.08.x and newer.
# For older versions, it may incorrectly report an unhealthy status, which should not be the case.
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/health || exit 1

VOLUME /anki_data

LABEL maintainer="zabbits <docker@zabbits.com>"
