#!/bin/bash
# ==========================================
# GCS Deployment Script (Google Cloud Shell)
# ==========================================
set -e

# 1. Targeted cleanup (only removes known project files, NOT everything)
echo "[Cleanup] Removing old deployment files..."
rm -f xray cf config.json index.html tunnel.yml Xray-linux-64.zip

# 2. Generate UUID if not already set
if [ -z "$NODE_UUID" ]; then
    NODE_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
    echo "[UUID] Generated: $NODE_UUID"
fi

# 3. Download components
echo "[1/4] Downloading components..."
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray && rm -f Xray-linux-64.zip
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# Inject UUID
sed -i "s/__YOUR_UUID__/$NODE_UUID/g" config.json

# 4. Start backend services (web on 8085 / Xray on 8080)
echo "[2/4] Starting backend processes..."
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &
nohup ./xray -c config.json > node.log 2>&1 &

# 5. Cloudflare tunnel
cat > tunnel.yml <<EOF
ingress:
  - hostname: "*"
    path: /api/v3/metrics
    service: http://127.0.0.1:8080
  - hostname: "*"
    service: http://127.0.0.1:8085
EOF

echo "[3/4] Starting Cloudflare tunnel..."
rm -f cf.log && touch cf.log
nohup ./cf tunnel --config tunnel.yml run > cf.log 2>&1 &

# 6. Wait for tunnel URL
echo "[4/4] Waiting for tunnel URL..."
for i in {1..10}; do
    LINK=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' cf.log | head -n 1)
    if [ -n "$LINK" ]; then
        clear
        echo -e "\n\033[32m=== [ Deployment Complete ] ===\033[0m"
        echo -e "🔗 \033[1mDashboard:\033[0m \033[36m$LINK\033[0m"
        echo -e "\033[33mThe diagnostic panel is now live. Ready for keepalive...\033[0m\n"
        break
    fi
    sleep 3
done
