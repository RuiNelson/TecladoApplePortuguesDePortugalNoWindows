#requires -RunAsAdministrator
# Remove o Scancode Map. Reiniciar para voltar ao normal.
$ErrorActionPreference = 'Stop'
$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$log = Join-Path $env:TEMP 'opencode\scancode-undo-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
try {
    Remove-ItemProperty -Path $key -Name 'Scancode Map' -Force -ErrorAction Stop
    $msg = 'OK - Scancode Map removido. Reinicia para voltar ao normal.'
    $msg | Set-Content -Encoding UTF8 $log
    Write-Host $msg
}
catch {
    "ERROR: $($_.Exception.Message)" | Set-Content -Encoding UTF8 $log
    exit 1
}
