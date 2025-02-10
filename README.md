# Vultr セキュリティ用

## 実行方法
```# 1. スクリプトをダウンロードして保存
curl -sSL https://raw.githubusercontent.com/tomohirof/vps-security-scripts/refs/heads/main/setup_firewall.sh -o setup_firewall.sh

# 2. スクリプトの内容を確認
less setup_firewall.sh

# 3. 実行権限を付与
chmod +x setup_firewall.sh

# 4. 実行
./setup_firewall.sh

```

### 注意点
- SSHポートは2222に変更しています。
- パスワードのログインはできなくなります。
- IPアドレスは自動的に設定されます。(最適ではないので修正)