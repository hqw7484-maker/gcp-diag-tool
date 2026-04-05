#!/bin/bash
# 1. 强力清理旧环境
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf xray cf config.json index.html node.log cf.log
sleep 2

# 2. 下载核心组件 (适配 XHTTP 26.x)
echo "Downloading core components..."
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

# 3. 远程获取你的配置
# 这里的用户名已经帮你填好了
GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"

echo "Fetching remote configuration..."
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 4. 启动伪装与核心服务
echo "Starting diagnostic tool..."
# 在 8085 端口启动伪装网页服务器
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &

# 启动 Xray (监听 8080，回落至 8085)
nohup ./xray -c config.json > node.log 2>&1 &

# 启动 Cloudflare 隧道 (穿透 8080)
nohup ./cf tunnel --url http://127.0.0.1:8080 > cf.log 2>&1 &

# 5. 关键：等待隧道注册成功 (增加到 15 秒解决 1033 报错)
echo "Initializing secure tunnel, please wait..."
sleep 15

echo -e "\n--- Diagnostic Tool is running at ---"
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
echo -e "------------------------------------"
