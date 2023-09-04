# Скачиваем файл с сайта
Invoke-WebRequest -Uri "https://openssh.had.su/OpenSSH-Server-Package~31bf3856ad364e35~amd64~~.cab" -OutFile "C:\OpenSSH-Server-Package~31bf3856ad364e35~amd64~~.cab"

# Устанавливаем .cab пакет
Dism /Online /Add-Package /PackagePath:"C:\OpenSSH-Server-Package~31bf3856ad364e35~amd64~~.cab"

# Удаляем .cab файл после установки
Remove-Item "C:\OpenSSH-Server-Package~31bf3856ad364e35~amd64~~.cab" -Force

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

# =======================================================================

# Скачивание файла optimisation.ps1 (Измени на нужный путь)
$url = "https://win-opt.had.su/optimisation.ps1"
$outputPath = "C:\Windows\System32\OpenSSH\optimisation.ps1"

Invoke-WebRequest -Uri $url -OutFile $outputPath

# Добавление папки в PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = "C:\Windows\System32\OpenSSH"

# Проверка, содержится ли путь уже в PATH
if (-not $currentPath.Contains($newPath)) {
    [System.Environment]::SetEnvironmentVariable("Path", $currentPath + ";" + $newPath, "Machine")
}

# Создание алиаса для запуска optimisation.ps1
$scriptPath = "C:\Windows\System32\OpenSSH\optimisation.ps1"

# Проверка на существование файла, прежде чем создавать алиас
if (Test-Path $scriptPath) {
    Set-Alias -Name opti -Value $scriptPath

    # Проверка наличия файла профиля и его создание при необходимости
    if (-not (Test-Path $PROFILE)) {
        New-Item -Type File -Path $PROFILE -Force
    }

    # Добавление команды создания алиаса в профиль для постоянного использования
    Add-Content -Path $PROFILE -Value "`nSet-Alias -Name opti -Value '$scriptPath'"

} else {
    Write-Error "Файл $scriptPath не найден."
}



