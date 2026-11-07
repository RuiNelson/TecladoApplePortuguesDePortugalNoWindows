#requires -RunAsAdministrator
# Remove o Scancode Map. Reiniciar para voltar ao normal.
$ErrorActionPreference = 'Stop'
$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$log = Join-Path $env:TEMP 'opencode\scancode-undo-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
try {
    if ($null -eq (Get-ItemProperty -Path $key -Name 'Scancode Map' -ErrorAction SilentlyContinue)) {
        $msg = 'OK - Nao existe Scancode Map; nada a remover.'
    }
    else {
        Remove-ItemProperty -Path $key -Name 'Scancode Map' -Force
        $msg = 'OK - Scancode Map removido. Reinicia para voltar ao normal.'
    }
    $msg | Set-Content -Encoding UTF8 $log
    Write-Host $msg
}
catch {
    $err = "ERROR: $($_.Exception.Message)"
    $err | Set-Content -Encoding UTF8 $log
    Write-Host $err -ForegroundColor Red
    exit 1
}
