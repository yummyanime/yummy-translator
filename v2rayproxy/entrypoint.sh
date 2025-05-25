#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Function to URL decode a string
url_decode() {
  local url_encoded="${1//+/ }" # Replace + with space
  printf '%b' "${url_encoded//%/\\x}" # Decode %xx sequences
}
echo "VLESS URL: $VLESS_URL"

# Check if VLESS_URL is provided
if [ -z "$VLESS_URL" ]; then
  echo "Error: VLESS_URL environment variable is not set."
  echo "Usage: docker run -e VLESS_URL=\"your_vless_link\" ..."
  exit 1
fi

# Parse VLESS URL
# Expected format: vless://<UUID>@<ADDRESS>:<PORT>?type=<TYPE>&security=<SECURITY>&pbk=<PBK>&fp=<FP>&sni=<SNI>&sid=<SID>&spx=<SPX_ENCODED>#<NAME>

# Remove vless:// prefix and #fragment
temp_url="${VLESS_URL#vless://}"
temp_url="${temp_url%#*}"

# Extract UUID (part before @)
export VLESS_UUID=$(echo "$temp_url" | cut -d'@' -f1)
address_part_and_query=$(echo "$temp_url" | cut -d'@' -f2-) # Use - to get the rest of the string

# Extract address and port (part before ?)
address_and_port=$(echo "$address_part_and_query" | cut -d'?' -f1)
export VLESS_ADDRESS=$(echo "$address_and_port" | cut -d':' -f1)
# Extract port, ensuring it's numeric. Handle potential IPv6 brackets.
if [[ "$VLESS_ADDRESS" == \[* ]]; then # IPv6 address like [::1]
    export VLESS_PORT_NUM=$(echo "$address_and_port" | awk -F']:' '{print $2}' | grep -o '[0-9]*')
    export VLESS_ADDRESS=$(echo "$VLESS_ADDRESS" | tr -d '[]') # Remove brackets for Xray config
else # IPv4 or hostname
    export VLESS_PORT_NUM=$(echo "$address_and_port" | cut -d':' -f2 | grep -o '[0-9]*')
fi


# Extract query parameters (part after ?)
query_string=$(echo "$address_part_and_query" | cut -d'?' -f2-)

# Function to extract query parameter value using awk for robustness
get_query_param() {
    local param_name="$1"
    local query_str="$2"
    echo "$query_str" | tr '&' '\n' | awk -F= -v p="$param_name" 'tolower($1)==tolower(p) {print $2; exit}'
}

export VLESS_NETWORK=$(get_query_param "type" "$query_string")
export VLESS_SECURITY=$(get_query_param "security" "$query_string")
export VLESS_PUBLIC_KEY=$(get_query_param "pbk" "$query_string")
export VLESS_FINGERPRINT=$(get_query_param "fp" "$query_string")
export VLESS_SNI=$(get_query_param "sni" "$query_string")
export VLESS_SHORT_ID=$(get_query_param "sid" "$query_string")
spx_encoded=$(get_query_param "spx" "$query_string")
export VLESS_SPIDER_X=$(url_decode "$spx_encoded")

# Validate essential parsed parameters
if [ -z "$VLESS_UUID" ] || [ -z "$VLESS_ADDRESS" ] || [ -z "$VLESS_PORT_NUM" ] || \
   [ -z "$VLESS_NETWORK" ] || [ -z "$VLESS_SECURITY" ] || [ -z "$VLESS_SNI" ] || \
   [ -z "$VLESS_PUBLIC_KEY" ] || [ -z "$VLESS_FINGERPRINT" ]; then
    echo "Error: Could not parse essential parts of VLESS_URL."
    echo "Please ensure the VLESS_URL is correct and includes type, security, pbk, fp, sni."
    echo "Parsed values (some might be empty if parsing failed):"
    echo "  UUID: $VLESS_UUID"
    echo "  ADDRESS: $VLESS_ADDRESS"
    echo "  PORT: $VLESS_PORT_NUM"
    echo "  NETWORK: $VLESS_NETWORK"
    echo "  SECURITY: $VLESS_SECURITY"
    echo "  SNI: $VLESS_SNI"
    echo "  PUBLIC_KEY: $VLESS_PUBLIC_KEY"
    echo "  FINGERPRINT: $VLESS_FINGERPRINT"
    echo "  SHORT_ID: $VLESS_SHORT_ID"
    echo "  SPIDER_X: $VLESS_SPIDER_X"
    exit 1
fi

# Warnings for specific configuration assumptions
if [ "$VLESS_SECURITY" != "reality" ]; then
    echo "Warning: This configuration template is specifically designed for 'reality' security. Your URL uses '$VLESS_SECURITY'."
fi
if [ "$VLESS_NETWORK" != "tcp" ]; then
    echo "Warning: This configuration template is specifically designed for 'tcp' network. Your URL uses '$VLESS_NETWORK'."
fi

# Set SOCKS port and listen address from environment variables or use defaults
export SOCKS_PORT_NUM=${SOCKS_PORT:-1080}
export SOCKS_LISTEN_ADDR=${SOCKS_LISTEN_ADDRESS:-"0.0.0.0"}

echo "--- Xray Configuration ---"
echo "VLESS Server: ${VLESS_ADDRESS}:${VLESS_PORT_NUM}"
echo "UUID: ${VLESS_UUID}"
echo "Network: ${VLESS_NETWORK}, Security: ${VLESS_SECURITY}"
echo "SNI: ${VLESS_SNI}, Fingerprint: ${VLESS_FINGERPRINT}"
echo "Public Key: ${VLESS_PUBLIC_KEY}"
[ -n "$VLESS_SHORT_ID" ] && echo "Short ID: ${VLESS_SHORT_ID}"
[ -n "$VLESS_SPIDER_X" ] && echo "SpiderX Path: ${VLESS_SPIDER_X}"
echo "SOCKS Proxy listening on: ${SOCKS_LISTEN_ADDR}:${SOCKS_PORT_NUM}"
echo "--------------------------"

# Generate config.json from template using envsubst
# 'envsubst' is provided by the 'gettext' package (installed as .build-deps and then removed, runtime part from libintl)
# Alpine's envsubst is typically in the 'envsubst' package or part of 'gettext-utils' or 'gettext'
# Ensuring variables are exported is crucial for envsubst.
envsubst < /etc/xray/config.template.json > /etc/xray/config.json
echo "\n\nExray config:\n\n$(cat /etc/xray/config.json)\n\n"
# For debugging: Show the generated config
# echo "Generated /etc/xray/config.json:"
# cat /etc/xray/config.json
# echo "--------------------------"

# Execute Xray with the generated configuration
echo "Starting Xray-core..."
exec /usr/local/bin/xray run -config /etc/xray/config.json
