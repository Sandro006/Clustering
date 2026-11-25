@echo off
REM Demarre tout le test de clustering : serveurs Spring Boot puis HAProxy dans WSL
cd /d D:\Clone_github\Clustering

echo === MySQL ===
wsl -e bash /mnt/d/Clone_github/Clustering/mysql-replication/start.sh
if errorlevel 1 echo Attention : MySQL n'a pas demarre. Les messages seront indisponibles.

echo === Serveurs Spring Boot ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Clone_github\Clustering\start-servers.ps1"

echo === HAProxy (WSL) ===
wsl -e bash /mnt/d/Clone_github/Clustering/haproxy/start-haproxy.sh

echo === Termine. http://localhost:8083 / stats : http://localhost:8404/stats ===
