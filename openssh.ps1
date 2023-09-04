## Set network connection protocol to TLS 1.2
## Define the OpenSSH latest release url
 $url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/tag/v9.2.2.0p1-Beta'
 $url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'


## Create a web request to retrieve the latest release download link
 $request = [System.Net.WebRequest]::Create($url)
 $request.AllowAutoRedirect=$false
 $response=$request.GetResponse()
 $source = $([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win64.zip'

## Download the latest OpenSSH for Windows package to the current working directory
 $webClient = [System.Net.WebClient]::new()
 $webClient.DownloadFile($source, (Get-Location).Path + '\OpenSSH-Win64.zip')

# Extract the ZIP to a temporary location
 Expand-Archive -Path .\OpenSSH-Win64.zip -DestinationPath ($env:temp) -Force
# Move the extracted ZIP contents from the temporary location to C:\Program Files\OpenSSH\
 Move-Item "$($env:temp)\OpenSSH-Win64" -Destination "C:\Program Files\OpenSSH\" -Force
# Unblock the files in C:\Program Files\OpenSSH\
 Get-ChildItem -Path "C:\Program Files\OpenSSH\" | Unblock-File

 & 'C:\Program Files\OpenSSH\install-sshd.ps1'


## Adding a Windows Firewall Rule to Allow SSH Traffic

New-NetFirewallRule -Name sshd -DisplayName 'Allow SSH' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

## changes the sshd service's startup type from manual to automatic.
 Set-Service sshd -StartupType Automatic
## starts the sshd service.
 Start-Service sshd

& 'C:\Program Files\OpenSSH\sshd.exe' -d


===========================================


# Создаем файл приветствия MOTD
$motdPath = "C:\Program Files\OpenSSH\motd.txt"
$motdMessage = @"
Что бы запустить скрипт оптимизации воспользуйтесь командой:
optimisation
"@
Set-Content -Path $motdPath -Value $motdMessage

# Добавляем путь к файлу приветствия в sshd_config_default
$configFile = "C:\Program Files\OpenSSH\sshd_config_default"
Add-Content -Path $configFile -Value "`nBanner $motdPath"

#########################################################



# Добавление папки в PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = "C:\Program Files\OpenSSH"

# Проверка, содержится ли путь уже в PATH
if (-not $currentPath.Contains($newPath)) {
    [System.Environment]::SetEnvironmentVariable("Path", $currentPath + ";" + $newPath, "Machine")
}

# Загрузка optimisation.ps1 с приватного репозитория на GitHub
$token = ""  # Замените на ваш персональный токен доступа
$headers = @{
    "Authorization" = "token $token"
}

# Убедитесь, что у вас правильный URL для raw файла optimisation.ps1
$downloadUrl = "https://raw.githubusercontent.com/a48-vitasyk/win-opt/main/win.ps1"
Invoke-RestMethod -Uri $downloadUrl -Headers $headers -OutFile $scriptPath

# Создание алиаса для запуска optimisation.ps1
if (Test-Path $scriptPath) {
    Set-Alias -Name optimisation -Value $scriptPath

    # Проверка наличия файла профиля и его создание при необходимости
    if (-not (Test-Path $PROFILE)) {
        New-Item -Type File -Path $PROFILE -Force
    }

    # Добавление команды создания алиаса в профиль для постоянного использования
    Add-Content -Path $PROFILE -Value "`nSet-Alias -Name optimisation -Value '$scriptPath'"

} else {
    Write-Error "Файл $scriptPath не найден."
}






