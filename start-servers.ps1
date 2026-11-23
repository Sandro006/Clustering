# Demarre les deux serveurs Spring Boot s'ils ne tournent pas deja
$ErrorActionPreference = 'SilentlyContinue'

# Spring Boot 4 exige Java 17+. Le JAVA_HOME systeme peut pointer sur un JDK plus ancien :
# on cherche donc un JDK suitable et on l'impose aux processes Maven.
function Get-JdkMajor {
    param([string]$JavaExe)
    if (-not (Test-Path $JavaExe)) { return 0 }
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = (& $JavaExe -version 2>&1 | Out-String)
        if ($out -match 'version\s+"([^"]+)"') {
            $v = $Matches[1]
            if ($v -like '1.*') { return [int]($v.Split('.')[1]) }
            return [int]($v.Split('.')[0])
        }
        return 0
    } catch { return 0 } finally { $ErrorActionPreference = $old }
}

function Find-SuitableJdk {
    $roots = @(
        (Join-Path $env:ProgramFiles 'Java'),
        (Join-Path ${env:ProgramFiles(x86)} 'Java'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Eclipse Adoptium'),
        (Join-Path $env:USERPROFILE '.jdks')
    )
    $found = @()
    if ($env:JAVA_HOME) {
        $exe = Join-Path $env:JAVA_HOME 'bin\java.exe'
        $major = Get-JdkMajor $exe
        if ($major -ge 17) { $found += [pscustomobject]@{ Path = $env:JAVA_HOME; Major = $major } }
    }
    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path $root)) { continue }
        Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like 'jdk*' } |
            ForEach-Object {
                $exe = Join-Path $_.FullName 'bin\java.exe'
                $major = Get-JdkMajor $exe
                if ($major -ge 17) { $found += [pscustomobject]@{ Path = $_.FullName; Major = $major } }
            }
    }
    if ($found.Count -eq 0) { return $null }
    # On prefer Java 21 (LTS, version declaree dans le pom), puis 17, puis le plus recent.
    $chosen = $found | Where-Object { $_.Major -eq 21 } | Select-Object -First 1
    if (-not $chosen) { $chosen = $found | Where-Object { $_.Major -eq 17 } | Select-Object -First 1 }
    if (-not $chosen) { $chosen = $found | Sort-Object Major -Descending | Select-Object -First 1 }
    return $chosen.Path
}

$jdk = Find-SuitableJdk
if ($jdk) {
    $env:JAVA_HOME = $jdk
    $env:PATH = "$jdk\bin;$env:PATH"
    Write-Output "JAVA_HOME selectionne : $jdk (Java $(Get-JdkMajor (Join-Path $jdk 'bin\java.exe')))"
} else {
    Write-Output "ATTENTION : aucun JDK >= 17 trouve, Spring Boot 4 ne demarrera pas."
}

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
