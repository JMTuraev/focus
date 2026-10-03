# Run once after `flutter create`:  powershell -ExecutionPolicy Bypass -File tool\setup_windows.ps1
# Adds an install rule so TDLib DLLs from .\tdlib are copied next to fokus.exe.
$cmake = Join-Path $PSScriptRoot "..\windows\CMakeLists.txt"
if (-not (Test-Path $cmake)) {
  Write-Error "windows\CMakeLists.txt topilmadi. Avval: flutter create --platforms=windows --project-name fokus ."
  exit 1
}
$marker = "# Fokus: bundle TDLib DLLs"
if ((Get-Content $cmake -Raw) -match [regex]::Escape($marker)) {
  Write-Host "Allaqachon qo'shilgan."
  exit 0
}
@"

$marker next to fokus.exe
file(GLOB FOKUS_TDLIB_DLLS "`${CMAKE_CURRENT_SOURCE_DIR}/../tdlib/*.dll")
install(FILES `${FOKUS_TDLIB_DLLS} DESTINATION "`${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
"@ | Add-Content $cmake
Write-Host "windows\CMakeLists.txt yangilandi."
