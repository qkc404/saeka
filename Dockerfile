FROM openresty/openresty:alpine

RUN apk add --no-cache ca-certificates wget unzip netcat-openbsd curl

# Fetch and configure Xray
RUN wget -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v26.5.9/Xray-linux-64.zip && \
    unzip -p /tmp/xray.zip xray > /usr/local/bin/xray && \
    chmod +x /usr/local/bin/xray && rm -rf /tmp/xray.zip

COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

HEALTHCHECK --interval=20s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
