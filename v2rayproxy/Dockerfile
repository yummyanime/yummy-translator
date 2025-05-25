# Dockerfile
FROM alpine:latest

ARG XRAY_VERSION="v1.8.10" # You can change this to the desired Xray version
ARG TARGETARCH="64"      # Use "64" for amd64, "arm64-v8a" for arm64

# Install dependencies
RUN apk add --no-cache bash coreutils curl unzip libintl gettext \
    # Download and install Xray
    && echo "Downloading Xray-core ${XRAY_VERSION} for linux-${TARGETARCH}..." \
    && wget -O /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${TARGETARCH}.zip" \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/xray \
    && rm -f /tmp/xray.zip /usr/local/bin/geoip.dat /usr/local/bin/geosite.dat \
    # Create Xray config directory
    && mkdir -p /etc/xray

COPY config.template.json /etc/xray/config.template.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables for configuration
ENV VLESS_URL=""
ENV SOCKS_PORT="1080"
ENV SOCKS_LISTEN_ADDRESS="0.0.0.0"
# Listen on all interfaces

# Expose the default SOCKS port (metadata for Docker)
EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]
# The CMD is effectively run by the entrypoint script after config generation
# CMD ["/usr/local/bin/xray", "run", "-config", "/etc/xray/config.json"]
