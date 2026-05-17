# 100 Recipes — Universal Media Converter

Typical real-world use cases per category. Each recipe is one command (copy-paste ready).

---

## 🎬 VIDEO (20)

### 1. iPhone MOV → web-ready MP4
```bash
conv IMG_1234.mov web.mp4
```

### 2. 4K → 1080p for editing
```bash
ffmpeg -i 4k.mp4 -vf scale=1920:1080 -c:v h264_videotoolbox -b:v 15M 1080p.mp4
```

### 3. Screen recording → compressed MP4 (share-ready)
```bash
conv recording.mov small.mp4     # auto-bitrate from hardware tier
```

### 4. Video → HEVC (half the size)
```bash
conv input.mp4 output.mkv         # hevc_videotoolbox
```

### 5. Video → WebM (AV1) for web
```bash
conv input.mp4 web.webm
```

### 6. Extract 10-second clip, no re-encode
```bash
conv --trim video.mp4 00:01:30 00:01:40 clip.mp4
```

### 7. Join YouTube chapter clips
```bash
conv --concat full.mp4 ch01.mp4 ch02.mp4 ch03.mp4
```

### 8. Split long video into 5-minute chunks
```bash
conv --split long.mp4 00:05:00
```

### 9. Extract MP3 audio from video
```bash
conv --extract-audio video.mp4 mp3
```

### 10. Contact sheet of video (16-frame thumbnail grid)
```bash
conv --thumbnail video.mp4 4       # 4 columns
```

### 11. Single frame at timestamp
```bash
conv --frame video.mp4 00:00:42    # → video_frame.jpg
```

### 12. HDR → SDR for older devices
```bash
conv --hdr-sdr hdr_video.mp4 sdr.mp4
```

### 13. Video → high-quality GIF
```bash
conv meme.mp4 meme.gif             # gifski (RAM≥64GB)
```

### 14. Burn subtitles into video
```bash
conv --subtitle-burn video.mp4 subs.srt subbed.mp4
```

### 15. Extract embedded subtitles
```bash
conv --subtitle-extract video.mkv
```

### 16. Probe video specs (codec, bitrate, HDR, etc.)
```bash
conv --probe mystery.mov
```

### 17. Batch: all .mov in Downloads → .mp4
```bash
convall mov mp4 ~/Downloads --parallel 8
```

### 18. Only convert videos bigger than 500MB
```bash
convall mkv mp4 . --larger-than 500M
```

### 19. Recursive convert with preview first
```bash
convall mov mp4 ~/Videos --recursive --dry-run
```

### 20. MKV → MP4 remux (no re-encode if H264)
```bash
conv input.mkv output.mp4          # auto-detects copy codec
```

---

## 🎵 AUDIO (12)

### 21. WAV → MP3 V2 (voice/podcast)
```bash
conv recording.wav episode.mp3
```

### 22. WAV → Opus (smallest, best quality)
```bash
conv master.wav optimized.opus
```

### 23. FLAC library → MP3 320k
```bash
convall flac mp3 ~/Music --recursive --parallel 12
```

### 24. Loudness-normalize podcast (EBU R128 -16 LUFS)
```bash
conv --normalize episode_*.wav
```

### 25. Split recording on silence
```bash
conv --split-silence interview.wav   # → interview_part_001.mp3 etc.
```

### 26. Waveform PNG for social media
```bash
conv --waveform song.mp3 waveform.png
```

### 27. Set ID3 tags
```bash
conv --id3 song.mp3 --artist "Max" --title "Track 1" --album "Album" --year 2026
```

### 28. Embed album art
```bash
conv --id3 song.mp3 --cover cover.jpg
```

### 29. Extract audio from 50 videos → mp3 library
```bash
for f in *.mp4; do conv --extract-audio "$f" mp3; done
```

### 30. Video podcast → audio-only MP3
```bash
conv --extract-audio podcast.mp4 mp3
```

### 31. Hi-res FLAC → AAC for iPhone
```bash
conv track.flac track.m4a
```

### 32. Bulk normalize entire folder
```bash
for f in ~/Podcast/*.mp3; do conv --normalize "$f"; done
```

---

## 🖼️ IMAGE (15)

### 33. iPhone HEIC → JPG (bulk)
```bash
convall heic jpg ~/Pictures/iPhone
```

### 34. Web optimization: resize to 1920px
```bash
resize photo.jpg 1920
```

### 35. JPEG → AVIF (50% smaller)
```bash
conv photo.jpg photo.avif
```

### 36. PNG → JXL (up to 98% smaller, lossless)
```bash
conv logo.png logo.jxl
```

