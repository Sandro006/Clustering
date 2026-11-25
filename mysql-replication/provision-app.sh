#!/usr/bin/env bash
set -euo pipefail
umask 077
BASE="$HOME/.local/share/clustering-mysql"
PASSWORD_FILE="$BASE/app-password"
if [ ! -f "$PASSWORD_FILE" ]; then
    openssl rand -hex 24 > "$PASSWORD_FILE"
fi
password=$(cat "$PASSWORD_FILE")
mysql --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/primary/mysql.sock" <<SQL
CREATE TABLE IF NOT EXISTS clustering.messages (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  content VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE USER IF NOT EXISTS 'clustering_app'@'%' IDENTIFIED BY '$password';
ALTER USER 'clustering_app'@'%' IDENTIFIED BY '$password';
GRANT SELECT, INSERT ON clustering.messages TO 'clustering_app'@'%';
SQL
