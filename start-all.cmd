@echo off
REM Demarre tout le test de clustering : serveurs Spring Boot puis HAProxy dans WSL
cd /d D:\alefas4\Clustering\Clustering

echo === Serveurs Spring Boot ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\alefas4\Clustering\Clustering\start-servers.ps1"

echo === HAProxy (WSL) ===
wsl -e bash /mnt/d/alefas4/Clustering/Clustering/haproxy/start-haproxy.sh

echo === Termine. http://localhost:8080 / stats : http://localhost:8404/stats ===
