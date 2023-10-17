# Скачивания файла
$downloadScriptPath = "C:\Windows\System32\OpenSSH\optimisation.ps1"
$scriptContent = @"
`$token = 'YOUR_GITHUB_TOKEN'
`$headers = @{
    'Authorization' = "token `$token"
}
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/a48-vitasyk/win-opt/main/win.ps1' -Headers `$headers -OutFile 'C:\Windows\System32\OpenSSH\optimisation.ps1'
"@

# Сохраняем содержимое в файл
$scriptContent | Out-File $downloadScriptPath

# Создаем действие для планировщика заданий
$Action = New-ScheduledTaskAction -Execute 'powershell' -Argument "-NoProfile -ExecutionPolicy Bypass -File $downloadScriptPath"

# Триггер для запуска каждый час
$TriggerHourly = New-ScheduledTaskTrigger -At (Get-Date) -RepetitionInterval ([TimeSpan]::FromHours(1)) -RepetitionDuration ([TimeSpan]::FromDays(365))

# Регистрируем задание с триггером
Register-ScheduledTask -Action $Action -Trigger $TriggerHourly -TaskName "DownloadWinOpt" -Description "Download win.ps1 from GitHub every hour"



# нужно будет заменить YOUR_GITHUB_TOKEN на реальный токен доступа и C:\path\to\save\file\win.ps1 на путь, куда нужно сохранить файл.

