# Hook global de teclado: registra scancode/ext/vk de cada tecla.
# Uso: powershell -ExecutionPolicy Bypass -File .\key-hook.ps1
$ErrorActionPreference = 'Stop'
$log = Join-Path $env:TEMP 'opencode\key-hook-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
if (Test-Path $log) { Remove-Item $log -Force }

Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @'
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class KeySpy
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;
    private static string _logPath;

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    public static void Start(string logPath)
    {
        _logPath = logPath;
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule)
            _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);

        if (_hookID == IntPtr.Zero)
        {
            File.WriteAllText(logPath, "HOOK_FAILED\r\n");
            return;
        }
        File.AppendAllText(_logPath, "READY\r\n");
        Application.Run();
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN))
        {
            KBDLLHOOKSTRUCT k = Marshal.PtrToStructure<KBDLLHOOKSTRUCT>(lParam);
            string ext = (k.flags & 0x01) != 0 ? "EXT" : "-";
            File.AppendAllText(_logPath, string.Format("scan={0:X2} ext={1} vk={2:X2}\r\n", k.scanCode, ext, k.vkCode));
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
'@

[KeySpy]::Start($log)
