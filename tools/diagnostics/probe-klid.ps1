Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class KlidProbe {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern int GetKeyboardLayoutName(StringBuilder name);
}
'@
$sb = New-Object System.Text.StringBuilder 64
[void][KlidProbe]::GetKeyboardLayoutName($sb)
"KLID: $($sb.ToString())"
Get-WinUserLanguageList | Select-Object LanguageTag, InputMethodTips | Format-Table -AutoSize
try {
  Get-WinDefaultInputMethodOverride -ErrorAction Stop | Format-List
}
catch {
  $override = (Get-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile' -Name InputMethodOverride -ErrorAction SilentlyContinue).InputMethodOverride
  "InputMethodOverride (registo): $override"
}
