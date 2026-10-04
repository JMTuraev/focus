# Builds a release of Focus, installs it for the current Windows user and
# puts a "Focus" shortcut on the desktop.
#
#   powershell -ExecutionPolicy Bypass -File tool\install_local.ps1
#
# The Telegram keys come from secrets.json at build time and are never printed.
# App data (%APPDATA%\com.example\fokus) is not touched, so the login and local
# data stay as they are.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path 'secrets.json')) {
  Write-Error 'secrets.json topilmadi. secrets.example.json dan nusxa oling.'
}
if (-not (Test-Path 'tdlib\tdjson.dll')) {
  Write-Error 'tdlib\tdjson.dll topilmadi. Avval TDLib DLL fayllarini tdlib\ papkasiga qo‘ying.'
}

$running = Get-Process -Name focus, fokus -ErrorAction SilentlyContinue
if ($running) {
  Write-Error 'Focus ishlab turibdi. Uni yoping va qayta urinib ko‘ring.'
}

Write-Host 'Release build...'
flutter build windows --release --dart-define-from-file=secrets.json --dart-define=USE_MOCK=false
if ($LASTEXITCODE -ne 0) { Write-Error 'Build muvaffaqiyatsiz tugadi.' }

$src = Join-Path $root 'build\windows\x64\runner\Release'
$exe = Join-Path $src 'focus.exe'
if (-not (Test-Path $exe)) { Write-Error "focus.exe topilmadi: $src" }
if (-not (Test-Path (Join-Path $src 'tdjson.dll'))) { Write-Error 'tdjson.dll release papkasiga nusxalanmagan.' }

$dest = Join-Path $env:LOCALAPPDATA 'Programs\Focus'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
New-Item -ItemType Directory -Force $dest | Out-Null
# fokus.exe: left in old build folders from before the rename.
Get-ChildItem $src | Where-Object Name -ne 'fokus.exe' | Copy-Item -Destination $dest -Recurse -Force

$target = Join-Path $dest 'focus.exe'
$desktop = [Environment]::GetFolderPath('Desktop')
$link = Join-Path $desktop 'Focus.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($link)
$shortcut.TargetPath = $target
$shortcut.WorkingDirectory = $dest
$shortcut.IconLocation = "$target,0"
$shortcut.Description = 'Focus: Telegram uchun lokal ish stoli'
$shortcut.Save()

Write-Host "O‘rnatildi: $dest"
Write-Host "Yorliq: $link"
