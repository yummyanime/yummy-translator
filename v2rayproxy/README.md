# Vless VPN to socks proxy docker image

This is a docker image that runs a Vless VPN server and exposes it as a socks proxy. It is based on the [V2Ray](https://www.v2ray.com/) project.

# Usage

## Build the image

```bash
docker build -t vless-vpn-socks .
```

## Run the container

```bash
docker run -p 1087:1080 -e VLESS_URL="vless://blablabla" vless-vpn-socks
```
