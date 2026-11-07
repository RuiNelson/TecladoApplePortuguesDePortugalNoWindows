if (-not ('KbDump' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class KbDump {
    [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr LoadKeyboardLayout(string pwszKLID, uint Flags);
    [DllImport("user32.dll")]
    public static extern uint MapVirtualKeyEx(uint uCode, uint uMapType, IntPtr dwhkl);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern int ToUnicodeEx(uint wVirtKey, uint wScanCode, byte[] lpKeyState,
        [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff, int cchBuff, uint wFlags, IntPtr dwhkl);

    public static string Key(IntPtr hkl, uint sc, bool shift, bool altgr) {
        byte[] state = new byte[256];
        if (shift) state[0x10] = 0x80;
        if (altgr) { state[0x11] = 0x80; state[0x12] = 0x80; }
        uint vk = MapVirtualKeyEx(sc, 3, hkl);
        StringBuilder sb = new StringBuilder(8);
        int r = ToUnicodeEx(vk, sc, state, sb, 8, 0, hkl);
        if (r == -1) {
            string dead = sb.Length > 0 ? sb[0].ToString() : "";
            byte[] none = new byte[256];
            StringBuilder junk = new StringBuilder(8);
            ToUnicodeEx(0x20, 0x39, none, junk, 8, 0, hkl);
            return "DK:" + dead;
        }
        if (r <= 0) return "";
        return sb.ToString(0, r);
    }
}
'@
}

$keys = @(
  @(0x29,'top-left'), @(0x02,'1'), @(0x03,'2'), @(0x04,'3'), @(0x05,'4'), @(0x06,'5'),
  @(0x07,'6'), @(0x08,'7'), @(0x09,'8'), @(0x0A,'9'), @(0x0B,'0'), @(0x0C,'-'), @(0x0D,'='),
  @(0x10,'Q'), @(0x11,'W'), @(0x12,'E'), @(0x13,'R'), @(0x14,'T'), @(0x15,'Y'), @(0x16,'U'),
  @(0x17,'I'), @(0x18,'O'), @(0x19,'P'), @(0x1A,'['), @(0x1B,']'),
  @(0x1E,'A'), @(0x1F,'S'), @(0x20,'D'), @(0x21,'F'), @(0x22,'G'), @(0x23,'H'), @(0x24,'J'),
  @(0x25,'K'), @(0x26,'L'), @(0x27,';'), @(0x28,"'"), @(0x2B,'\\'),
  @(0x56,'<>'), @(0x2C,'Z'), @(0x2D,'X'), @(0x2E,'C'), @(0x2F,'V'), @(0x30,'B'), @(0x31,'N'),
  @(0x32,'M'), @(0x33,','), @(0x34,'.'), @(0x35,'/'), @(0x39,'Space')
)

function Esc([string]$s) {
  if ($null -eq $s -or $s.Length -eq 0) { return '-' }
  $out = foreach ($ch in $s.ToCharArray()) {
    $code = [int]$ch
    if ($code -lt 32 -or $code -gt 126) { 'U+{0:X4}' -f $code } else { [string]$ch }
  }
  return ($out -join '')
}

foreach ($kl in @('00000816','a0000416')) {
  $hkl = [KbDump]::LoadKeyboardLayout($kl, 0)
  "===== $kl  (HKL=$hkl) ====="
  $rows = foreach ($k in $keys) {
    $sc = [uint32]$k[0]
    $name = $k[1]
    [pscustomobject]@{
      Key   = $name
      None  = Esc ([KbDump]::Key($hkl, $sc, $false, $false))
      Shift = Esc ([KbDump]::Key($hkl, $sc, $true,  $false))
      AltGr = Esc ([KbDump]::Key($hkl, $sc, $false, $true))
      ShAlt = Esc ([KbDump]::Key($hkl, $sc, $true,  $true))
    }
  }
  $rows | Format-Table -AutoSize | Out-String -Width 200
}
