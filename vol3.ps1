$ErrorActionPreference = "Stop"
$ffmpegPath = Resolve-Path ".\ffmpeg-bin\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe"
$env:Path += ";$($ffmpegPath.Path | Split-Path)"

Write-Host "Processing volume 3..."
$vol = "volume 3"
$baseDir = Get-Location

$output_file = "$($vol -replace ' ', '_').mp4"
$final_output_path = Join-Path -Path $baseDir -ChildPath $output_file

if (Test-Path $final_output_path) {
    Write-Host "$final_output_path already exists. Exiting."
    exit
}

$combined_path = Join-Path -Path $vol -ChildPath "combined.dat"
if (-Not (Test-Path $combined_path)) {
    Write-Host "combined.dat not found!"
    exit
}

Write-Host "Running ffmpeg for $vol..."
$cmdArgs = "-y -f mpeg -i `"$($baseDir.Path)\$vol\combined.dat`" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k `"$final_output_path`""

$process = Start-Process -FilePath $ffmpegPath.Path -ArgumentList $cmdArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0 -and (Test-Path $final_output_path)) {
    Write-Host "$vol conversion completed successfully to $final_output_path."
    Remove-Item -Path $combined_path -Force
} else {
    Write-Host "$vol conversion failed with exit code $($process.ExitCode)."
}

Write-Host "All done!"
