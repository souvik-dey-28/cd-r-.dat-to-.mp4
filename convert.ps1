$ErrorActionPreference = "Stop"
$ffmpegPath = Resolve-Path ".\ffmpeg-bin\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe"
$env:Path += ";$($ffmpegPath.Path | Split-Path)"

$volumes = @("volume 1", "volume 2", "volume 3")
$baseDir = Get-Location

foreach ($vol in $volumes) {
    Write-Host "Processing $vol..."
    Set-Location -Path $baseDir
    $mpegav_dir = Join-Path -Path $vol -ChildPath "MPEGAV"
    
    if (Test-Path $mpegav_dir) {
        $output_file = "$($vol -replace ' ', '_').mp4"
        $final_output_path = Join-Path -Path $baseDir -ChildPath $output_file
        
        if (Test-Path $final_output_path) {
            Write-Host "$final_output_path already exists. Skipping..."
            continue
        }
        
        # Check if the file is stuck in the volume dir from a previous failed run
        $temp_output_path = Join-Path -Path $vol -ChildPath $output_file
        if (Test-Path $temp_output_path) {
            Write-Host "Found existing file in $vol, moving to root..."
            try {
                Move-Item -Path $temp_output_path -Destination $final_output_path -Force
                Write-Host "Successfully moved."
                continue
            } catch {
                Write-Host "Could not move file, will recreate it."
            }
        }

        $dat_files = Get-ChildItem -Path $mpegav_dir -Filter "*.DAT" | Sort-Object Name
        
        # Change directory to $vol to run ffmpeg
        Set-Location -Path $vol
        
        $concat_content = ""
        foreach ($file in $dat_files) {
            $concat_content += "file 'MPEGAV/$($file.Name)'`r`n"
        }
        
        [System.IO.File]::WriteAllText("$PWD\concat_list.txt", $concat_content)
        
        Write-Host "Running ffmpeg for $vol..."
        # We output directly to the base directory so we don't have to move it
        $cmdArgs = "-y -f concat -safe 0 -i `"concat_list.txt`" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k `"$final_output_path`""
        
        $process = Start-Process -FilePath $ffmpegPath.Path -ArgumentList $cmdArgs -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0 -and (Test-Path $final_output_path)) {
            Write-Host "$vol conversion completed successfully to $final_output_path."
            Remove-Item -Path "concat_list.txt" -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "$vol conversion failed with exit code $($process.ExitCode)."
        }
    } else {
        Write-Host "Directory $mpegav_dir not found."
    }
}

Set-Location -Path $baseDir
Write-Host "All done!"
