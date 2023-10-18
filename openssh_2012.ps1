# Включаем TLS 1.2 для безопасных загрузок
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Добавляем в переменные OpenSSH
$url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win64.zip"
$outFile = "C:\Program Files\OpenSSH\OpenSSH-Win64.zip"

# Создаем директорию, если она не существует
if (-not (Test-Path "C:\Program Files\OpenSSH")) {
    New-Item -Path "C:\Program Files\OpenSSH" -ItemType Directory
}

# Скачиваем архив
Invoke-WebRequest -Uri $url -OutFile $outFile

# Распаковываем архив
function Unzip
{
    param (
        [string]$zipFile,
        [string]$destination
    )
    if (-not ([System.Management.Automation.PSTypeName]'System.IO.Compression.ZipFile').Type) {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)
}

# Использование функции:
Unzip -zipFile $outFile -destination "C:\Program Files\OpenSSH"

Move-Item "C:\Program Files\OpenSSH\OpenSSH-Win64\*" "C:\Program Files\OpenSSH\"
Remove-Item "C:\Program Files\OpenSSH\OpenSSH-Win64" -Force -Recurse

# Переходим в директорию для установки
cd "C:\Program Files\OpenSSH"

# Устанавливаем и настраиваем OpenSSH
.\install-sshd.ps1

# Создаем директорию для ключей, если она не существует
if (-not (Test-Path "C:\ProgramData\ssh")) {
    New-Item -Path "C:\ProgramData\ssh" -ItemType Directory
}

# Генерируем ключи
.\ssh-keygen.exe -A

# Настраиваем права доступа к файлам
Add-Type -AssemblyName System.Windows.Forms
$fixHostScript = ".\FixHostFilePermissions.ps1"

if (Test-Path $fixHostScript) {
    $process = Start-Process -FilePath "PowerShell" -ArgumentList "-ExecutionPolicy Bypass -File $fixHostScript" -PassThru
    Start-Sleep -Seconds 3  # Задержка, чтобы дать скрипту время на запуск

    1..6 | ForEach-Object {  # Повторяем отправку 6 раз
        [System.Windows.Forms.SendKeys]::SendWait("A{ENTER}")
        Start-Sleep -Seconds 2  # Задержка между отправками
    }

    $process.WaitForExit()
}

# Задаем нужный порт OpenSSH
$configFile = "C:\Program Files\OpenSSH\sshd_config_default"
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

