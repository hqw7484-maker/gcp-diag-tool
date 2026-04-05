#!/bin/bash
# 1. 物理清场
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf *; sleep 2

# 2. 下载
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

# 3. 拉取配置 (请确保你的用户名正确)
GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 4. 启动伪装网页 (给 8081 喂饭)
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &

# 5. 启动 Xray (监听 8080 和 8081)
nohup ./xray -c config.json > node.log 2>&1 &

# 6. 启动隧道 (核心修改：转发给 8080，如果路径不匹配则回落)
# 我们让隧道直连 8080，利用 Xray 26.x 的内部路由
nohup ./cf tunnel --url http://127.0.0.1:8080 > cf.log 2>&1 &

echo "正在建立最后的防线 (15秒等待)..."
sleep 15
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
