ARG VERSION
ARG FLAVOR=bookworm

FROM openresty/openresty:${VERSION:+$VERSION-}${FLAVOR}

ENV TZ=Asia/Shanghai

COPY rootfs /

RUN set -eux; \
    chmod +x /usr/local/bin/entrypoint; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone; \
    \
    if [ -f "/root/.bashrc" ]; then \
        sed -i 's/^# \(export\|alias\)/\1/g' /root/.bashrc; \
    fi; \
    \
    if [ "alpine" = "$(. /etc/os-release && echo "$ID")" ]; then \
        ln -snf /usr/local/openresty/nginx/conf /etc/openresty; \
        apk add --no-cache bash; \
        { \
            echo "export LS_OPTIONS='--color=auto'"; \
            echo "alias ls='ls \$LS_OPTIONS'"; \
            echo "alias ll='ls \$LS_OPTIONS -l'"; \
            echo "alias l='ls \$LS_OPTIONS -l'"; \
        } | tee /root/.bashrc; \
    fi;

EXPOSE 80

WORKDIR /opt

ENTRYPOINT ["entrypoint"]