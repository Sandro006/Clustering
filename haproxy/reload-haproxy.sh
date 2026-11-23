#!/bin/bash
# Valide puis recharge HAProxy pour le test de clustering (a lancer depuis WSL).
# N'affiche RELOAD_OK que si la configuration est valide ET que HAProxy a redemarre.
# host.docker.internal est remplace par l'IP de l'hote Windows (route par defaut).
CFG=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.cfg
RUNTIME=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.runtime.cfg

HOST_IP=$(ip route show default | awk '/default/ {print $3}')
if [ -z "$HOST_IP" ]; then
  echo "ECHEC : impossible de determiner l'IP de l'hote Windows."
  exit 1
fi
sed "s/host\.docker\.internal/$HOST_IP/g" "$CFG" > "$RUNTIME"

echo "== Validation de la configuration =="
if ! haproxy -c -f "$RUNTIME"; then
  echo "ECHEC : configuration invalide."
  exit 1
fi

echo "== Redemarrage de HAProxy =="
pkill -f "haproxy -f $RUNTIME" 2>/dev/null
pkill -f "haproxy -f $CFG" 2>/dev/null
sleep 1
setsid haproxy -f "$RUNTIME" -D >/dev/null 2>&1
sleep 1

if pgrep -f "haproxy -f $RUNTIME" >/dev/null; then
  echo "RELOAD_OK (hote Windows : $HOST_IP)"
else
  echo "ECHEC : HAProxy n'a pas demarre."
  exit 1
fi
