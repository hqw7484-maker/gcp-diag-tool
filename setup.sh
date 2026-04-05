#!/bin/bash
# 1. 物理清场
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf ./* ./.* 2>/dev/null; sleep 2

# 2. 下载核心组件
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

# 3. 拉取你的配置 (请根据实际修改仓库名)
GH_RAW="https://raw.githubusercontent.com/hqw7484-maker/gcp-diag-tool/main"
curl -sL "$GH_RAW/index.html" -o index.html
curl -sL "$GH_RAW/config.json" -o config.json

# 4. 启动网页服务器 (8085)
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &
# 5. 启动 Xray (8080)
nohup ./xray -c config.json > node.log 2>&1 &

# 6. 核心分流规则 (保证主页必亮)
cat > tunnel.yml <<EOF
ingress:
  - hostname: "*"
    path: /api/v3/metrics
    service: http://127.0.0.1:8080
  - hostname: "*"
    service: http://127.0.0.1:8085
EOF

# 7. 启动隧道并提取链接
nohup ./cf tunnel --config tunnel.yml run > cf.log 2>&1 &

sleep 15
echo -e "\n\033[32m=== [ 部署完成 ] ===\033[0m"
echo -n "诊断页面链接: "
grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log
echo -e "\033[33m提示：点击上方链接确认网页亮起，随后直接在软件中使用该域名。\033[0m\n"
