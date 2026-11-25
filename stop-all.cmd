@echo off
REM Arrete tout le test de clustering : serveurs Spring Boot + HAProxy (WSL)
cd /d D:\Clone_github\Clustering

echo === Serveurs Spring Boot ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Clone_github\Clustering\stop-servers.ps1"

echo === HAProxy (WSL) ===
wsl -e bash /mnt/d/Clone_github/Clustering/haproxy/stop-haproxy.sh

echo === Termine. ===
