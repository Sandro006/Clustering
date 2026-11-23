#!/bin/bash
# Demarre HAProxy pour le test de clustering (a lancer depuis WSL).
# En mode NAT, host.docker.internal n'est pas resolu : on le remplace par l'IP de
# la passerelle Windows (route par defaut) dans une configuration "runtime".
CFG=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.cfg
RUNTIME=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.runtime.cfg

HOST_IP=$(ip route show default | awk '/default/ {print $3}')
if [ -z "$HOST_IP" ]; then
  echo "Impossible de determiner l'IP de l'hote Windows."
  exit 1
fi
sed "s/host\.docker\.internal/$HOST_IP/g" "$CFG" > "$RUNTIME"
echo "Hote Windows : $HOST_IP"

echo "== Verification de la configuration =="
if ! haproxy -c -f "$RUNTIME"; then
  echo "Configuration invalide, abandon."
  exit 1
fi

echo "== Arret d'une eventuelle instance precedente =="
pkill -f "haproxy -f $RUNTIME" 2>/dev/null
pkill -f "haproxy -f $CFG" 2>/dev/null
sleep 1

echo "== Demarrage =="
setsid haproxy -f "$RUNTIME" -D >/dev/null 2>&1
sleep 2

echo "== Etat =="
CODE=$(curl -s -m 3 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/)
if [ "$CODE" = "200" ]; then
  echo "HAProxy OK -> http://localhost:8080  (stats : http://localhost:8404/stats)"
else
  echo "HAProxy tourne mais aucun backend n'est disponible (code $CODE)."
  echo "Lance les serveurs Spring Boot : start-servers.ps1"
fi
