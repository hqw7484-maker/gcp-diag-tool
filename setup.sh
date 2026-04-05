#!/bin/bash
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf *; sleep 2

wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 启动门面网页服务器 (8085)
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &
# 启动核心逻辑 (8080)
nohup ./xray -c config.json > node.log 2>&1 &
# 启动隧道
nohup ./cf tunnel --url http://127.0.0.1:8080 > cf.log 2>&1 &

sleep 15
echo -e "\n--- 诊断工具链接 ---"
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
