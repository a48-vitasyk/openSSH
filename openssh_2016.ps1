# включение tls1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# создание папки openssh и загрузка архива
$installDir = "C:\Program Files\OpenSSH"

if (-not (Test-Path $installDir)) {
    mkdir $installDir
}


cd $installDir


# Скачать на наш сервер
$downloadLink = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win64.zip"
Invoke-WebRequest -Uri $downloadLink -OutFile .\openssh.zip
Expand-Archive .\openssh.zip -DestinationPath $installDir

Move-Item "C:\Program Files\OpenSSH\OpenSSH-Win64\*" "C:\Program Files\OpenSSH\"
Remove-Item "C:\Program Files\OpenSSH\OpenSSH-Win64" -Force -Recurse
Remove-Item .\openssh.zip

# включения службы
setx PATH "$env:path;$installDir\" -m


# установка службы
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1

# Задаем нужный порт OpenSSH
$configFile = "$installDir\sshd_config_default"
$newPort = 22222

# Проверяем, содержит ли файл строку "Port"
if (Get-Content $configFile -Raw | Select-String -Pattern "^Port\s+\d+") {
    # Если да, то заменяем значение порта на новое
    (Get-Content $configFile) | ForEach-Object {
        $_ -replace '^Port\s+\d+', ("Port " + $newPort)
    } | Set-Content $configFile
} else {
    # Если нет, добавляем строку с портом после "#Port 22"
    $content = Get-Content $configFile
    $index = $content | Select-String -Pattern "#Port 22" -List | Select-Object LineNumber
    $newContent = $content[0..($index.LineNumber-1)] + ("Port " + $newPort) + $content[$index.LineNumber..$content.Length]
    $newContent | Set-Content $configFile
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
$outputPath = "C:\Program Files\OpenSSH\optimisation.ps1"

Invoke-WebRequest -Uri $url -OutFile $outputPath

# Добавление папки в PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = "C:\Program Files\OpenSSH"

# Проверка, содержится ли путь уже в PATH
if (-not $currentPath.Contains($newPath)) {
    [System.Environment]::SetEnvironmentVariable("Path", $currentPath + ";" + $newPath, "Machine")
}

# Создание алиаса для запуска optimisation.ps1
$scriptPath = "C:\Program Files\OpenSSH\optimisation.ps1"

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



