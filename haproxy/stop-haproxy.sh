#!/bin/bash
# Arrete l'instance HAProxy de ce projet (sans toucher au HAProxy systeme)
CFG=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.cfg
RUNTIME=/mnt/d/alefas4/Clustering/Clustering/haproxy/haproxy.runtime.cfg
if pkill -f "haproxy -f $RUNTIME" || pkill -f "haproxy -f $CFG"; then
  echo "HAProxy arrete"
else
  echo "HAProxy deja arrete"
fi
