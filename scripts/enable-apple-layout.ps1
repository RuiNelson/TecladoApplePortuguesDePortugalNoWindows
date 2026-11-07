# Activa o layout Apple PT-PT (KLID a0000416) e torna-o o predefinido.
# Nao precisa de administrador. Algumas apps so mudam depois de reiniciar.
$ErrorActionPreference = 'Stop'

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

function Enable-AppleLayout([string]$tip) {
  $list = Get-WinUserLanguageList
  $tag = ($tip -split ':')[0]

  if ($tag -eq '0816') {
    if (-not ($list | Where-Object { $_.LanguageTag -eq 'pt-PT' })) { $list.Add('pt-PT') }
    $lang = $list | Where-Object { $_.LanguageTag -eq 'pt-PT' }
    $lang.InputMethodTips.Clear()
    $lang.InputMethodTips.Add($tip)
  }
  else {
    if (-not ($list | Where-Object { $_.LanguageTag -eq 'en-US' })) { $list.Add('en-US') }
    $lang = $list | Where-Object { $_.LanguageTag -eq 'en-US' }
    if (-not ($lang.InputMethodTips -contains $tip)) { $lang.InputMethodTips.Insert(0, $tip) }
  }

  Set-WinUserLanguageList -LanguageList $list -Force
  Set-WinDefaultInputMethodOverride -InputTip $tip
}

$usedTip = $null
foreach ($tip in @('0816:a0000416', '0409:a0000416')) {
  try {
    Enable-AppleLayout $tip
    $usedTip = $tip
    break
  }
  catch {
    "Tip $tip failed: $($_.Exception.Message)"
  }
}

if (-not $usedTip) { throw 'Could not enable the Apple layout.' }
"Enabled input tip: $usedTip"

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

$hkl = [LangSwitch]::LoadKeyboardLayout('a0000416', 1)
$fg = [LangSwitch]::GetForegroundWindow()
[void][LangSwitch]::PostMessage($fg, 0x0050, [IntPtr]::Zero, $hkl)
"Posted layout change to foreground window (HKL=$hkl)"

'--- Result ---'
Get-WinUserLanguageList | Select-Object LanguageTag, InputMethodTips | Format-Table -AutoSize
# Get-WinDefaultInputMethodOverride falha em algumas instalacoes
# ("Exception of type 'System.Exception' was thrown") mesmo depois de o Set
# ter funcionado. Nesse caso le-se o valor directamente do registo.
try {
  Get-WinDefaultInputMethodOverride | Format-List
}
catch {
  $override = (Get-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile' -Name InputMethodOverride -ErrorAction SilentlyContinue).InputMethodOverride
  "InputMethodOverride (registo): $override"
}
