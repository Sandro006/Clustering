@echo off
REM Arrete tout le test de clustering : serveurs Spring Boot + HAProxy (WSL)
cd /d D:\alefas4\Clustering\Clustering

echo === Serveurs Spring Boot ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\alefas4\Clustering\Clustering\stop-servers.ps1"

echo === HAProxy (WSL) ===
wsl -e bash /mnt/d/alefas4/Clustering/Clustering/haproxy/stop-haproxy.sh

echo === Termine. ===
