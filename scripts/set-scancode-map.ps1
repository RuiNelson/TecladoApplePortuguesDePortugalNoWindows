#requires -RunAsAdministrator
# Aplica o Scancode Map descrito em docs/02-scancode-map.md.
# Pressupoe o layout Portugues do Windows (00000816): correr antes enable-pt-layout.ps1.
# Depois de correr, reiniciar o Windows.
# Gravado em UTF-8 com BOM para o Windows PowerShell 5.1 ler bem os caracteres § ± « » º ª.
#
#   -SwapIsoKeys    o Windows recebe trocadas a tecla do canto superior esquerdo
#                   (§ ±) e a do lado do Shift esquerdo (< >). Acontece no Boot Camp,
#                   porque o teclado Apple ISO as envia trocadas; numa VM no macOS
#                   chegam na posicao normal. Sinal: depois de reiniciar, a tecla
#                   < > escreve « em vez de <.
#   -KeepModifiers  nao troca Command/Ctrl (por exemplo, se a VM ja o faz).
param(
    [switch]$SwapIsoKeys,
    [switch]$KeepModifiers
)
$ErrorActionPreference = 'Stop'
$log = Join-Path $env:TEMP 'opencode\scancode-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

# Posicao fisica (scancode PC) -> scancode do layout Portugues do Windows que
# escreve o que esta gravado nessa tecla do teclado Apple. As teclas que nao
# estao aqui ja coincidem e ficam como estao.
$positions = @(
    @(0x29, 0x0D, 'canto superior esquerdo (§ ±)   -> « » (o layout PT não tem § ± numa tecla)'),
    @(0x56, 0x56, 'ao lado do Shift esquerdo (< >) -> < >'),
    @(0x0D, 0x1A, 'à direita do '' ? (+ *)         -> + *'),
    @(0x1A, 0x28, 'à direita do P (º ª)            -> º ª'),
    @(0x28, 0x2B, 'à direita do Ç (~ ^)            -> ~ ^'),
    @(0x2B, 0x29, 'à esquerda do Enter (\ |)       -> \ |')
)

# Cada entrada: @(novo scancode, scancode recebido, descricao).
$entries = New-Object System.Collections.Generic.List[object]
foreach ($p in $positions) {
    $raw = $p[0]
    if ($SwapIsoKeys) {
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
    $msg = "OK`nSwapIsoKeys: $SwapIsoKeys  KeepModifiers: $KeepModifiers`n$($lines -join "`n")`nScancode Map: $hex"
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
