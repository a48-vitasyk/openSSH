# Скачивания файла
$downloadScriptPath = "C:\path\to\download.ps1"
$scriptContent = @"
`$token = 'YOUR_GITHUB_TOKEN'
`$headers = @{
    'Authorization' = "token `$token"
}
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/a48-vitasyk/win-opt/main/win.ps1' -Headers `$headers -OutFile 'C:\path\to\save\file\win.ps1'
"@

# Сохраняем содержимое в файл
$scriptContent | Out-File $downloadScriptPath

# Создаем задание в планировщике заданий
$Action = New-ScheduledTaskAction -Execute 'powershell' -Argument "-NoProfile -ExecutionPolicy Bypass -File $downloadScriptPath"
$Trigger = New-ScheduledTaskTrigger -AtStartup -RepetitionInterval ([TimeSpan]::FromDays(1)) # Запуск при старте и каждый день

Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "DownloadWinOpt" -Description "Download win.ps1 from GitHub"


# нужно будет заменить YOUR_GITHUB_TOKEN на реальный токен доступа и C:\path\to\save\file\win.ps1 на путь, куда нужно сохранить файл.

