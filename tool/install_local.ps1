# Builds a release of Focus, installs it for the current Windows user and
# puts a "Focus" shortcut on the desktop.
#
#   powershell -ExecutionPolicy Bypass -File tool\install_local.ps1
#
# The Telegram keys come from secrets.json at build time and are never printed.
# App data (%APPDATA%\com.example\fokus) is not touched, so the login and local
# data stay as they are.
param([switch]$SkipBuild)

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
if (-not $SkipBuild) {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { Write-Error 'Build muvaffaqiyatsiz tugadi.' }
    & (Join-Path $PSScriptRoot 'build_windows.ps1') -Mode Release -RealTelegram -DefineFile secrets.json
}

$src = Join-Path $root 'build\windows-portable\x64\runner\Release'
$exe = Join-Path $src 'focus.exe'
if (-not (Test-Path $exe)) { Write-Error "focus.exe topilmadi: $src" }
if (-not (Test-Path (Join-Path $src 'tdjson.dll'))) { Write-Error 'tdjson.dll release papkasiga nusxalanmagan.' }
$manifestPath = Join-Path $src 'focus-build.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'Build manifest is missing; build with tool/build_windows.ps1 first.' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.status -ne 'complete' -or $manifest.mode -ne 'Release' -or $manifest.target -ne 'lib/main.dart' -or
    $manifest.realTelegram -ne $true -or $manifest.testRunner -ne $false) {
    throw 'Only a normal real-Telegram Release build may be installed.'
}

$programs = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs'))
$dest = Join-Path $programs 'Focus'
$stage = Join-Path $programs "Focus.install-$([guid]::NewGuid().ToString('N'))"
$previous = Join-Path $programs "Focus.previous-$([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'))-$([guid]::NewGuid().ToString('N').Substring(0,8))"
# Every directory move stays inside the explicitly named per-user Programs folder.
foreach ($candidate in @($dest, $stage, $previous)) {
    if ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($candidate)) -ne $programs) { throw 'Unexpected install path.' }
    if ((Test-Path -LiteralPath $candidate) -and ((Get-Item -LiteralPath $candidate).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'Refusing to replace an install directory that is a reparse point.'
    }
}
New-Item -ItemType Directory -Path $stage | Out-Null
# fokus.exe: left in old build folders from before the rename.
Get-ChildItem -LiteralPath $src | Where-Object Name -ne 'fokus.exe' | Copy-Item -Destination $stage -Recurse -Force
$oldMoved = $false
$newMoved = $false
try {
    if (Test-Path -LiteralPath $dest) {
        Move-Item -LiteralPath $dest -Destination $previous
        $oldMoved = $true
    }
    Move-Item -LiteralPath $stage -Destination $dest
    $newMoved = $true

    $target = Join-Path $dest 'focus.exe'
    $desktop = [Environment]::GetFolderPath('Desktop')
    $link = Join-Path $desktop 'Focus.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($link)
    $shortcut.TargetPath = $target
    $shortcut.WorkingDirectory = $dest
    $shortcut.IconLocation = "$target,0"
    $shortcut.Description = 'Focus: Telegram uchun lokal ish stoli'
    # Keep an existing user-customized shortcut to this same install location.
    if (-not (Test-Path -LiteralPath $link)) { $shortcut.Save() }
} catch {
    if ($newMoved) { Move-Item -LiteralPath $dest -Destination $stage }
    if ($oldMoved) { Move-Item -LiteralPath $previous -Destination $dest }
    throw
}

Write-Host "O‘rnatildi: $dest"
Write-Host "Yorliq: $link"
if ($oldMoved) { Write-Host "Oldingi ilova nusxasi saqlandi: $previous" }
