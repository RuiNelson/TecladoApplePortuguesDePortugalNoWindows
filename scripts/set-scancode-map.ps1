#requires -RunAsAdministrator
# Aplica o Scancode Map descrito em docs/02-scancode-map.md.
# Depois de correr, reiniciar o Windows.
$ErrorActionPreference = 'Stop'
$log = Join-Path $env:TEMP 'opencode\scancode-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

try {
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    $bytes = [byte[]](
        0x00, 0x00, 0x00, 0x00,   # version
        0x00, 0x00, 0x00, 0x00,   # flags
        0x06, 0x00, 0x00, 0x00,   # 6 entries (5 swaps + terminator)
        0x56, 0x00, 0x29, 0x00,   # new 0x56   <- old 0x29   (<> -> §±)
        0x29, 0x00, 0x56, 0x00,   # new 0x29   <- old 0x56   (§± -> <>)
        0x1D, 0x00, 0x5B, 0xE0,   # new 0x1D   <- old 0xE05B (Cmd esq -> Ctrl esq)
        0x5B, 0xE0, 0x1D, 0x00,   # new 0xE05B <- old 0x1D   (Ctrl esq -> Win esq)
        0x1D, 0xE0, 0x5C, 0xE0,   # new 0xE01D <- old 0xE05C (Cmd dir -> Ctrl dir)
        0x00, 0x00, 0x00, 0x00    # terminator
    )

    New-ItemProperty -Path $key -Name 'Scancode Map' -PropertyType Binary -Value $bytes -Force | Out-Null
    $read = (Get-ItemProperty -Path $key -Name 'Scancode Map').'Scancode Map'
    $hex = ($read | ForEach-Object { $_.ToString('X2') }) -join ' '

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $msg = "OK`nAdmin: $isAdmin`nScancode Map: $hex"
    $msg | Set-Content -Encoding UTF8 $log
    Write-Host $msg
    Write-Host 'Reinicia o Windows para aplicar.'
}
catch {
    "ERROR: $($_.Exception.Message)" | Set-Content -Encoding UTF8 $log
    exit 1
}
