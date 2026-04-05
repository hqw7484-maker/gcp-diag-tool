#!/bin/bash
# 1. 彻底清理旧环境 (暴力清场)
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf *
sleep 2

# 2. 下载核心组件 (Xray 26.3.27 + Cloudflared)
echo "Downloading core components..."
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

# 3. 从 GitHub 获取你的配置 (请确保用户名正确)
GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"

echo "Fetching remote configuration from GitHub..."
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 4. 启动服务 (仅 Xray + Cloudflare Tunnel)
echo "Launching diagnostic system..."
# Xray 监听 8080，直接处理网页回落
nohup ./xray -c config.json > node.log 2>&1 &
# 隧道穿透 8080
nohup ./cf tunnel --url http://127.0.0.1:8080 > cf.log 2>&1 &

# 5. 等待并抓取链接
echo "Waiting for Cloudflare Tunnel to synchronize (15s)..."
sleep 15
echo -e "\n--- Diagnostic Tool is running at ---"
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
echo -e "------------------------------------"
echo "Tips: If you see 404, please check 'cat node.log' for path errors."
