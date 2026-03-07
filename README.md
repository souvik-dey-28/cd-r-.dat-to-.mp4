# VCD to MP4 Conversion Guide

This document explains the process used to convert the contents of 3 Video CDs (VCDs) to a single MP4 file per volume. 

This process is designed to handle older VCD formats where the video data is split into multiple `.DAT` files within an `MPEGAV` directory, which is a common structure for older media.

## Prerequisites
1. **FFmpeg**: The industry standard utility for video processing.
2. **PowerShell**: To execute the automated conversion scripts.

## Step 1: Directory Structure Preparation
The files from the CDs were copied into a specific directory structure. For each CD, a folder was created (e.g., `volume 1`, `volume 2`, `volume 3`). Inside each of these folders, the original `MPEGAV` folder from the CD was placed, which contained the actual `.DAT` video files.

Example of the tree structure:
```
d:\11111111111111111111111 antrigrvity\
 ├── volume 1\
 │    └── MPEGAV\
 │         ├── AVSEQ01.DAT
 │         └── AVSEQ02.DAT
 ├── volume 2\
 │    └── MPEGAV\
 │         ├── AVSEQ01.DAT
 │         └── ...
 └── volume 3\
      └── MPEGAV\
           └── ...
```

## Step 2: FFmpeg Setup
FFmpeg was downloaded and extracted into a local directory (`ffmpeg-bin`). The executable paths were added to the PowerShell `$env:Path` temporarily during script execution so that `ffmpeg.exe` and `ffprobe.exe` could be called effortlessly.

## Step 3: Script Execution and Video Concatenation
Two main scripts were used to process the files depending on the nature of the VCD structure:

### Method A: FFmpeg Concat Demuxer (`convert.ps1`)
Used successfully for **Volume 1** and **Volume 2**.
1. The script automatically scans the `MPEGAV` directory within a volume.
2. It lists all `.DAT` files in alphabetical order.
3. It generates a temporary text file (`concat_list.txt`) formatted for FFmpeg's concat demuxer (e.g., `file 'MPEGAV/AVSEQ01.DAT'`).
4. It calls FFmpeg to concatenate the files gaplessly and encodes them using H.264 video codec and AAC audio codec for high compatibility.
   ```powershell
   ffmpeg -y -f concat -safe 0 -i "concat_list.txt" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k "volume_1.mp4"
   ```

### Method B: Binary Copy + Forced MPEG Format (`vol3.ps1`)
Used for **Volume 3** where FFmpeg had trouble automatically correctly parsing the headers of the individual `.DAT` segments through the concat demuxer.
1. The script manually concatenates all the binary `.DAT` files into one large `.dat` file using the Windows `copy /b` command.
   ```powershell
   cmd /c copy /b "AVSEQ01.DAT" + "AVSEQ02.DAT" + ... "combined.dat"
   ```
2. FFmpeg is then invoked explicitly forcing the input format to `mpeg` (`-f mpeg`) on the combined file, bypassing the need for probing individual segment headers.
   ```powershell
   ffmpeg -y -f mpeg -i "combined.dat" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k "volume_3.mp4"
   ```

## Step 4: Verification (Checking Video Lengths)
To ensure no scenes were dropped or shortened during the joining process, we used `ffprobe` to sum up the durations of the original `.DAT` files and cross-referenced them against the final merged `.mp4` files. We wrote a PowerShell script loop that calculates the sum of all durations in the `MPEGAV` directory and compares it to the output file.

```powershell
# Get duration of a single file in seconds
$duration = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "video.mp4"
```
By comparing the summed lengths, we guarantee frame-accurate concatenations!

## Final Output
The generated output files are standard `.mp4` containers (`volume_1.mp4`, `volume_2.mp4`, `volume_3.mp4`) located in the root directory. They are verified to have their full durations and are perfectly compatible with any USB Pendrive and Smart TV.
