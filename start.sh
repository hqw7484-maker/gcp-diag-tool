#!/bin/bash
# ==========================================
# GCS 总调度脚本：一键清场 + 部署 + 监控
# ==========================================

# 1. 物理清场 (自毁逻辑)
echo -e "\033[33m[1/3]\033[0m 正在深度清理旧环境..."
pkill -9 xray; pkill -9 cf; pkill -9 python3; rm -rf ./* ./.* 2>/dev/null
sleep 2

# 2. 执行主部署脚本 (生成节点和链接)
echo -e "\033[33m[2/3]\033[0m 正在拉取配置并部署节点..."
GH_RAW="https://raw.githubusercontent.com/hqw7484-maker/gcp-diag-tool/main"
curl -sL "$GH_RAW/setup.sh" | bash

# 3. 衔接保活监控仪表盘
echo -e "\033[33m[3/3]\033[0m 部署完成，准备进入监控模式..."
sleep 2
curl -sL "$GH_RAW/monitor.sh" | bash
