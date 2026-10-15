# Builds a complete Windows bundle without changing the installed app or data.
# Supports MSVC installations whose Visual Studio registration is unavailable.
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Mode = 'Debug',
    [string]$Target = 'lib/main.dart',
    [string]$BuildDirectory = 'build/windows-portable/x64',
    [string]$VisualStudioPath,
    [string]$VisualStudioVersion,
    [switch]$RealTelegram,
    [string]$DefineFile
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot $BuildDirectory))
if (-not $buildRoot.StartsWith("$projectRoot\build\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'BuildDirectory must be inside this project build folder.'
}
if ($Target -ne 'lib/main.dart' -and $RealTelegram) {
    throw 'RealTelegram is only supported with lib/main.dart.'
}

if (-not $VisualStudioPath) {
    $instances = Join-Path $env:ProgramData 'Microsoft/VisualStudio/Packages/_Instances'
    $candidates = @(Get-ChildItem -LiteralPath $instances -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $stateFile = Join-Path $_.FullName 'state.json'
        if (Test-Path -LiteralPath $stateFile) {
            $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
            if ($state.installationPath -and $state.installationVersion) { $state }
        }
    } | Sort-Object { [version]$_.installationVersion } -Descending)
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate.installationPath 'VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt')) {
            $VisualStudioPath = $candidate.installationPath
            $VisualStudioVersion = $candidate.installationVersion
            break
        }
    }
}
if (-not $VisualStudioPath -or $VisualStudioVersion -notmatch '^17\.\d+\.\d+\.\d+$') {
    throw 'Provide a VS 2022 C++ installation with -VisualStudioPath and -VisualStudioVersion.'
}
$toolsVersion = (Get-Content -LiteralPath (Join-Path $VisualStudioPath 'VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt') -Raw).Trim()
foreach ($required in @(
    "VC/Tools/MSVC/$toolsVersion/bin/Hostx64/x64/cl.exe",
    "VC/Tools/MSVC/$toolsVersion/atlmfc/include/atlbase.h",
    'MSBuild/Current/Bin/MSBuild.exe'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $VisualStudioPath $required))) { throw "Missing build component: $required" }
}

# Official Kitware archive, pinned to its published SHA-256.
$cmakeVersion = '3.31.6'
$cmakeHash = 'D163CD3AB4959B0A53FA8988F2DDBD2E6C501658201E6A154386BAD9DBE4F836'
$toolCache = Join-Path $projectRoot 'build/toolchain'
$archiveName = "cmake-$cmakeVersion-windows-x86_64.zip"
$archive = Join-Path $toolCache $archiveName
$cmake = Join-Path $toolCache "cmake-$cmakeVersion-windows-x86_64/bin/cmake.exe"
New-Item -ItemType Directory -Path $toolCache -Force | Out-Null
if (-not (Test-Path -LiteralPath $archive)) {
    Invoke-WebRequest -Uri "https://github.com/Kitware/CMake/releases/download/v$cmakeVersion/$archiveName" -OutFile $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $cmakeHash) { throw 'CMake archive checksum mismatch.' }
if (-not (Test-Path -LiteralPath $cmake)) { Expand-Archive -LiteralPath $archive -DestinationPath $toolCache }
& $cmake --version
if ($LASTEXITCODE -ne 0) { throw 'The project CMake executable cannot run.' }

$previousTemp = $env:TEMP
$previousTmp = $env:TMP
Push-Location $projectRoot
try {
    $env:TEMP = Join-Path $projectRoot 'build/toolchain/temp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    $flutterArgs = @('build', 'windows', "--$($Mode.ToLowerInvariant())", '--no-pub', '--config-only', '--target', $Target,
        "--dart-define=USE_MOCK=$((-not $RealTelegram).ToString().ToLowerInvariant())")
    if ($DefineFile) { $flutterArgs += "--dart-define-from-file=$DefineFile" }
    # Flutter writes its generated config/plugin links before locating VS.
    # Only this exact discovery failure is allowed; all other failures stop.
    # Windows PowerShell 5.1 wraps native stderr in ErrorRecord; collect the
    # expected discovery error without terminating before checking its exit.
    try {
        $ErrorActionPreference = 'Continue'
        $configOutput = & flutter @flutterArgs 2>&1
        $configExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = 'Stop'
    }
    if ($configExit -ne 0 -and ($configOutput -join "`n") -notmatch 'Unable to find suitable Visual Studio toolchain') {
        throw "Flutter configuration failed: $($configOutput -join "`n")"
    }
    if (-not (Test-Path -LiteralPath 'windows/flutter/ephemeral/generated_config.cmake')) { throw 'Flutter config is missing.' }
    $instance = "$VisualStudioPath,version=$VisualStudioVersion"
    # Only the known temporary-data harness gets a separate instance identity.
    # Always reset this cache option for ordinary app builds.
    $testRunner = if ($Target -eq 'integration_test/desktop_chat_test.dart' -and -not $RealTelegram) { 'ON' } else { 'OFF' }
    & $cmake -S windows -B $buildRoot -G 'Visual Studio 17 2022' -A x64 "-DCMAKE_GENERATOR_INSTANCE=$instance" -DFLUTTER_TARGET_PLATFORM=windows-x64 "-DFOCUS_INTEGRATION_TEST_RUNNER=$testRunner"
    if ($LASTEXITCODE -ne 0) { throw 'CMake generation failed.' }
    & $cmake --build $buildRoot --config $Mode --target INSTALL --parallel 2
    if ($LASTEXITCODE -ne 0) { throw 'Windows compilation failed.' }
    $executable = Join-Path $buildRoot "runner/$Mode/focus.exe"
    if (-not (Test-Path -LiteralPath $executable)) { throw 'Windows executable is missing.' }
    Write-Host "Built: $executable"
} finally {
    Pop-Location
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
}
