#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/.local/share/clustering-mysql"
for name in replica primary; do
    mysqladmin --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/$name/mysql.sock" shutdown
    echo "$name stopped"
done
