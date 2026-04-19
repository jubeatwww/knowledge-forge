param([Parameter(Mandatory)][string]$Path)
$sig = '[DllImport("winmm.dll", CharSet=CharSet.Auto)] public static extern int mciSendString(string c, System.Text.StringBuilder r, int l, System.IntPtr h);'
$m = Add-Type -MemberDefinition $sig -Name WinMM -Namespace Win32 -PassThru
$alias = "snd_$([guid]::NewGuid().ToString('N'))"
$r1 = $m::mciSendString("open `"$Path`" type mpegvideo alias $alias", $null, 0, [System.IntPtr]::Zero)
$r2 = $m::mciSendString("play $alias wait", $null, 0, [System.IntPtr]::Zero)
$r3 = $m::mciSendString("close $alias", $null, 0, [System.IntPtr]::Zero)