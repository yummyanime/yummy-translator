# Yummy translator

This repo contains a microservice that translates text using genimi API from different languages.

Example of .env:

```environment
GEMINI_API_KEY=genimi-token
```

If you want to use the proxy, you can set the `PROXY_URL` environment variable:

```environment
ALL_PROXY=socks5://proxy:1087
```

To run a VLESS wrapped socks5 proxy, see [v2rayproxy](./v2rayproxy).
