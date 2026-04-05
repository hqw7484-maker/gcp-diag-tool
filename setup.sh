#!/bin/bash
# 自动清理环境，避免冲突
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf xray cf config.json index.html node.log cf.log

# 1. 环境对齐：下载兼容 XHTTP 26.x 的 Xray 核心 (这是解决报错的关键)
echo "Downloading core components..."
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

# 2. 从你的 GitHub 仓库远程拉取伪装文件和配置
# !!! 重要 !!! 请修改下方 "你的GitHub用户名" 为你的真实用户名 !!! 重要 !!!
GH_USER="你的GitHub用户名"
GH_REPO="gcp-diag-tool"

echo "Fetching remote configuration..."
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 3. 启动服务 (真正的“一把梭”)
echo "Starting diagnostic tool..."
# 在 8081 端口启动 Python 服务器，用于渲染诊断网页
nohup python3 -m http.server 8081 --bind 127.0.0.1 > /dev/null 2>&1 &
# 启动 Xray 接管 8080
nohup ./xray -c config.json > node.log 2>&1 &
# 启动隧道
nohup ./cf tunnel --url http://127.0.0.1:8080 > cf.log 2>&1 &

# 4. 等待穿透并吐出链接
echo -e "\nInitializing tunnel..."
sleep 10
echo -e "\n--- Diagnostic Tool is running at ---"
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
echo -e "------------------------------------"
