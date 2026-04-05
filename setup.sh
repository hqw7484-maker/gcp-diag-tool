#!/bin/bash
# 1. 彻底清场
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf ./* ./.* 2>/dev/null; sleep 2

# 2. 环境下载 (静默模式，减少干扰)
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip -o Xray-linux-64.zip xray && chmod +x xray
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf && chmod +x cf

# 3. 拉取配置
GH_RAW="https://raw.githubusercontent.com/hqw7484-maker/gcp-diag-tool/main"
curl -sL "$GH_RAW/index.html" -o index.html
curl -sL "$GH_RAW/config.json" -o config.json

# 4. 启动后端 (网页 8085 / Xray 8080)
nohup python3 -m http.server 8085 --bind 127.0.0.1 > /dev/null 2>&1 &
nohup ./xray -c config.json > node.log 2>&1 &

# 5. 写入分流配置
cat > tunnel.yml <<EOF
ingress:
  - hostname: "*"
    path: /api/v3/metrics
    service: http://127.0.0.1:8080
  - hostname: "*"
    service: http://127.0.0.1:8085
EOF

# 6. 启动隧道 (清理旧日志，确保抓取准确)
rm -f cf.log && touch cf.log
nohup ./cf tunnel --config tunnel.yml run > cf.log 2>&1 &

# 7. 【核心修正】动态轮询链接，最多等 60 秒
echo -n "正在向 Cloudflare 申请临时隧道链接..."
for i in {1..20}; do
    echo -n "."
    LINK=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' cf.log | head -n 1)
    if [ -n "$LINK" ]; then
        echo -e "\n\n\033[32m✅ 部署成功！\033[0m"
        echo -e "🔗 诊断页面: \033[36m$LINK\033[0m"
        echo -e "\033[33m提示: 链接已就绪，正在启动 9 小时保活程序...\033[0m\n"
        break
    fi
    sleep 3
    # 如果 20 次还没抓到，输出报错
    if [ $i -eq 20 ]; then
        echo -e "\n\033[31m❌ 链接获取失败！请检查 cf.log 内容：\033[0m"
        cat cf.log
        exit 1
    fi
done
