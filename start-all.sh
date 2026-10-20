#!/bin/bash
# ====================================
# aps2api + new-api 一键启动脚本
# 手机 Termux / Linux / macOS 通用
# ====================================
set -e
cd "$(dirname "$0")"

echo "======================================"
echo "  aps2api + new-api 启动中..."
echo "======================================"

# ---------- 初始化 aps2api 配置 ----------
mkdir -p config logs
if [ ! -f config/config.json ] && [ -f config/config.example.json ]; then
  cp config/config.example.json config/config.json
  echo "[aps2api] 已生成 config/config.json"
fi
if [ ! -f config/api_keys.txt ]; then
  [ -f config/api_keys.example.txt ] && cp config/api_keys.example.txt config/api_keys.txt
  echo "[aps2api] 已生成 config/api_keys.txt"
fi

# Termux SSL 证书修复
if [ -d "/data/data/com.termux" ]; then
  export SSL_CERT_FILE="${PREFIX}/etc/tls/cert.pem"
  [ ! -f "$SSL_CERT_FILE" ] && export SSL_CERT_FILE="${PREFIX}/etc/ssl/certs/ca-certificates.crt"
fi

# ---------- 初始化 new-api 配置 ----------
mkdir -p new-api-data
export TZ=Asia/Shanghai
export SESSION_SECRET="$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 32)"
export SQLITE_PATH="./new-api-data/one-api.db"
export ERROR_LOG_ENABLED=true

# ---------- 清理旧进程 ----------
pkill -f "./aps2api" 2>/dev/null || true
pkill -f "./new-api" 2>/dev/null || true
sleep 1

# ---------- 启动 aps2api ----------
echo ""
echo "[aps2api] 正在启动 (端口 2156)..."
VPROXY_CONFIG=./config/config.json \
VPROXY_API_KEYS=./config/api_keys.txt \
VPROXY_MODELS=./config/models.json \
nohup ./aps2api > logs/aps2api.log 2>&1 &
echo "         PID: $!"
echo "         日志: logs/aps2api.log"

# ---------- 启动 new-api ----------
echo ""
echo "[new-api] 正在启动 (端口 3000)..."
nohup ./new-api --port 3000 --log-dir ./new-api-data/logs > new-api-data/new-api.log 2>&1 &
echo "         PID: $!"
echo "         日志: new-api-data/new-api.log"

# ---------- 等待启动 ----------
sleep 2

echo ""
echo "======================================"
echo "  启动完成！"
echo "======================================"
echo ""
echo "  aps2api 管理面板:  http://127.0.0.1:2156/admin/"
echo "  new-api 管理面板:  http://127.0.0.1:3000/"
echo ""
echo "  aps2api 管理员密码在日志中："
echo "    grep password logs/aps2api.log"
echo ""
echo "  首次使用 new-api 会提示创建管理员账号"
echo ""
echo "  查看日志:"
echo "    tail -f logs/aps2api.log"
echo "    tail -f new-api-data/new-api.log"
echo "======================================"