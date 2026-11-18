#!/bin/bash
# Demarre HAProxy pour le test de clustering (a lancer depuis WSL)
CFG=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.cfg

echo "== Verification de la configuration =="
if ! haproxy -c -f "$CFG"; then
  echo "Configuration invalide, abandon."
  exit 1
fi

echo "== Arret d'une eventuelle instance precedente =="
pkill -f "haproxy -f $CFG" 2>/dev/null
sleep 1

echo "== Demarrage =="
setsid haproxy -f "$CFG" -D
sleep 2

echo "== Etat =="
if curl -s -m 3 -o /dev/null http://127.0.0.1:8080/; then
  echo "HAProxy OK -> http://localhost:8080  (stats : http://localhost:8404/stats)"
else
  echo "HAProxy tourne mais aucun backend n'est disponible."
  echo "Lance les serveurs Spring Boot : start-servers.ps1"
fi
