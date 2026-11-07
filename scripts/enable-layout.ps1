# Activa o layout de teclado e torna-o o predefinido. Nao precisa de administrador.
#
#   -Layout Auto        (por omissao) Apple se o layout Apple PT-PT do Boot Camp
#                       estiver instalado; senao, Portugues.
#   -Layout Apple       layout Apple PT-PT (a0000416, PortuguA.dll). So existe com
#                       os drivers do Boot Camp. Igual ao macOS, incluindo
#                       Option+Shift+8/9 para { }.
#   -Layout Portuguese  layout Portugues do Windows (00000816, kbdpo.dll). Vem com
#                       qualquer Windows (VMs, ARM64); alguns simbolos com AltGr
#                       ficam noutras teclas (ver README).
#
# Depois, correr set-scancode-map.ps1 como administrador (com o mesmo -Layout, se
# o tiveres indicado aqui) e reiniciar.
param(
  [ValidateSet('Auto', 'Apple', 'Portuguese')]
  [string]$Layout = 'Auto'
)
$ErrorActionPreference = 'Stop'
$appleKlid = 'a0000416'
$ptKlid = '00000816'

$appleFile = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$appleKlid" -Name 'Layout File' -ErrorAction SilentlyContinue).'Layout File'
$appleInstalled = [bool]($appleFile -and (Test-Path (Join-Path "$env:SystemRoot\System32" $appleFile)))

if ($Layout -eq 'Auto') {
  $Layout = if ($appleInstalled) { 'Apple' } else { 'Portuguese' }
}
if ($Layout -eq 'Apple' -and -not $appleInstalled) {
  Write-Host "ERRO: o layout Apple PT-PT ($appleKlid) nao esta instalado neste Windows." -ForegroundColor Red
  Write-Host 'So existe com os drivers de teclado da Apple (Boot Camp). Usa -Layout Portuguese. Nada foi alterado.'
  exit 1
}
"Layout: $Layout"

# 1) Backup da lista de idiomas (so na primeira vez, para nao perder o original).
$backupPath = Join-Path $env:TEMP 'opencode\winlang-backup.json'
New-Item -ItemType Directory -Force -Path (Split-Path $backupPath) | Out-Null
if (-not (Test-Path $backupPath)) {
  Get-WinUserLanguageList |
    ForEach-Object { [pscustomobject]@{ Tag = $_.LanguageTag; Tips = @($_.InputMethodTips) } } |
    ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $backupPath
  "Backup saved to $backupPath"
}
else {
  "Backup already exists at $backupPath (not overwritten)"
}

# 2) So para o layout Portugues: remover a substituicao 00000816 = a0000416
#    (HKCU\Keyboard Layout\Substitutes). E assim que o Windows guarda o tip
#    0816:a0000416; com ela, "Portugues" continuaria a ser o layout Apple.
if ($Layout -eq 'Portuguese') {
  $substKey = 'HKCU:\Keyboard Layout\Substitutes'
  $subst = (Get-ItemProperty -Path $substKey -Name $ptKlid -ErrorAction SilentlyContinue).$ptKlid
  if ($subst -eq $appleKlid) {
    Remove-ItemProperty -Path $substKey -Name $ptKlid
    "Removed substitute $ptKlid = $subst"
  }
}

function Enable-Tip([string]$tip) {
  $list = Get-WinUserLanguageList
  $tag = ($tip -split ':')[0]
  $langTag = if ($tag -eq '0816') { 'pt-PT' } else { 'en-US' }
  if (-not ($list | Where-Object { $_.LanguageTag -eq $langTag })) { $list.Add($langTag) }

  # Com o layout Portugues, tirar o layout Apple de todos os idiomas.
  if ($Layout -eq 'Portuguese') {
    foreach ($l in $list) {
      foreach ($t in @($l.InputMethodTips)) {
        if ($t -like "*:$appleKlid") { [void]$l.InputMethodTips.Remove($t) }
      }
    }
  }

  $lang = $list | Where-Object { $_.LanguageTag -eq $langTag }
  if ($tag -eq '0816') {
    $lang.InputMethodTips.Clear()
    $lang.InputMethodTips.Add($tip)
  }
  elseif (-not ($lang.InputMethodTips -contains $tip)) {
    $lang.InputMethodTips.Insert(0, $tip)
  }

  Set-WinUserLanguageList -LanguageList $list -Force

  # O Set-WinUserLanguageList descarta em silencio os metodos de entrada que
  # nao consegue usar; confirmar que este ficou mesmo na lista.
  if (-not (Get-WinUserLanguageList | Where-Object { $_.InputMethodTips -contains $tip })) {
    throw "o Windows nao aceitou o metodo de entrada $tip"
  }

  Set-WinDefaultInputMethodOverride -InputTip $tip
}

# 3) Activar o layout (Apple: pt-PT; se falhar, en-US com o layout Apple).
$tips = if ($Layout -eq 'Apple') { @("0816:$appleKlid", "0409:$appleKlid") } else { @("0816:$ptKlid") }
$usedTip = $null
foreach ($tip in $tips) {
  try {
    Enable-Tip $tip
    $usedTip = $tip
    break
  }
  catch {
    "Tip $tip failed: $($_.Exception.Message)"
  }
}

if (-not $usedTip) { throw "Nao foi possivel activar o layout $Layout." }
"Enabled input tip: $usedTip"
$klid = ($usedTip -split ':')[1]

# 4) Mudar ja a janela em primeiro plano para o layout escolhido.
if (-not ('LangSwitch' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class LangSwitch {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr LoadKeyboardLayout(string pwszKLID, uint Flags);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
'@
}

$hkl = [LangSwitch]::LoadKeyboardLayout($klid, 1)
if ($hkl -eq [IntPtr]::Zero) {
  Write-Warning "LoadKeyboardLayout($klid) falhou; o layout fica activo em aplicacoes novas ou depois de reiniciar sessao."
}
else {
  $fg = [LangSwitch]::GetForegroundWindow()
  [void][LangSwitch]::PostMessage($fg, 0x0050, [IntPtr]::Zero, $hkl)
  "Posted layout change to foreground window (HKL=$hkl)"
}

'--- Result ---'
Get-WinUserLanguageList | Select-Object LanguageTag, InputMethodTips | Format-Table -AutoSize
# Le-se o override directamente do registo: o Get-WinDefaultInputMethodOverride
# falha em algumas instalacoes ("Exception of type 'System.Exception' was thrown").
$override = (Get-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile' -Name InputMethodOverride -ErrorAction SilentlyContinue).InputMethodOverride
"InputMethodOverride: $override"
'Feito. Segue-se o set-scancode-map.ps1 (como administrador) e um reinicio.'
