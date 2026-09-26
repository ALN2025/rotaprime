# Repara "Could not extract native JNI library" (Windows).
param(
  [string]$GradleHome = 'C:\gradle-rota-prime'
)
$ErrorActionPreference = 'SilentlyContinue'
& "$PSScriptRoot\stop_gradle_daemons.ps1"
Start-Sleep -Seconds 2
foreach ($sub in @('native', 'daemon', '.tmp')) {
  $path = Join-Path $GradleHome $sub
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Recurse -Force
  }
}
$userNative = Join-Path $env:USERPROFILE '.gradle\native'
if (Test-Path -LiteralPath $userNative) {
  Remove-Item -LiteralPath $userNative -Recurse -Force
}
Start-Sleep -Seconds 1
Write-Host "[OK] Cache JNI Gradle limpo em $GradleHome"
exit 0
