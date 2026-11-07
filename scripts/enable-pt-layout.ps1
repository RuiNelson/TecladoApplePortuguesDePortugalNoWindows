# Activa o layout Portugues do Windows (KLID 00000816) e torna-o o predefinido.
# E o layout que o Scancode Map deste repositorio pressupoe. Vem com o Windows
# (kbdpo.dll), por isso nao e preciso instalar nada. Nao precisa de administrador.
$ErrorActionPreference = 'Stop'
$klid = '00000816'
$tip = "0816:$klid"

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

# 2) Remover a substituicao do layout PT pelo layout Apple do Boot Camp
#    (HKCU\Keyboard Layout\Substitutes: 00000816 = a0000416), deixada por versoes
#    anteriores deste repositorio. Com ela, "Portugues" deixava de ser o layout
#    do Windows e o Scancode Map ficava errado.
$substKey = 'HKCU:\Keyboard Layout\Substitutes'
$subst = (Get-ItemProperty -Path $substKey -Name $klid -ErrorAction SilentlyContinue).$klid
if ($subst) {
  Remove-ItemProperty -Path $substKey -Name $klid
  "Removed substitute $klid = $subst"
}

# 3) pt-PT so com o layout Portugues; tirar o layout Apple (a0000416) de todos os idiomas.
$list = Get-WinUserLanguageList
if (-not ($list | Where-Object { $_.LanguageTag -eq 'pt-PT' })) { $list.Add('pt-PT') }
foreach ($l in $list) {
  foreach ($t in @($l.InputMethodTips)) {
    if ($t -match ':a0000416$') { [void]$l.InputMethodTips.Remove($t) }
  }
}
$lang = $list | Where-Object { $_.LanguageTag -eq 'pt-PT' }
$lang.InputMethodTips.Clear()
$lang.InputMethodTips.Add($tip)
Set-WinUserLanguageList -LanguageList $list -Force

if (-not (Get-WinUserLanguageList | Where-Object { $_.InputMethodTips -contains $tip })) {
  throw "O Windows nao aceitou o metodo de entrada $tip."
}
Set-WinDefaultInputMethodOverride -InputTip $tip
"Enabled input tip: $tip"

# 4) Mudar ja a janela em primeiro plano para o layout Portugues.
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
