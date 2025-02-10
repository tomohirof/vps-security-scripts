#!/bin/bash

# Script metadata
VERSION="1.0.0"
LAST_UPDATED="2024-02-10"
AUTHOR="Your Name"
DESCRIPTION="VPS Firewall and Security Setup Script for CapRover"

# バージョン情報の表示
echo "🔒 VPS Security Setup Script v${VERSION}"
echo "📅 Last Updated: ${LAST_UPDATED}"
echo "✍️  Author: ${AUTHOR}"
echo "📝 ${DESCRIPTION}"
echo "----------------------------------------"

# エラーハンドリングの追加
set -e
trap 'echo "エラーが発生しました。スクリプトを終了します。"; exit 1' ERR

# 現在のグローバルIPを取得（with fallback）
echo "🌐 グローバルIPを取得中..."
SSH_ALLOWED_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipecho.net/plain)
if [ -z "$SSH_ALLOWED_IP" ]; then
    echo "エラー: グローバルIPの取得に失敗しました"
    exit 1
fi

echo "🔒 VPSのセキュリティ設定を開始します..."

# 1. UFWのインストールと初期設定
echo "📌 UFWをインストールします..."
sudo apt update -y
sudo apt install ufw -y

echo "🛑 すべてのポートをデフォルトでブロックします..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 2. 必要なポートを開放
echo "🚪 必要なポートを開放します..."
# 基本ポート
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# CapRover必須ポート
sudo ufw allow 996/tcp   # CapRover Agent
sudo ufw allow 7946/tcp  # Docker Swarm TCP
sudo ufw allow 7946/udp  # Docker Swarm UDP
sudo ufw allow 4789/udp  # Docker Swarm Overlay Network
sudo ufw allow 2377/tcp  # Docker Swarm Cluster Management

# 3. SSHのセキュリティ強化
echo "🔑 SSHの設定を強化します..."
# SSHポートを変更（例：2222）
SSH_PORT=2222
sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 新しいSSHポートの許可（特定IPのみ）
echo "🔐 SSHアクセスを $SSH_ALLOWED_IP のみに制限します..."
sudo ufw allow from $SSH_ALLOWED_IP to any port $SSH_PORT proto tcp
sudo ufw deny $SSH_PORT/tcp  # その他のIPからのアクセスを拒否

# 4. レート制限の設定
echo "⚡ レート制限を設定します..."
sudo ufw limit $SSH_PORT/tcp

# 5. UFWを有効化
echo "✅ UFWファイアウォールを有効化します..."
sudo ufw enable

# 6. Fail2Banのインストールと設定
echo "🛡 Fail2Banをインストールして設定します..."
sudo apt install fail2ban -y

sudo bash -c "cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 300
bantime = 3600
ignoreip = $SSH_ALLOWED_IP

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
findtime = 300
bantime = 3600
EOF"

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

echo "📝 セキュリティ設定の概要:"
echo "• SSHポート: $SSH_PORT"
echo "• 許可されたIP: $SSH_ALLOWED_IP"
echo "• パスワード認証: 無効"
echo "• Fail2Ban: 有効（3回の失敗で1時間のバン）"

echo "🚨 重要な注意事項:"
echo "1. 新しいSSHポート($SSH_PORT)を使用してください"
echo "2. パスワード認証は無効化されています。SSH鍵を使用してください"
echo "3. 設定を確認するには:"
echo "   sudo ufw status numbered"
echo "   sudo fail2ban-client status"
echo "   sudo ss -tlnp"
