# Demarre les deux serveurs Spring Boot s'ils ne tournent pas deja
$ErrorActionPreference = 'SilentlyContinue'

$logDir = Join-Path $env:TEMP 'opencode'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$servers = @(
    @{ Name = 'server1'; Dir = 'D:\alefas4\Clustering\Clustering\server1'; Port = 8081 },
    @{ Name = 'server2'; Dir = 'D:\alefas4\Clustering\Clustering\server2'; Port = 8082 }
)

foreach ($s in $servers) {
    $listen = Get-NetTCPConnection -LocalPort $s.Port -State Listen -ErrorAction SilentlyContinue
    if ($listen) {
        Write-Output "$($s.Name) : deja actif sur le port $($s.Port)"
        continue
    }

    $log = Join-Path $logDir "$($s.Name).log"
    Start-Process -FilePath (Join-Path $s.Dir 'mvnw.cmd') `
                  -ArgumentList 'spring-boot:run' `
                  -WorkingDirectory $s.Dir `
                  -WindowStyle Hidden `
                  -RedirectStandardOutput $log `
                  -RedirectStandardError "$log.err" | Out-Null
    Write-Output "$($s.Name) : lancement en cours (port $($s.Port))"
}

# Attente que les deux ports soient ouverts (max 90 secondes)
foreach ($s in $servers) {
    for ($i = 0; $i -lt 90; $i++) {
        $listen = Get-NetTCPConnection -LocalPort $s.Port -State Listen -ErrorAction SilentlyContinue
        if ($listen) { break }
        Start-Sleep -Seconds 1
    }
    $listen = Get-NetTCPConnection -LocalPort $s.Port -State Listen -ErrorAction SilentlyContinue
    if ($listen) {
        Write-Output "$($s.Name) : pret sur $($s.Port)"
    } else {
        Write-Output "$($s.Name) : PAS PRET sur $($s.Port) (voir $logDir\$($s.Name).log.err)"
    }
}
