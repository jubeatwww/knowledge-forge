param([Parameter(Mandatory)][string]$Path)
# WPF MediaPlayer (via PresentationCore) handles the MP3 variants that the
# older MCI `mpegvideo` driver rejects with error 277 on open — notably
# higher-bitrate / longer clips. We poll NaturalDuration to learn the clip
# length, then sleep synchronously so the process outlives playback.
Add-Type -AssemblyName PresentationCore
$mp = New-Object System.Windows.Media.MediaPlayer
$mp.Open([Uri]::new($Path))
$deadline = (Get-Date).AddSeconds(3)
while (-not $mp.NaturalDuration.HasTimeSpan -and (Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 20
}
if (-not $mp.NaturalDuration.HasTimeSpan) {
  Write-Error "failed to load: $Path"
  exit 1
}
$mp.Play()
Start-Sleep -Milliseconds ([int]($mp.NaturalDuration.TimeSpan.TotalMilliseconds + 200))
$mp.Close()