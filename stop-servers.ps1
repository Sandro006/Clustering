# Arrete les serveurs Spring Boot en tuant les processus qui ecoutent sur 8081/8082
$ErrorActionPreference = 'SilentlyContinue'

foreach ($port in 8081, 8082) {
    $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if (-not $connections) {
        Write-Output "Port $port : rien a arreter"
        continue
    }
    foreach ($conn in $connections) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Output "Arret de $($proc.ProcessName) (PID $($conn.OwningProcess)) sur le port $port"
            Stop-Process -Id $conn.OwningProcess -Force
        }
    }
}
