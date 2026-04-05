#!/bin/bash
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf *; sleep 2

# 下载
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 启动网页服务器 (8085)
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &
# 启动 Xray (8080)
nohup ./xray -c config.json > node.log 2>&1 &

# 创建 Cloudflare 路由规则 (最直观的修复)
cat > tunnel.yml <<EOF
ingress:
  - hostname: "*"
    path: /api/v3/metrics
    service: http://127.0.0.1:8080
  - hostname: "*"
    service: http://127.0.0.1:8085
EOF

# 使用配置文件启动隧道
nohup ./cf tunnel --config tunnel.yml --url http://127.0.0.1:8085 > cf.log 2>&1 &

sleep 15
echo -e "\n--- 门面网页链接 ---"
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
