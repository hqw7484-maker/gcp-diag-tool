#!/bin/bash
# ==========================================
# GCS 部署脚本 (带网页分流)
# ==========================================

# 1. 物理清场
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf *; sleep 2

# 2. 静默下载
echo "[1/3] 正在拉取组件..."
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

GH_USER="hqw7484-maker"
GH_REPO="gcp-diag-tool"
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/index.html" -o index.html
curl -sL "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/config.json" -o config.json

# 3. 启动后台服务 (网页 8085 / Xray 8080)
echo "[2/3] 正在启动后端进程..."
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &
nohup ./xray -c config.json > node.log 2>&1 &

# 4. 创建 Cloudflare 精准路由配置文件
cat > tunnel.yml <<EOF
ingress:
  - hostname: "*"
    path: /api/v3/metrics
    service: http://127.0.0.1:8080
  - hostname: "*"
    service: http://127.0.0.1:8085
EOF

# 5. 【核心修复】使用配置文件启动隧道 (不要加 --url)
echo "[3/3] 正在请求临时隧道链接..."
rm -f cf.log && touch cf.log
nohup ./cf tunnel --config tunnel.yml run > cf.log 2>&1 &

# 6. 等待链接喷出并打印
for i in {1..10}; do
    LINK=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log | head -n 1)
    if [ -n "$LINK" ]; then
        clear
        echo -e "\n\033[32m=== [ 部署完成 ] ===\033[0m"
        echo -e "🔗 \033[1m门面网页链接:\033[0m \033[36m$LINK\033[0m"
        echo -e "\033[33m提示: 链接已就绪，网页亮起诊断面板。准备启动 9 小时保活程序...\033[0m\n"
        break
    fi
    sleep 3
done
