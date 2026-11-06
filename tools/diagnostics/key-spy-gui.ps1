# Janela "Key Spy": mostra [TECLA] scancode/ext/vk e [HID] relatorios crus.
# Uso: powershell -ExecutionPolicy Bypass -File .\key-spy-gui.ps1
# NAO arrancar com -WindowStyle Hidden: isso esconde tambem a janela do WinForms.
$ErrorActionPreference = 'Stop'
$log = Join-Path $env:TEMP 'opencode\keyspy-gui-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

public class KeySpyGui
{
    public const int WM_INPUT = 0x00FF;
    const int WH_KEYBOARD_LL = 13;
    const int WM_KEYDOWN = 0x0100;
    const int WM_KEYUP = 0x0101;
    const int WM_SYSKEYDOWN = 0x0104;
    const int WM_SYSKEYUP = 0x0105;
    const uint RID_INPUT = 0x10000003;
    const uint RIDEV_INPUTSINK = 0x00000100;
    const uint RIDI_DEVICENAME = 0x20000007;
    const uint RIDI_DEVICEINFO = 0x2000000B;

    static IntPtr hookID = IntPtr.Zero;
    static LowLevelKeyboardProc proc = HookCallback;
    static TextBox box;
    static string logPath;

    delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    struct RAWINPUTDEVICE { public ushort usUsagePage; public ushort usUsage; public uint dwFlags; public IntPtr hwndTarget; }
    [StructLayout(LayoutKind.Sequential)]
    struct RAWINPUTHEADER { public uint dwType; public uint dwSize; public IntPtr hDevice; public IntPtr wParam; }
    [StructLayout(LayoutKind.Sequential)]
    struct RAWINPUTDEVICELIST { public IntPtr hDevice; public uint dwType; }
    [StructLayout(LayoutKind.Sequential)]
    struct RID_DEVICE_INFO { public uint cbSize; public uint dwType; public uint dwVendorId; public uint dwProductId; public uint dwVersionNumber; public ushort usUsagePage; public ushort usUsage; public uint pad1; public uint pad2; }
    [StructLayout(LayoutKind.Sequential)]
    struct KBDLLHOOKSTRUCT { public uint vkCode; public uint scanCode; public uint flags; public uint time; public IntPtr dwExtraInfo; }

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("user32.dll", SetLastError = true)]
    static extern bool RegisterRawInputDevices(RAWINPUTDEVICE[] pRawInputDevices, uint uiNumDevices, uint cbSize);
    [DllImport("user32.dll")]
    static extern uint GetRawInputData(IntPtr hRawInput, uint uiCommand, IntPtr pData, ref uint pcbSize, uint cbSizeHeader);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern uint GetRawInputDeviceInfo(IntPtr hDevice, uint uiCommand, IntPtr pData, ref uint pcbSize);
    [DllImport("user32.dll")]
    static extern uint GetRawInputDeviceList(IntPtr pRawInputDeviceList, ref uint puiNumDevices, uint cbSize);

    class SpyForm : Form
    {
        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_INPUT) KeySpyGui.HandleRawInput(m.LParam);
            base.WndProc(ref m);
        }
    }

    public static void Run(string path)
    {
        logPath = path;
        try { if (File.Exists(logPath)) File.Delete(logPath); } catch { }

        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
        Application.ThreadException += delegate(object sender, ThreadExceptionEventArgs e)
        {
            Append("ERRO UI: " + e.Exception.GetType().Name + ": " + e.Exception.Message);
        };

        SpyForm form = new SpyForm();
        form.Text = "Key Spy - prime a tecla Eject";
        form.Width = 900;
        form.Height = 500;
        form.TopMost = true;
        form.StartPosition = FormStartPosition.CenterScreen;

        box = new TextBox();
        box.Multiline = true;
        box.ReadOnly = true;
        box.ScrollBars = ScrollBars.Both;
        box.WordWrap = false;
        box.Dock = DockStyle.Fill;
        box.Font = new Font("Consolas", 10);
        box.BackColor = Color.Black;
        box.ForeColor = Color.Lime;

        Panel bottom = new Panel();
        bottom.Dock = DockStyle.Bottom;
        bottom.Height = 48;
        Button clear = new Button();
        clear.Text = "Limpar";
        clear.SetBounds(10, 8, 100, 30);
        Button copy = new Button();
        copy.Text = "Copiar tudo";
        copy.SetBounds(120, 8, 110, 30);
        Label hint = new Label();
        hint.Text = "Prime Eject 2-3 vezes. As linhas [TECLA] sao teclas normais; [HID] sao dados crus.";
        hint.SetBounds(245, 14, 640, 24);
        clear.Click += delegate { box.Clear(); };
        copy.Click += delegate { try { Clipboard.SetText(box.Text); } catch { } };
        bottom.Controls.Add(clear);
        bottom.Controls.Add(copy);
        bottom.Controls.Add(hint);

        form.Controls.Add(box);
        form.Controls.Add(bottom);

        form.Shown += delegate
        {
            InstallHook();
            InstallRawInput(form.Handle);
            Append("PRONTO. Prime a tecla Eject 2-3 vezes.");
            Append("");
        };
        form.FormClosed += delegate
        {
            if (hookID != IntPtr.Zero) UnhookWindowsHookEx(hookID);
        };

        Application.Run(form);
    }

    static void Append(string line)
    {
        string s = DateTime.Now.ToString("HH:mm:ss.fff") + "  " + line;
        try { File.AppendAllText(logPath, s + "\r\n"); } catch { }
        if (box != null && box.IsHandleCreated) box.AppendText(s + "\r\n");
    }

    static void InstallHook()
    {
        using (Process cur = Process.GetCurrentProcess())
        using (ProcessModule mod = cur.MainModule)
        {
            hookID = SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(mod.ModuleName), 0);
        }
        Append("Hook de teclado: " + (hookID != IntPtr.Zero ? "OK" : "FALHOU"));
    }

    static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            int msg = wParam.ToInt32();
            if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN || msg == WM_KEYUP || msg == WM_SYSKEYUP)
            {
                KBDLLHOOKSTRUCT k = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
                string name = "";
                try { name = ((Keys)k.vkCode).ToString(); } catch { }
                string dir = (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) ? "DOWN" : "UP  ";
                Append(string.Format("[TECLA] {0} scan=0x{1:X2} ext={2} vk=0x{3:X2} ({4})",
                    dir, k.scanCode, (k.flags & 1) != 0 ? "SIM" : "nao", k.vkCode, name));
            }
        }
        return CallNextHookEx(hookID, nCode, wParam, lParam);
    }

    static void InstallRawInput(IntPtr hwnd)
    {
        List<ushort[]> pairs = new List<ushort[]>();
        uint count = 0;
        int listSize = Marshal.SizeOf(typeof(RAWINPUTDEVICELIST));
        GetRawInputDeviceList(IntPtr.Zero, ref count, (uint)listSize);
        if (count == 0) { Append("HID: nenhum dispositivo encontrado."); return; }

        IntPtr list = Marshal.AllocHGlobal((int)count * listSize);
        try
        {
            GetRawInputDeviceList(list, ref count, (uint)listSize);
            for (int i = 0; i < count; i++)
            {
                IntPtr h = Marshal.ReadIntPtr(list, i * listSize);
                uint type = (uint)Marshal.ReadInt32(list, i * listSize + IntPtr.Size);
                if (type != 2) continue;
                ushort page, usage;
                if (GetHidUsage(h, out page, out usage))
                {
                    bool found = false;
                    foreach (ushort[] p in pairs) { if (p[0] == page && p[1] == usage) { found = true; break; } }
                    if (!found) pairs.Add(new ushort[] { page, usage });
                }
            }
        }
        finally { Marshal.FreeHGlobal(list); }

        int ok = 0;
        foreach (ushort[] p in pairs)
        {
            RAWINPUTDEVICE[] d = new RAWINPUTDEVICE[1];
            d[0].usUsagePage = p[0];
            d[0].usUsage = p[1];
            d[0].dwFlags = RIDEV_INPUTSINK;
            d[0].hwndTarget = hwnd;
            if (RegisterRawInputDevices(d, 1, (uint)Marshal.SizeOf(typeof(RAWINPUTDEVICE)))) ok++;
        }
        Append(string.Format("HID: {0} coleccoes registadas de {1} encontradas.", ok, pairs.Count));
        foreach (ushort[] p in pairs)
            Append(string.Format("  coleccao page=0x{0:X2} usage=0x{1:X2}", p[0], p[1]));
    }

    static bool GetHidUsage(IntPtr hDevice, out ushort page, out ushort usage)
    {
        page = 0; usage = 0;
        uint size = (uint)Marshal.SizeOf(typeof(RID_DEVICE_INFO));
        IntPtr buf = Marshal.AllocHGlobal((int)size);
        try
        {
            Marshal.WriteInt32(buf, 0, (int)size);
            if (GetRawInputDeviceInfo(hDevice, RIDI_DEVICEINFO, buf, ref size) == uint.MaxValue) return false;
            RID_DEVICE_INFO info = (RID_DEVICE_INFO)Marshal.PtrToStructure(buf, typeof(RID_DEVICE_INFO));
            page = info.usUsagePage;
            usage = info.usUsage;
            return true;
        }
        finally { Marshal.FreeHGlobal(buf); }
    }

    static void HandleRawInput(IntPtr lParam)
    {
        try
        {
            uint size = 0;
            uint hdrSize = (uint)Marshal.SizeOf(typeof(RAWINPUTHEADER));
            GetRawInputData(lParam, RID_INPUT, IntPtr.Zero, ref size, hdrSize);
            if (size == 0) return;

            IntPtr buf = Marshal.AllocHGlobal((int)size);
            try
            {
                if (GetRawInputData(lParam, RID_INPUT, buf, ref size, hdrSize) == uint.MaxValue) return;
                RAWINPUTHEADER hdr = (RAWINPUTHEADER)Marshal.PtrToStructure(buf, typeof(RAWINPUTHEADER));
                if (hdr.dwType != 2) return;
                int off = Marshal.SizeOf(typeof(RAWINPUTHEADER));
                uint sizeHid = (uint)Marshal.ReadInt32(buf, off);
                uint cnt = (uint)Marshal.ReadInt32(buf, off + 4);
                off += 8;
                if (sizeHid == 0 || sizeHid > 512 || cnt > 64) return;

                ushort pg, us;
                GetHidUsage(hdr.hDevice, out pg, out us);
                string dev = ShortDev(DeviceName(hdr.hDevice));
                for (int i = 0; i < cnt; i++)
                {
                    StringBuilder sb = new StringBuilder();
                    for (int b = 0; b < sizeHid; b++)
                        sb.Append(Marshal.ReadByte(buf, off + i * (int)sizeHid + b).ToString("X2")).Append(' ');
                    Append(string.Format("[HID 0x{0:X2}:0x{1:X2}] {2} | {3}", pg, us, dev, sb.ToString().Trim()));
                }
            }
            finally { Marshal.FreeHGlobal(buf); }
        }
        catch (Exception ex)
        {
            Append("ERRO HID: " + ex.GetType().Name + ": " + ex.Message);
        }
    }

    static string DeviceName(IntPtr h)
    {
        uint size = 0;
        GetRawInputDeviceInfo(h, RIDI_DEVICENAME, IntPtr.Zero, ref size);
        if (size == 0) return "?";
        IntPtr p = Marshal.AllocHGlobal((int)(size * 2));
        try
        {
            GetRawInputDeviceInfo(h, RIDI_DEVICENAME, p, ref size);
            return Marshal.PtrToStringUni(p);
        }
        finally { Marshal.FreeHGlobal(p); }
    }

    static string ShortDev(string d)
    {
        if (d == null) return "?";
        int i = d.LastIndexOf('#');
        if (i >= 0 && i + 1 < d.Length) d = d.Substring(i + 1);
        if (d.Length > 60) d = d.Substring(d.Length - 60);
        return d;
    }
}
'@

if ($env:KEYSPY_COMPILE_ONLY -eq '1') {
    'COMPILE_OK'
} else {
    [KeySpyGui]::Run($log)
}
