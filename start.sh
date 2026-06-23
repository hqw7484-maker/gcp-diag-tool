#!/bin/bash
# ==========================================
# GCS Scheduler: one-shot deploy + monitor
# ==========================================

echo -e "\033[33m[1/3]\033[0m Cleaning old environment (targeted)..."
rm -f xray cf config.json index.html tunnel.yml cf.log node.log web.log Xray-linux-64.zip

echo -e "\033[33m[2/3]\033[0m Deploying node..."
GH_RAW="https://raw.githubusercontent.com/hqw7484-maker/gcp-diag-tool/main"
curl -sL "$GH_RAW/setup.sh" | bash

echo -e "\033[33m[3/3]\033[0m Deployment complete. Entering monitor mode..."
sleep 2
curl -sL "$GH_RAW/monitor.sh" | bash
