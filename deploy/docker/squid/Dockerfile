FROM alpine:3.20

RUN apk add --no-cache squid bash

# Пользователь squid уже создан пакетом, просто убедимся, что директории существуют
RUN mkdir -p /var/cache/squid /var/log/squid && \
    chown -R squid:squid /var/cache/squid /var/log/squid

USER squid

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD squidclient -h localhost mgr:info > /dev/null 2>&1 || exit 1

CMD ["squid", "-N"]
