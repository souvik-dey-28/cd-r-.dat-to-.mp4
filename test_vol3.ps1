$ErrorActionPreference = "Stop"
$ffmpegPath = Resolve-Path ".\ffmpeg-bin\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe"
$env:Path += ";$($ffmpegPath.Path | Split-Path)"

Write-Host "Testing ffmpeg with forced mpeg format on volume 3\combined.dat..."
# We use -f mpeg
& $ffmpegPath.Path -f mpeg -i "volume 3\combined.dat"
