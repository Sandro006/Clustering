#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/.local/share/clustering-mysql"
mysql --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/primary/mysql.sock" -e \
  "CREATE TABLE IF NOT EXISTS clustering.replication_test (id INT PRIMARY KEY, message VARCHAR(100)); INSERT INTO clustering.replication_test VALUES (1, 'Replication OK') ON DUPLICATE KEY UPDATE message='Replication OK';"
for i in $(seq 1 30); do
    result=$(mysql --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/replica/mysql.sock" -N -e 'SELECT message FROM clustering.replication_test WHERE id=1' 2>/dev/null || true)
    [ "$result" = 'Replication OK' ] && break
    sleep 1
done
echo "Replica test row: ${result:-not found}"
mysql --defaults-extra-file="$BASE/client.cnf" --socket="$BASE/replica/mysql.sock" -e 'SHOW REPLICA STATUS\G' | grep -E 'Replica_IO_Running:|Replica_SQL_Running:|Last_IO_Error:|Last_SQL_Error:'
[ "$result" = 'Replication OK' ]