### 37. Optimize PNG + JPEG in-place
```bash
optimg *.png *.jpg
```

### 38. Parallel optimize entire photo folder
```bash
optall ~/Photos/2025
```

### 39. Strip EXIF for privacy (bulk)
```bash
conv --strip-exif *.jpg
```

### 40. Auto-rotate sideways photos
```bash
conv --auto-rotate ~/Pictures/*.jpg
```

### 41. Crop region (magick geometry)
```bash
conv --crop photo.jpg 800x600+100+50
```

### 42. DPI audit for print
```bash
conv --dpi-check *.jpg
```

### 43. Set metadata DPI to 300 (no resample)
```bash
conv --dpi-set flyer.jpg 300
```

### 44. Upscale for 100mm poster at 300 DPI
```bash
conv --upscale small.jpg 300 100
```

### 45. Print-ready batch (CMYK + 300 DPI + flatten)
```bash
conv --print-ready design1.jpg design2.jpg
```

### 46. Contact sheet of all images in folder
```bash
conv --thumbnail-grid ~/Photos/event
```

### 47. Big poster → 6-tile split for A4 printing
```bash
conv --poster-split map.jpg 2 3
```

---

## 📄 PDF (15)

### 48. Merge multiple PDFs
```bash
conv --pdf-merge combined.pdf chapter1.pdf chapter2.pdf chapter3.pdf
```

### 49. Split PDF into individual pages
```bash
conv --pdf-split book.pdf
```

### 50. Extract specific page range
```bash
conv --pdf-extract-pages doc.pdf 1-5,8,12-15 extracted.pdf
```

### 51. Rotate PDF 90° clockwise
```bash
conv --pdf-rotate scan.pdf 90
```

### 52. Compress bloated PDF
```bash
conv --pdf-compress huge.pdf
```

### 53. OCR scanned PDF (searchable)
```bash
conv --pdf-ocr scan.pdf deu+eng searchable.pdf
```

### 54. Extract text from PDF
```bash
conv --pdf-text report.pdf > text.txt
```

### 55. Extract all embedded images
```bash
conv --pdf-images catalog.pdf ./images
```

### 56. Resize PDF to A5
```bash
conv --pdf-resize big.pdf a5
```

### 57. 2-up imposition (2 pages per sheet)
```bash
conv --pdf-nup doc.pdf 2 1
```

### 58. 4-up (4 pages per sheet, classroom handout)
```bash
conv --pdf-nup doc.pdf 2 2
```

### 59. Booklet imposition (saddle-stitch)
```bash
conv --pdf-booklet zine.pdf
```

### 60. Markdown → PDF (via pandoc+typst)
```bash
conv manuscript.md book.pdf
```

### 61. PDF info (title, author, pages, version)
```bash
conv --pdf-info document.pdf
```

### 62. PDF preflight (print-readiness check)
```bash
conv --preflight design.pdf
```

---

## 🖨️ PRINT PRODUCTION (12)

### 63. Convert PDF RGB → CMYK for offset
```bash
conv --pdf-cmyk design.pdf cmyk.pdf
```

### 64. Make PDF/X-1a compliant (standard for offset)
```bash
conv --pdf-x design.pdf x1a
```

### 65. PDF/X-3 (Flyeralarm, preserves transparency)
```bash
conv --pdf-x design.pdf x3
```

### 66. Grayscale for laser printer (save toner)
```bash
conv --pdf-gray document.pdf
```

### 67. Add 3mm bleed + crop marks
```bash
conv --pdf-crop-marks flyer.pdf 3
```

### 68. Image → CMYK TIFF for print shop
```bash
conv --img-cmyk photo.jpg photo_cmyk.tif
```

### 69. Business card PDF (front + back, 85×55mm + bleed)
```bash
conv --business-card front.jpg back.jpg card.pdf
```

### 70. One-click: Offset print prep (CMYK + X-1a + preflight)
```bash
conv --print-prep design.pdf offset
```

### 71. One-click: Digital print prep
```bash
conv --print-prep design.pdf digital
```

### 72. One-click: Web preview version
```bash
conv --print-prep design.pdf web
```

### 73. Smart: "Flyer at wirmachendruck" (natural language)
```bash
conv --smart "flyer wirmachendruck" design.pdf
```

### 74. Interactive wizard (full guided flow)
```bash
conv --wizard design.pdf
```

---

## 🎯 METADATA (8)

### 75. Read all EXIF/ID3 tags
```bash
conv --meta-read photo.jpg
```

### 76. Set specific tag
```bash
conv --meta-write photo.jpg "Artist=Max" "Copyright=2026"
```

