#!/usr/bin/env bash
# Configures DNS + Email Routing for joaquimbravo.com on Cloudflare
# Run AFTER: (1) domain added as site in CF, (2) Hostinger nameservers updated to CF, (3) zone is "Active".

set -euo pipefail

# Load API token from main .env (up 2 dirs from this script)
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "${ROOT}/.env"

ZONE_NAME="joaquimbravo.com"
FORWARD_TO="ximyb5@hotmail.com"
GITHUB_USER="Xim1994"

echo "==> Looking up zone id for ${ZONE_NAME}"
ZONE_ID=$(curl -sS -k --ssl-no-revoke "https://api.cloudflare.com/client/v4/zones?name=${ZONE_NAME}" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" | python -c "import sys,json;d=json.load(sys.stdin);print(d['result'][0]['id'])")
echo "    zone_id=${ZONE_ID}"

# --- DNS records for GitHub Pages ---
# Apex A records (GitHub Pages)
for IP in 185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153; do
  echo "==> Adding A record @ -> ${IP}"
  curl -sS -k --ssl-no-revoke -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"@\",\"content\":\"${IP}\",\"ttl\":1,\"proxied\":true}" >/dev/null
done

echo "==> Adding CNAME www -> ${GITHUB_USER,,}.github.io"
curl -sS -k --ssl-no-revoke -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"CNAME\",\"name\":\"www\",\"content\":\"${GITHUB_USER,,}.github.io\",\"ttl\":1,\"proxied\":true}" >/dev/null

# --- Email Routing ---
echo "==> Enabling Email Routing"
curl -sS -k --ssl-no-revoke -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/email/routing/enable" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" >/dev/null || true

echo "==> Adding destination address ${FORWARD_TO}"
curl -sS -k --ssl-no-revoke -X POST "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/email/routing/addresses" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"email\":\"${FORWARD_TO}\"}" >/dev/null || true

echo "==> Creating rule hola@${ZONE_NAME} -> ${FORWARD_TO}"
curl -sS -k --ssl-no-revoke -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/email/routing/rules" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"actions\":[{\"type\":\"forward\",\"value\":[\"${FORWARD_TO}\"]}],\"matchers\":[{\"field\":\"to\",\"type\":\"literal\",\"value\":\"hola@${ZONE_NAME}\"}],\"enabled\":true,\"name\":\"hola@ -> personal\",\"priority\":0}" >/dev/null

echo "==> Creating catch-all rule -> ${FORWARD_TO}"
curl -sS -k --ssl-no-revoke -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/email/routing/rules/catch_all" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"actions\":[{\"type\":\"forward\",\"value\":[\"${FORWARD_TO}\"]}],\"matchers\":[{\"type\":\"all\"}],\"enabled\":true,\"name\":\"Catch-all -> personal\"}" >/dev/null || \
curl -sS -k --ssl-no-revoke -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/email/routing/rules/catch_all" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"actions\":[{\"type\":\"forward\",\"value\":[\"${FORWARD_TO}\"]}],\"matchers\":[{\"type\":\"all\"}],\"enabled\":true,\"name\":\"Catch-all -> personal\"}" >/dev/null

echo ""
echo "==> Cloudflare configured."
echo "    - Apex + www -> GitHub Pages (proxied)"
echo "    - hola@${ZONE_NAME}  forwards to ${FORWARD_TO}"
echo "    - catch-all forwards to ${FORWARD_TO}"
echo "    NOTE: you must verify ${FORWARD_TO} from its inbox (Cloudflare sends a verification email)."
