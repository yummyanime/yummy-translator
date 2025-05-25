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

## Running

### Nix

You can use nix+direnv:

```bash
direnv allow
env $(cat .env | xargs) python ./main.py
```

### Docker

To run the service, you can use Docker:

```bash
docker build -t yummy-translator . && docker run -p 8080:8000 -e GEMINI_API_KEY="YOUR_KEY" -e ALL_PROXY="socks5://proxy-if-defined-or.remove:13939" yummy-translator
```

## Translating

Now you can access the service at `http://localhost:8080/translate`:

```bash
curl -X POST http://localhost:8080/translate -H "Content-Type: application/json" -d '{"text": "Hello, world!", "lang_from": "en", "lang_to": "es"}'
```

## K8S

You can see k8s config [here](./k8s.yaml).
