using System;
using System.Runtime.InteropServices;

public class Taskbar
{
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern IntPtr FindWindow(
    string lpClassName,
    string lpWindowName);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);

    public static bool IsTaskbarLoaded()
    {
        var taskbarHandle = FindWindow("Shell_traywnd", "");
        var startButtonHandle = FindWindowEx(taskbarHandle, IntPtr.Zero, "Start", null);
        return taskbarHandle != IntPtr.Zero && startButtonHandle != IntPtr.Zero;
    }

    public static IntPtr GetTaskbarHandle()
    {
        var taskbarHandle = FindWindow("Shell_traywnd", "");
        var startButtonHandle = FindWindowEx(taskbarHandle, IntPtr.Zero, "Start", null);
        return taskbarHandle;
    }
    public static IntPtr GetTaskbarStartHandle()
    {
        var taskbarHandle = FindWindow("Shell_traywnd", "");
        var startButtonHandle = FindWindowEx(taskbarHandle, IntPtr.Zero, "Start", null);
        return startButtonHandle;
    }
}