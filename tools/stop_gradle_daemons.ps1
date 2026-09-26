# Encerra apenas processos Java do Gradle (nao mata Android Studio inteiro).
$procs = Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue
if ($null -eq $procs) { exit 0 }
foreach ($p in @($procs)) {
  $cmd = $p.CommandLine
  if ([string]::IsNullOrEmpty($cmd)) { continue }
  if ($cmd -match 'GradleDaemon|gradle-wrapper|org\.gradle\.launcher') {
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
  }
}