### 77. Copy metadata from one file to another
```bash
conv --meta-copy original.jpg converted.webp
```

### 78. Strip ALL metadata (privacy)
```bash
conv --meta-strip sensitive.jpg
```

### 79. Backup folder metadata to CSV
```bash
conv --meta-backup ~/Photos/2025 metadata_2025.csv
```

### 80. Sync file mtime with EXIF date
```bash
conv --set-date ~/Photos/iPhone/*.heic
```

### 81. Add GPS + copyright to whole batch
```bash
for f in *.jpg; do conv --meta-write "$f" "GPSLatitude=48.137154" "GPSLongitude=11.576124" "Copyright=2026 Max"; done
```

### 82. Scan QR/barcode in image
```bash
conv --barcode-scan scanned.png
```

---

## 📦 ARCHIVE (5)

### 83. Extract any archive (auto-detects format)
```bash
conv --extract archive.zip
conv --extract backup.tar.gz
conv --extract data.7z
```

### 84. Extract all archives in Downloads
```bash
conv --extract-all ~/Downloads
```

### 85. Compress folder to ZIP
```bash
conv --compress project.zip ./my-project
```

### 86. Split 10GB file into 1GB chunks for upload
```bash
conv --split-file huge.mkv 1G
```

### 87. 7z max compression
```bash
conv --compress backup.7z ~/Documents
```

---

## 📋 BULK & ORGANIZATION (8)

### 88. Find duplicates (hash-based)
```bash
conv --dedupe ~/Downloads
```

### 89. Dedupe + trash duplicates (keep oldest)
```bash
conv --dedupe ~/Downloads --delete
```

### 90. Smart rename by EXIF date
```bash
conv --rename-batch '{year}-{month}-{day}_{seq:3}.{ext}' ~/Photos
```

### 91. Sort mixed folder by type
```bash
conv --sort-type ~/Downloads    # → videos/ images/ audio/ docs/
```

### 92. Sort photos into YYYY/MM folders
```bash
conv --sort-date ~/Photos/2025
```

### 93. Remove empty directories after cleanup
```bash
conv --remove-empty ~/Pictures
```

### 94. Separate screenshots from photos
```bash
conv --screenshot-detect ~/Pictures/iPhone
```

### 95. Batch convert with age filter
```bash
convall mov mp4 ~/Movies --older-than 180d --output-dir ~/archived
```

---

## 📊 REPORTS & QR (5)

### 96. Full media audit of directory
```bash
conv --report ~/Downloads
```

### 97. Files older than 1 year (cleanup candidates)
```bash
conv --age-report ~/Downloads 365
```

### 98. Codec/format distribution
```bash
conv --format-stats ~/Movies
```

### 99. Generate print-ready QR (SVG, vector)
```bash
conv --qr-svg "https://supersynergy.de" qr.svg
```

### 100. QR code with custom size + high ECC
```bash
conv --qr "https://supersynergy.de" big_qr.png 16 H
```

---

## 🔧 Hardware & Help

```bash
conv_info                          # show hardware profile + bitrate tiers
conv --help                        # all 80+ commands
conv --printer-list                # all 50 printer profiles
conv --printer-specs wirmachendruck
conv --analyze <file>              # auto-detect everything about a file
```

---

## Combo Workflows

### Prepare Flyer for Wirmachendruck (full pipeline)
```bash
conv --smart "flyer a5 wirmachendruck" design.pdf
# Auto: analyze → CMYK → A5 resize → 3mm bleed → PDF/X-1a → preflight
```

### Clean up iPhone photo backup
```bash
conv --dedupe ~/iPhone-backup --delete
conv --set-date ~/iPhone-backup/*.heic
convall heic jpg ~/iPhone-backup --parallel 12
conv --rename-batch '{year}-{month}-{day}_{seq:4}.{ext}' ~/iPhone-backup
conv --sort-date ~/iPhone-backup
```

### Produce podcast episode (raw → distro)
```bash
conv --normalize episode_raw.wav
conv episode_raw_norm.wav episode.mp3
conv --id3 episode.mp3 --artist "Max" --title "Ep 42" --album "Podcast"
conv --waveform episode.mp3 waveform.png
```

### Archive project folder before deletion
```bash
conv --dedupe ~/projects/old-project --delete
conv --compress ~/backups/old-project-2026.7z ~/projects/old-project
conv --split-file ~/backups/old-project-2026.7z 2G
```

### Check all PDFs in folder for print-readiness
```bash
for f in *.pdf; do echo "=== $f ==="; conv --preflight "$f"; done
```
