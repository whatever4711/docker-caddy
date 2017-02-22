FROM armhf/alpine:3.5
ENV ARCH armhf

COPY caddy /usr/sbin/caddy
RUN apk upgrade --no-cache --available && \
    apk add --no-cache \
      ca-certificates \
      tini \
      git \
      libressl \
      libcap \
    && adduser -Du 1000 caddy \
    && mkdir -p /home/caddy/logs /home/caddy/cache \
    && chown -R caddy:caddy /home/caddy \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/caddy

VOLUME ["/home/caddy", "/home/caddy/logs", "/home/caddy/cache"]

# Run as an unprivileged user.
USER caddy
ENTRYPOINT ["/sbin/tini", "--", "/usr/sbin/caddy"]
