#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/.local/share/clustering-mysql"
for name in primary replica; do
    dir="$BASE/$name"
    if mysqladmin --defaults-extra-file="$BASE/client.cnf" --socket="$dir/mysql.sock" ping >/dev/null 2>&1; then
        echo "$name already running"
        continue
    fi
    nohup mysqld --defaults-file="$BASE/$name.cnf" --datadir="$dir/data" \
        --socket="$dir/mysql.sock" --pid-file="$dir/mysql.pid" --log-error="$dir/mysql.log" >/dev/null 2>&1 &
    ready=0
    for i in $(seq 1 60); do
        if mysqladmin --defaults-extra-file="$BASE/client.cnf" --socket="$dir/mysql.sock" ping >/dev/null 2>&1; then ready=1; break; fi
        sleep 1
    done
    [ "$ready" = 1 ] || { echo "Failed to start $name; see $dir/mysql.log" >&2; exit 1; }
    echo "$name started"
done
