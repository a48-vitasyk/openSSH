# Устанавливаем OpenSSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Задаем путь к файлу конфигурации и нужный порт OpenSSH
$configFile = "C:\Windows\System32\OpenSSH\sshd_config_default"
$newPort = 22222

# Предоставляем права на файл
takeown /F "$configFile"
icacls "$configFile" /grant "Administrators:F"

# Проверяем, содержит ли файл строку "Port"
if (Get-Content -LiteralPath $configFile -Raw | Select-String -Pattern "^Port\s+\d+") {
    # Если да, то заменяем значение порта на новое
    (Get-Content -LiteralPath $configFile) | ForEach-Object {
        $_ -replace '^Port\s+\d+', ("Port " + $newPort)
    } | Set-Content -LiteralPath $configFile
} else {
    # Если нет, добавляем строку с портом после "#Port 22"
    $content = Get-Content -LiteralPath $configFile
    $index = $content | Select-String -Pattern "#Port 22" -List | Select-Object LineNumber
    $newContent = $content[0..($index.LineNumber-1)] + ("Port " + $newPort) + $content[$index.LineNumber..$content.Length]
    $newContent | Set-Content -LiteralPath $configFile
}

# Открываем нужный порт
New-NetFirewallRule -Protocol TCP -LocalPort 22222 -Direction Inbound -Action Allow -DisplayName SSH

# Запускаем службу OpenSSH
Start-Service -Name sshd

# Дополнительно: Установить службу на автоматический запуск
Set-Service -Name sshd -StartupType Automatic

# Устанавливаем значение по умолчанию для оболочки SSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Приветствие
$profilePath = $PROFILE.AllUsersCurrentHost

$profileContent = @"
if (`$env:SSH_CLIENT) {
    Write-Host ""
    Write-Host "For Optimisation use:" -NoNewline
    Write-Host " opti" -ForegroundColor Green
    Write-Host ""
}
"@

# Если профиль не существует, создаём его
if (-not (Test-Path $profilePath)) {
    New-Item -Type File -Path $profilePath -Force | Out-Null
}

# Добавляем содержимое в профиль
Add-Content -Path $profilePath -Value $profileContent

# ==================================================

# Если файл профиля не существует, создаем его
if (-not (Test-Path $profilePath)) {
    New-Item -Type File -Path $profilePath -Force | Out-Null
}

# Добавляем функцию и алиас в профиль
$functionContent = @"
function Execute-OptimisationScript {
    # Установка протокола TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    # URL файла optimisation.ps1
    `$url = "https://raw.githubusercontent.com/a48-vitasyk/optimisation/main/optimisation.ps1"
    `$tempDirectory = "C:\Windows\System32\temp"
    `$scriptPath = Join-Path `$tempDirectory "optimisation.ps1"

    # Создание директории, если она не существует
    if (-not (Test-Path `$tempDirectory)) {
        New-Item -ItemType Directory -Path `$tempDirectory | Out-Null
    }

    # Удаление предыдущей версии файла, если он существует
    if (Test-Path `$scriptPath) {
        Remove-Item `$scriptPath
    }

    # Скачивание файла
    Invoke-WebRequest -Uri `$url -OutFile `$scriptPath

    # Выполнение скачанного скрипта
    . `$scriptPath
}
Set-Alias -Name opti -Value Execute-OptimisationScript
"@

# Добавляем содержимое в профиль
Add-Content -Path $profilePath -Value $functionContent

