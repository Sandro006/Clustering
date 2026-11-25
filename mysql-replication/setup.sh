#!/usr/bin/env bash
# Creates two NEW local MySQL instances. Existing installations are not modified.
set -euo pipefail
umask 077
HERE=$(cd "$(dirname "$0")" && pwd)
BASE="$HOME/.local/share/clustering-mysql"
command -v mysqld >/dev/null || { echo 'MySQL server is not installed.' >&2; exit 1; }
command -v mysql >/dev/null || { echo 'MySQL client is not installed.' >&2; exit 1; }
if [ -e "$BASE" ]; then
    echo "Refusing to overwrite existing instance directory: $BASE" >&2
    exit 1
fi
mkdir -p "$BASE/primary" "$BASE/replica"
cp "$HERE/primary.cnf" "$HERE/replica.cnf" "$BASE/"
chmod 600 "$BASE/primary.cnf" "$BASE/replica.cnf"
PASSWORD=$(openssl rand -hex 24)
REPL_PASSWORD=$(openssl rand -hex 16)
printf '[client]\nuser=root\npassword=%s\n' "$PASSWORD" > "$BASE/client.cnf"
for name in primary replica; do
    dir="$BASE/$name"
    mysqld --no-defaults --initialize-insecure --datadir="$dir/data" --log-error="$dir/init.log"
    nohup mysqld --defaults-file="$BASE/$name.cnf" --datadir="$dir/data" \
        --socket="$dir/mysql.sock" --pid-file="$dir/mysql.pid" --log-error="$dir/mysql.log" \
        --read-only=OFF --super-read-only=OFF >/dev/null 2>&1 &
    for i in $(seq 1 60); do
        [ -S "$dir/mysql.sock" ] && mysqladmin --no-defaults --socket="$dir/mysql.sock" -u root ping >/dev/null 2>&1 && break
        sleep 1
    done
    mysql --no-defaults --socket="$dir/mysql.sock" -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSWORD'"
done
mysql --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/primary/mysql.sock" -e \
    "CREATE USER 'replicator'@'127.0.0.1' IDENTIFIED BY '$REPL_PASSWORD'; GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'127.0.0.1'; CREATE DATABASE clustering;"
mysql --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/replica/mysql.sock" -e \
    "CHANGE REPLICATION SOURCE TO SOURCE_HOST='127.0.0.1', SOURCE_PORT=3307, SOURCE_USER='replicator', SOURCE_PASSWORD='$REPL_PASSWORD', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1; START REPLICA; SET GLOBAL super_read_only=ON;"
echo "Instances created. Client credentials: $BASE/client.cnf"
echo "Check replication: mysql --defaults-extra-file=$BASE/client.cnf --socket=$BASE/replica/mysql.sock -e 'SHOW REPLICA STATUS\\G'"
