param(
  [Parameter(Mandatory = $true)][string]$ApkPath,
  [ValidateSet('Mobile', 'Emulador')]
  [string]$Target = 'Mobile'
)
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-not (Test-Path -LiteralPath $ApkPath)) {
  Write-Host "[ERRO] Arquivo nao encontrado: $ApkPath"
  exit 1
}
$fi = Get-Item -LiteralPath $ApkPath
Write-Host "Tamanho no disco: $($fi.Length) bytes"
$z = [IO.Compression.ZipFile]::OpenRead($fi.FullName)
$abis = @($z.Entries | Where-Object { $_.FullName -like 'lib/*' } | ForEach-Object { ($_.FullName -split '/')[1] } | Sort-Object -Unique)
$hasApp = @($z.Entries | Where-Object { $_.FullName -like 'lib/*/libapp.so' }).Count -ge 1
$z.Dispose()
Write-Host ("CPUs no APK: " + ($abis -join ', '))
if ($Target -eq 'Mobile') {
  if ($abis -notcontains 'armeabi-v7a' -or $abis -notcontains 'arm64-v8a') {
    Write-Host "[ERRO] APK celular: faltam armeabi-v7a e/ou arm64-v8a."
    exit 1
  }
  Write-Host "[OK] APK celular (ARM 32 + 64 bits)."
} else {
  $okEmu = ($abis -contains 'x86_64') -or ($abis -contains 'arm64-v8a')
  if (-not $okEmu) {
    Write-Host "[ERRO] APK emulador: falta x86_64 ou arm64-v8a."
    exit 1
  }
  Write-Host "[OK] APK emulador (AVD Intel ou ARM)."
}
if (-not $hasApp) {
  Write-Host "[ERRO] Falta libapp.so - APK incompleto."
  exit 1
}
$hash = (Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256).Hash
Write-Host ("SHA256: " + $hash)
$infoPath = [IO.Path]::ChangeExtension($ApkPath, '.CONFIRA.txt')
$tipo = if ($Target -eq 'Mobile') { 'celular (distribuir)' } else { 'emulador Android no PC' }
$lines = @(
  "ROTA PRIME - conferencia do APK ($tipo)",
  "Arquivo: $ApkPath",
  "Tamanho EXATO em bytes: $($fi.Length)",
  "SHA256: $hash",
  "CPUs: $($abis -join ', ')"
)
if ($Target -eq 'Mobile') {
  $lines += "No celular o tamanho deve ser IGUAL. Se for menor, baixe de novo ou use cabo USB."
}
Set-Content -LiteralPath $infoPath -Value $lines -Encoding UTF8
Write-Host ("Salvo: " + $infoPath)
exit 0
