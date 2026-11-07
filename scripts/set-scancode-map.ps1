﻿#requires -RunAsAdministrator
# Aplica o Scancode Map descrito em docs/03-scancode-map.md.
# Correr depois de enable-layout.ps1 e reiniciar o Windows a seguir.
# Gravado em UTF-8 com BOM para o Windows PowerShell 5.1 ler bem os caracteres § ± « » º ª.
#
#   -Layout Auto        (por omissao) Apple se o layout Apple PT-PT do Boot Camp
#                       estiver instalado; senao, Portugues. Tem de ser o mesmo
#                       layout que o enable-layout.ps1 activou.
#   -Layout Apple       mapa para o layout Apple PT-PT (a0000416).
#   -Layout Portuguese  mapa para o layout Portugues do Windows (00000816).
#   -SwapIsoKeys        o Windows recebe trocadas a tecla do canto superior esquerdo
#                       (§ ±) e a do lado do Shift esquerdo (< >). Por omissao,
#                       liga-se quando ha drivers do Boot Camp (o teclado Apple ISO
#                       envia-as trocadas) e desliga-se nas VMs (o macOS ja as
#                       corrige). -SwapIsoKeys:$false desliga-a a forca.
#                       Sinal de que esta errado: a tecla < > nao escreve <.
#   -KeepModifiers      nao troca Command/Ctrl (por exemplo, se a VM ja o faz).
param(
    [ValidateSet('Auto', 'Apple', 'Portuguese')]
    [string]$Layout = 'Auto',
    [switch]$SwapIsoKeys,
    [switch]$KeepModifiers
)
$ErrorActionPreference = 'Stop'
$log = Join-Path $env:TEMP 'opencode\scancode-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

# O layout Apple PT-PT so existe com os drivers do Boot Camp; serve tambem para
# saber se estamos no Boot Camp.
$appleFile = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\a0000416' -Name 'Layout File' -ErrorAction SilentlyContinue).'Layout File'
$appleInstalled = [bool]($appleFile -and (Test-Path (Join-Path "$env:SystemRoot\System32" $appleFile)))

if ($Layout -eq 'Auto') {
    $Layout = if ($appleInstalled) { 'Apple' } else { 'Portuguese' }
}
if ($Layout -eq 'Apple' -and -not $appleInstalled) {
    Write-Warning 'O layout Apple PT-PT (a0000416) nao esta instalado; este mapa so serve com esse layout.'
}
$swap = if ($PSBoundParameters.ContainsKey('SwapIsoKeys')) { [bool]$SwapIsoKeys } else { $appleInstalled }

# Posicao fisica (scancode PC) -> scancode que, no layout escolhido, escreve o que
# esta gravado nessa tecla do teclado Apple. As teclas que nao estao aqui ja
# coincidem e ficam como estao.
if ($Layout -eq 'Apple') {
    $positions = @(
        @(0x56, 0x56, 'ao lado do Shift esquerdo (< >) -> < >'),
        @(0x29, 0x29, 'canto superior esquerdo (§ ±)   -> § ±')
    )
}
else {
    $positions = @(
        @(0x29, 0x0D, 'canto superior esquerdo (§ ±)   -> « » (o layout PT não tem § ± numa tecla)'),
        @(0x56, 0x56, 'ao lado do Shift esquerdo (< >) -> < >'),
        @(0x0D, 0x1A, 'à direita do '' ? (+ *)         -> + *'),
        @(0x1A, 0x28, 'à direita do P (º ª)            -> º ª'),
        @(0x28, 0x2B, 'à direita do Ç (~ ^)            -> ~ ^'),
        @(0x2B, 0x29, 'à esquerda do Enter (\ |)       -> \ |')
    )
}

# Cada entrada: @(novo scancode, scancode recebido, descricao).
$entries = New-Object System.Collections.Generic.List[object]
foreach ($p in $positions) {
    $raw = $p[0]
    if ($swap) {
        if ($raw -eq 0x29) { $raw = 0x56 } elseif ($raw -eq 0x56) { $raw = 0x29 }
    }
    if ($raw -ne $p[1]) { $entries.Add(@($p[1], $raw, $p[2])) }
}
if (-not $KeepModifiers) {
    $entries.Add(@(0x001D, 0xE05B, 'Command esquerdo -> Ctrl esquerdo'))
    $entries.Add(@(0xE05B, 0x001D, 'Ctrl esquerdo -> Windows esquerda'))
    $entries.Add(@(0xE01D, 0xE05C, 'Command direito -> Ctrl direito'))
}

try {
    # Formato: 8 bytes a zero, DWORD com n. de entradas (incluindo o terminador),
    # entradas de 4 bytes (novo, antigo; little-endian; extended = 0xE0..), terminador.
    $bytes = New-Object System.Collections.Generic.List[byte]
    $bytes.AddRange([byte[]](0, 0, 0, 0, 0, 0, 0, 0))
    $bytes.AddRange([BitConverter]::GetBytes([uint32]($entries.Count + 1)))
    foreach ($e in $entries) {
        $bytes.AddRange([BitConverter]::GetBytes([uint16]$e[0]))
        $bytes.AddRange([BitConverter]::GetBytes([uint16]$e[1]))
    }
    $bytes.AddRange([byte[]](0, 0, 0, 0))

    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    New-ItemProperty -Path $key -Name 'Scancode Map' -PropertyType Binary -Value $bytes.ToArray() -Force | Out-Null
    $read = (Get-ItemProperty -Path $key -Name 'Scancode Map').'Scancode Map'
    $hex = ($read | ForEach-Object { $_.ToString('X2') }) -join ' '

    $lines = foreach ($e in $entries) { '  0x{0:X4} <- 0x{1:X4}  {2}' -f $e[0], $e[1], $e[2] }
    $msg = "OK`nLayout: $Layout  SwapIsoKeys: $swap  KeepModifiers: $KeepModifiers`n$($lines -join "`n")`nScancode Map: $hex"
    $msg | Set-Content -Encoding UTF8 $log
    Write-Host $msg
    Write-Host 'Reinicia o Windows para aplicar.'
}
catch {
    $err = "ERROR: $($_.Exception.Message)"
    $err | Set-Content -Encoding UTF8 $log
    Write-Host $err -ForegroundColor Red
    exit 1
}
