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
Get-WinDefaultInputMethodOverride | Format-List
