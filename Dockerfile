ARG VERSION
ARG FLAVOR=bookworm

FROM openresty/openresty:${VERSION:+$VERSION-}${FLAVOR}

ENV TZ=Asia/Shanghai

COPY rootfs /

RUN set -eux; \
    chmod +x /usr/local/bin/entrypoint; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone; \
    if [ -f "/root/.bashrc" ]; then \
        sed -i 's/^# \(export\|alias\)/\1/g' /root/.bashrc; \
    fi;

EXPOSE 80

WORKDIR /opt

ENTRYPOINT ["entrypoint"]