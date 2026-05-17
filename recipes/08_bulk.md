# Bulk & Organization Recipes

100 real-world bulk processing, organization, deduplication, and workflow recipes using `conv`.

## TOC
- [Bulk Conversion](#bulk-conversion) — 1–14
- [Deduplication](#deduplication) — 15–26
- [Smart Renaming](#smart-renaming) — 27–44
- [Folder Organization](#folder-organization) — 45–54
- [Cleanup Workflows](#cleanup-workflows) — 55–64
- [Filter Combinations](#filter-combinations) — 65–72
- [Reports & Analytics](#reports--analytics) — 73–80
- [Photo & Media Import Pipelines](#photo--media-import-pipelines) — 81–88
- [Document Organization](#document-organization) — 89–93
- [Combo Workflows](#combo-workflows) — 94–100

---

## Bulk Conversion

### 1. Convert all HEIC to JPEG
**Use case:** iPhone photo import — all at once  
**Command:**
```
convall HEIC jpg ~/Downloads/iPhone_Import/
```

### 2. Convert all PNG to WebP in web project
**Use case:** Optimize entire image directory  
**Command:**
```
convall png webp ./website/images/ --output-dir ./website/images_webp/
```

### 3. Convert all MP4 to WebM in parallel
**Use case:** Batch video format conversion using all cores  
**Command:**
```
convall mp4 webm ./videos/ --parallel 4
```

### 4. Convert all FLAC to MP3 (music library)
**Use case:** Portable copy of lossless library  
**Command:**
```
convall flac mp3 ~/Musik/ --output-dir ~/Musik_MP3/ --recursive
```

### 5. Recursively convert old AVI to MP4
**Use case:** Legacy video archive modernization  
**Command:**
```
convall avi mp4 ~/Videos/ --recursive --output-dir ~/Videos_Modern/
```

### 6. Dry run before bulk conversion
**Use case:** Preview what will be converted  
**Command:**
```
convall jpg webp ./Fotos/ --dry-run
```

### 7. Convert only large files (>10MB)
**Use case:** Only process large images that need optimization  
**Command:**
```
convall jpg webp ./Fotos/ --larger-than 10M
```

### 8. Convert only old files (>1 year)
**Use case:** Archive old formats that haven't been touched  
**Command:**
```
convall avi mp4 ./Archiv/ --older-than 365d
```

### 9. Convert with output to specific directory
**Use case:** Keep originals, output processed files separately  
**Command:**
```
convall tiff jpg ./Scans/ --output-dir ./Scans_JPEG/
```

### 10. Batch convert with 8 parallel workers
**Use case:** Fast machine, maximize throughput  
**Command:**
```
convall mp4 mp4 ./4K_Videos/ --parallel 8 --output-dir ./1080p/
```

### 11. Convert all audio in subdirectory tree
**Use case:** Music library with nested album folders  
**Command:**
```
convall wav mp3 ~/Studio/ --recursive --parallel 4
```

### 12. Convert old WMV/AVI archive
**Use case:** Legacy corporate video archive  
**Command:**
```
convall wmv mp4 ./Unternehmensvideos/ --recursive --output-dir ./Videos_Archiv_Modern/
```

### 13. Batch DOCX to PDF
**Use case:** Entire document library → PDF archive  
**Command:**
```
for f in ./Dokumente/**/*.docx; do libreoffice --headless --convert-to pdf "$f" --outdir ./PDFs/; done
```

### 14. Batch convert only files missing output
**Use case:** Resume interrupted batch  
**Command:**
```
for f in ./source/*.jpg; do
  out="./webp/${f##*/%.jpg}.webp"
  if [ ! -f "$out" ]; then conv "$f" "$out"; fi
done
```

---

## Deduplication

### 15. Find and list duplicates (hash-based)
**Use case:** Identify duplicate files before deciding  
**Command:**
```
conv --dedupe ./Fotos/
```

### 16. Find and delete duplicates automatically
**Use case:** Clean up photo library with confirmed dupes  
**Command:**
```
conv --dedupe ./Fotos/ --delete
```

### 17. Find visually similar images (perceptual hash)
**Use case:** Find near-duplicates (same photo, different JPEG quality)  
**Command:**
```
conv --dedupe ./Fotos/ --similar
```

### 18. Dedupe music library (exact duplicates)
**Use case:** Multiple copies of same MP3  
**Command:**
```
conv --dedupe ~/Musik/ --delete
```

### 19. Dedupe video archive
**Use case:** Duplicated recordings with different names  
**Command:**
```
conv --dedupe ./Videos/ --similar
```

### 20. Dedupe downloads folder
**Use case:** Monthly cleanup — remove accumulated duplicates  
**Command:**
```
conv --dedupe ~/Downloads/ --dry-run
conv --dedupe ~/Downloads/ --delete
```

### 21. Find duplicate PDFs across project folders
**Use case:** Same invoice in multiple locations  
**Command:**
```
conv --dedupe ~/Dokumente/ --recursive
```

### 22. Dedupe and keep newest version
**Use case:** Keep most recent when multiple exist  
**Command:**
```
fdupes -r -N --order=mtime ./Fotos/
```

### 23. Dedupe and keep file in specific location
**Use case:** Master library has canoncial versions  
**Command:**
```
fdupes -L ./Master_Library/ ./Import/
```

### 24. Identify duplicates in two directories
**Use case:** Check if import already exists in library  
**Command:**
```
fdupes -r ./Bibliothek/ ./Neuer_Import/ | head -50
```

### 25. Screenshot detection and dedup
**Use case:** Screenshots mixed with photos — identify and remove  
**Command:**
```
conv --screenshot-detect ./Fotos/
conv --dedupe ./Fotos/ --delete
```

### 26. Dedupe with size report
**Use case:** Know how much space duplicates are taking  
**Command:**
```
fdupes -r -S ~/Downloads/ | tail -5
```

---

## Smart Renaming

### 27. Rename by date (YYYY-MM-DD)
**Use case:** Camera photos with DSC_XXXX names → dates  
**Command:**
```
conv --rename-batch '*.jpg' '{date}.jpg'
```

### 28. Rename with date and sequence
**Use case:** Multiple photos per day, sorted  
**Command:**
```
conv --rename-batch '*.jpg' '{year}-{month}-{day}_{seq:3}.jpg'
```

### 29. Rename with original name preserved
**Use case:** Add date prefix to existing names  
**Command:**
```
conv --rename-batch '*.pdf' '{date}_{name}.pdf'
```

### 30. Rename by year-month folder structure
**Use case:** Invoice PDFs → 2026-04_Rechnung.pdf  
**Command:**
```
conv --rename-batch 'Rechnung*.pdf' '{year}-{month}_{name}.pdf'
```

### 31. Rename video files with sequence
**Use case:** Lecture series sequential naming  
**Command:**
```
conv --rename-batch '*.mp4' 'Vorlesung_{seq:2}_{name}.mp4'
```

### 32. Rename by extension (add date to all)
**Use case:** Mixed file types all get date prefix  
**Command:**
```
conv --rename-batch '*.*' '{date}_{name}.{ext}'
```

### 33. Batch rename with year only
**Use case:** Annual reports → simple year prefix  
**Command:**
```
conv --rename-batch 'Bericht*.pdf' '{year}_{name}.pdf'
```

### 34. Rename screenshots by date+seq
**Use case:** Screenshot_2026-XX → Screenshot_2026-04-17_001  
**Command:**
```
conv --rename-batch 'Screenshot*.png' 'Screenshot_{date}_{seq:3}.png'
```

### 35. Rename camera files by model+date
**Use case:** Multi-camera shoot identification  
**Command:**
```
exiftool '-FileName<${Model}_${DateTimeOriginal}' -d "%Y%m%d_%H%M%S.%%e" ./Shooting/
```

### 36. Lowercase all filenames
**Use case:** Server case-sensitivity issue  
**Command:**
```
for f in *; do mv "$f" "$(echo $f | tr '[:upper:]' '[:lower:]')"; done
```

### 37. Replace spaces with underscores
**Use case:** Filenames with spaces break shell scripts  
**Command:**
```
for f in *\ *; do mv "$f" "${f// /_}"; done
```

### 38. Remove special characters from filenames
**Use case:** macOS filenames with colons, slashes  
**Command:**
```
for f in *; do mv "$f" "$(echo "$f" | tr -d '/:*?"<>|')"; done
```

### 39. Add prefix to all files matching pattern
**Use case:** Mark files for processing  
**Command:**
```
for f in *.jpg; do mv "$f" "processed_${f}"; done
```

### 40. Remove prefix from files
**Use case:** Clean up after batch processing  
**Command:**
```
for f in processed_*.jpg; do mv "$f" "${f#processed_}"; done
```

### 41. Rename based on file content (PDF title)
**Use case:** PDF with generic name — rename from title metadata  
**Command:**
```
for f in *.pdf; do
  title=$(exiftool -s3 -Title "$f" | tr ' ' '_' | tr -cd '[:alnum:]_')
  if [ -n "$title" ]; then mv "$f" "${title}.pdf"; fi
done
```

### 42. Rename audio by ID3 tags
**Use case:** Generic track names → Artist_Title.mp3  
**Command:**
```
exiftool '-FileName<${Artist}_${Title}.%e' *.mp3
```

### 43. Batch rename with counter reset per folder
**Use case:** Folder-based sequential naming  
**Command:**
```
for dir in ./Albums/*/; do
  i=1
  for f in "$dir"*.jpg; do
    mv "$f" "${dir}photo_$(printf '%03d' $i).jpg"
    ((i++))
  done
done
```

### 44. Rename by file hash (fingerprint-based names)
**Use case:** Content-addressable storage  
**Command:**
```
for f in *.jpg; do
  hash=$(sha256sum "$f" | cut -c1-12)
  mv "$f" "${hash}.jpg"
done
```

---

## Folder Organization

### 45. Sort files by type into subfolders
**Use case:** Downloads folder chaos → organized  
**Command:**
```
conv --sort-type ~/Downloads/
```

### 46. Sort files by date into year/month folders
**Use case:** Photo library flat → YYYY/MM structure  
**Command:**
```
conv --sort-date ~/Pictures/
```

### 47. Move old files to archive folder
**Use case:** Files >1 year → ./Archiv/  
**Command:**
```
find ./Projekte/ -mtime +365 -exec mv {} ./Archiv/ \;
```

### 48. Organize music by Artist/Album
**Use case:** Flat music folder → proper hierarchy  
**Command:**
```
beet move
```

### 49. Create YYYY/MM/DD folder structure for photos
**Use case:** Day-level organization for large shoots  
**Command:**
```
exiftool -r '-Directory<DateTimeOriginal' -d "%Y/%m/%d" ./Fotos_flat/
```

### 50. Move videos by resolution to subfolders
**Use case:** Separate 4K, 1080p, 720p  
**Command:**
```
for f in *.mp4; do
  height=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f")
  mkdir -p "${height}p" && mv "$f" "${height}p/"
done
```

### 51. Sort downloads by file type
**Use case:** Monthly cleanup of Downloads folder  
**Command:**
```
cd ~/Downloads
for ext in pdf jpg png mp4 zip docx xlsx; do
  mkdir -p "$ext"
  mv *.$ext "$ext/" 2>/dev/null
done
```

### 52. Remove empty directories
**Use case:** After file moves, clean up empty folders  
**Command:**
```
conv --remove-empty ./Projekte/
```

### 53. Sort by camera (using EXIF model)
**Use case:** Multi-camera shoot → separate by device  
**Command:**
```
exiftool '-Directory<${Model}' -d "%Y%m%d" ./Shoot/ 2>/dev/null
```

### 54. Organize by GPS city (geocode from EXIF)
**Use case:** Travel photos → city-named folders  
**Command:**
```
exiftool -if '$GPSLatitude' -Directory<GPSCity ./Reisefotos/ 2>/dev/null || true
```

---

## Cleanup Workflows

### 55. Find and remove duplicate screenshots
**Use case:** Cmd+Shift+4 abuse → hundreds of duplicates  
**Command:**
```
conv --screenshot-detect ~/Desktop/
conv --dedupe ~/Desktop/ --delete
```

### 56. Remove empty files
**Use case:** Partial downloads, 0-byte failed saves  
**Command:**
```
find ~/Downloads/ -empty -delete
```

### 57. Clean up DS_Store files (macOS)
**Use case:** Remove macOS metadata before ZIP for Windows  
**Command:**
```
find . -name ".DS_Store" -delete
find . -name "__MACOSX" -type d -exec rm -rf {} +
```

### 58. Remove duplicate downloads (same name, different hash)
**Use case:** Multiple downloads of same file  
**Command:**
```
conv --dedupe ~/Downloads/ --similar
```

### 59. Delete files larger than 1GB (free space)
**Use case:** Emergency disk cleanup  
**Command:**
```
convall mp4 mp4 ~/Videos/ --larger-than 1G --dry-run
find ~/Videos/ -size +1G -name "*.mp4"
```

### 60. Delete old temp files
**Use case:** Temp folder cleanup  
**Command:**
```
find /tmp/ -mtime +7 -delete
find ~/.cache/ -mtime +30 -exec rm -rf {} + 2>/dev/null
```

### 61. Remove all .log files older than 30 days
**Use case:** Server log rotation  
**Command:**
```
find /var/log/ -name "*.log" -mtime +30 -delete
```

### 62. Clean up node_modules from old projects
**Use case:** Free up disk space  
**Command:**
```
find ~/Projekte/ -name "node_modules" -type d -mtime +90 -exec rm -rf {} + 2>/dev/null
```

### 63. Remove .bak and .tmp files
**Use case:** Editor leftover cleanup  
**Command:**
```
find ~/Dokumente/ \( -name "*.bak" -o -name "*.tmp" -o -name "*~" \) -delete
```

### 64. Clean up screenshot clutter from Desktop
**Use case:** Desktop screenshot hygiene  
**Command:**
```
mkdir -p ~/Pictures/Screenshots
find ~/Desktop/ -name "Screenshot*.png" -newer ~/Pictures/Screenshots -exec mv {} ~/Pictures/Screenshots/ \;
conv --dedupe ~/Pictures/Screenshots/ --delete
```

---

## Filter Combinations

### 65. Convert only large old files
**Use case:** Transcode archive — large files older than 2 years  
**Command:**
```
convall avi mp4 ./Archiv/ --older-than 730d --larger-than 500M
```

### 66. Convert only recent files
**Use case:** Process only this month's photos  
**Command:**
```
find ./Fotos/ -mtime -30 -name "*.jpg" | xargs -I{} conv {} {}_webp.webp
```

### 67. Batch convert small images only
**Use case:** Optimize tiny placeholder images  
**Command:**
```
find ./web/ -name "*.png" -size -100k | xargs -I{} conv {} {%.png}.webp
```

### 68. Process files from specific date range
**Use case:** Just this year's photos  
**Command:**
```
find ./Fotos/ -newer 2026-01-01 -not -newer 2027-01-01 -name "*.jpg" | wc -l
```

### 69. Convert only files not yet converted (no output)
**Use case:** Resume interrupted batch — skip done files  
**Command:**
```
for f in ./source/*.mp4; do
  out="./output/$(basename ${f%.mp4}).webm"
  [ ! -f "$out" ] && conv "$f" "$out"
done
```

### 70. Parallel batch with progress
**Use case:** Fast batch with real-time progress  
**Command:**
```
ls *.jpg | parallel --bar conv {} webp/{.}.webp
```

### 71. Filter by content (video duration > 10min)
**Use case:** Find and batch long videos for compression  
**Command:**
```
for f in *.mp4; do
  dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$f")
  if (( $(echo "$dur > 600" | bc) )); then echo "$f: ${dur}s"; fi
done
```

### 72. Batch process with error logging
**Use case:** Large batch — capture failures  
**Command:**
```
for f in ./source/*.avi; do
  conv "$f" "./output/${f##*/%.avi}.mp4" || echo "FAILED: $f" >> errors.log
done
```

---

## Reports & Analytics

### 73. Full directory report
**Use case:** Understand folder composition before processing  
**Command:**
```
conv --report ~/Downloads/
```

### 74. Format statistics
**Use case:** What file types are in my media library?  
**Command:**
```
conv --format-stats ~/Medien/
```

### 75. Age report (find old files)
**Use case:** Identify files for archiving  
**Command:**
```
conv --age-report ~/Projekte/
```

### 76. Disk usage by file type
**Use case:** Which file type is eating most disk space?  
**Command:**
```
find ~/Medien/ -type f | awk -F. '{print $NF}' | sort | uniq | while read ext; do
  total=$(find ~/Medien/ -name "*.$ext" -exec du -sk {} + | awk '{sum+=$1} END{print sum}')
  echo "$ext: ${total}KB"
done | sort -t: -k2 -rn | head -10
```

### 77. Count files by type
**Use case:** Quick inventory  
**Command:**
```
find ~/Fotos/ -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

### 78. Find largest files in library
**Use case:** Quick disk space recovery  
**Command:**
```
find ~/Videos/ -type f -size +500M -exec du -sh {} \; | sort -rh | head -20
```

### 79. Report on unconverted old formats
**Use case:** Migration planning  
**Command:**
```
find ~/Archiv/ \( -name "*.avi" -o -name "*.wmv" -o -name "*.flv" \) | wc -l
```

### 80. Generate file inventory CSV
**Use case:** Asset management, client delivery  
**Command:**
```
find ./Projekt/ -type f -exec stat -f "%N,%z,%Sm" -t "%Y-%m-%d" {} \; > inventory.csv
```

---

## Photo & Media Import Pipelines

### 81. iPhone import → convert → organize → dedupe
**Use case:** Monthly iPhone photo import  
**Command:**
```
convall HEIC jpg /Volumes/iPhone/DCIM/ --output-dir ~/Pictures/Import_temp/
conv --sort-date ~/Pictures/Import_temp/
conv --dedupe ~/Pictures/Library/ --similar
```

### 82. Camera SD card → RAW backup → JPEG → organize
**Use case:** Photo shoot import workflow  
**Command:**
```
rsync -av /Volumes/SD_CARD/DCIM/ ~/Pictures/RAW_Backup/
convall CR2 jpg ~/Pictures/RAW_Backup/ --output-dir ~/Pictures/JPEG/
exiftool -r '-Directory<DateTimeOriginal' -d "%Y/%m" ~/Pictures/JPEG/
```

### 83. Video import → transcode → thumbnail → organize
**Use case:** GoPro footage import pipeline  
**Command:**
```
convall MP4 mp4 /Volumes/GoPro/ --output-dir ~/Videos/GoPro_1080p/
for f in ~/Videos/GoPro_1080p/*.mp4; do
  conv --thumbnail "$f" "~/Videos/GoPro_thumbs/${f##*/%.mp4}.jpg"
done
conv --sort-date ~/Videos/GoPro_1080p/
```

### 84. Download folder → classify → move to right folder
**Use case:** Weekly download cleanup  
**Command:**
```
conv --sort-type ~/Downloads/
conv --dedupe ~/Downloads/ --delete
conv --remove-empty ~/Downloads/
```

### 85. Music download → tag → organize → dedupe
**Use case:** Add new music to library  
**Command:**
```
# Auto-tag using beets
beet import ~/Downloads/Neue_Musik/
# Dedupe against existing library
conv --dedupe ~/Musik/ --similar
```

### 86. Podcast sync → transcode → tag → organize
**Use case:** Podcast archive for offline player  
**Command:**
```
convall m4a mp3 ~/Podcasts/Download/ --output-dir ~/Podcasts/MP3/
for f in ~/Podcasts/MP3/*.mp3; do conv --normalize "$f" "$f" --target -16; done
conv --sort-date ~/Podcasts/MP3/
```

### 87. Screenshot cleanup → dedupe → rename → organize
**Use case:** Tame the screenshot chaos  
**Command:**
```
conv --screenshot-detect ~/Desktop/
conv --dedupe ~/Desktop/ --delete
conv --rename-batch '~/Desktop/Screenshot*.png' 'Screenshot_{date}_{seq:3}.png'
mv ~/Desktop/Screenshot_*.png ~/Pictures/Screenshots/
```

### 88. Video archive transcode (old formats → H264)
**Use case:** Family archive modernization  
**Command:**
```
convall avi mp4 ~/Videos/Familie/ --recursive --older-than 730d --output-dir ~/Videos/Familie_Modern/
convall wmv mp4 ~/Videos/Familie/ --recursive --older-than 730d --output-dir ~/Videos/Familie_Modern/
conv --dedupe ~/Videos/Familie_Modern/ --delete
```

---

## Document Organization

### 89. Receipts → OCR → rename by date → organize
**Use case:** Paper receipts → searchable archive  
**Command:**
```
for f in ~/Scans/Receipts/*.pdf; do
  conv --pdf-ocr "$f" "~/Dokumente/Rechnungen/${f##*/}" --lang deu
done
conv --rename-batch '~/Dokumente/Rechnungen/*.pdf' '{date}_{name}.pdf'
conv --sort-date ~/Dokumente/Rechnungen/
```

### 90. Contract management → rename → organize → archive
**Use case:** Annual contract organization  
**Command:**
```
conv --rename-batch '~/Dokumente/Vertraege/*.pdf' '{year}_{name}.pdf'
find ~/Dokumente/Vertraege/ -name "2024_*.pdf" -exec mv {} ~/Archiv/Vertraege_2024/ \;
conv --pdf-merge ~/Archiv/Vertraege_2024/*.pdf Vertraege_2024_gesamt.pdf
```

### 91. Tax documents → organize by year → compress → archive
**Use case:** Tax season document management  
**Command:**
```
mkdir -p ~/Steuer/2026
find ~/Dokumente/ -name "*Steuer*2026*" -o -name "*Rechnung*2026*" | xargs -I{} cp {} ~/Steuer/2026/
conv --pdf-merge ~/Steuer/2026/*.pdf ~/Steuer/2026/Alle_Steuerdokumente_2026.pdf
```

### 92. Email attachment cleanup → dedupe → organize
**Use case:** Downloads folder full of email attachments  
**Command:**
```
conv --sort-type ~/Downloads/
conv --dedupe ~/Downloads/ --delete
find ~/Downloads/ -mtime +90 -not -name "*.pdf" -delete
```

### 93. GDPR deletion audit — find files with PII
**Use case:** Verify no personal data remains  
**Command:**
```
pdfgrep -r "Vorname\|Nachname\|Geburtsdatum\|Personalausweis" ~/Archiv/ > pii_audit.txt
```

---

## Combo Workflows

### 94. Full Photo Library Maintenance (monthly)
**Use case:** Complete photo library hygiene routine  
**Command:**
```
# Import
convall HEIC jpg ~/Pictures/Inbox/ --output-dir ~/Pictures/Library/
# Auto-rotate
for f in ~/Pictures/Library/*.jpg; do conv --auto-rotate "$f" "$f"; done
# Organize by date
exiftool -r '-Directory<DateTimeOriginal' -d "%Y/%m" ~/Pictures/Library/
# Deduplicate
conv --dedupe ~/Pictures/Library/ --delete
# Report
conv --report ~/Pictures/Library/
```

### 95. Music Library Full Audit + Cleanup
**Use case:** Music library maintenance pipeline  
**Command:**
```
# Find untagged
for f in ~/Musik/**/*.mp3; do
  [ -z "$(exiftool -s3 -Artist "$f")" ] && echo "$f" >> untagged.txt
done
# Dedupe
conv --dedupe ~/Musik/ --delete
# Normalize loudness on all
find ~/Musik/ -name "*.mp3" | xargs -P4 -I{} conv --normalize {} {} --target -14
# Report
conv --format-stats ~/Musik/
```

### 96. Download → Sort → Dedupe → Archive Old
**Use case:** Weekly download folder hygiene  
**Command:**
```
conv --sort-type ~/Downloads/
conv --dedupe ~/Downloads/ --delete
conv --remove-empty ~/Downloads/
find ~/Downloads/ -mtime +60 -type f | tar -czf "Downloads_Archive_$(date +%Y-%m).tar.gz" -T - --remove-files
```

### 97. Video Archive: Transcode → Thumbnail Grid → Report
**Use case:** Digitize and catalog family video archive  
**Command:**
```
convall avi mp4 ~/Familie_Videos/ --recursive --output-dir ~/Familie_Videos_Modern/ --parallel 4
for f in ~/Familie_Videos_Modern/*.mp4; do
  conv --thumbnail-grid "$f" "~/Familie_Thumbnails/${f##*/%.mp4}_grid.jpg"
done
conv --report ~/Familie_Videos_Modern/
conv --age-report ~/Familie_Videos_Modern/
```

### 98. Pre-Archive Filter → Compress → Verify → Cold Store
**Use case:** Year-end full archive before cold storage  
**Command:**
```
# Remove duplicates
conv --dedupe ~/Projekte_2025/ --delete
conv --remove-empty ~/Projekte_2025/
# Report before archive
conv --report ~/Projekte_2025/ > Projekte_2025_report.txt
# Archive
tar -czf "Projekte_2025.tar.gz" ~/Projekte_2025/
sha256sum Projekte_2025.tar.gz > Projekte_2025.sha256
# Verify
7z t Projekte_2025.tar.gz && echo "Archive verified OK"
```

### 99. Multi-Step Photo Delivery Pipeline
**Use case:** Client photo delivery — clean, organized, optimized  
**Command:**
```
# Strip metadata
for f in ./Shooting/*.jpg; do conv --strip-exif "$f" "delivery/${f##*/}"; done
# Resize for web delivery
for f in ./delivery/*.jpg; do resize "$f" 2400; done
# Optimize
optall ./delivery/
# Rename systematically
conv --rename-batch './delivery/*.jpg' '{seq:4}_{name}.jpg'
# Final report
conv --report ./delivery/
echo "Delivery: $(ls delivery/ | wc -l) files, $(du -sh delivery/ | cut -f1)"
```

### 100. Complete Media Ingest → Process → Organize → Archive
**Use case:** Full production media management pipeline  
**Command:**
```
SOURCE="/Volumes/SD_CARD"
LIBRARY="$HOME/Media_Library"
DATE=$(date +%Y-%m-%d)

# 1. Import raw files
rsync -av "$SOURCE/" "$LIBRARY/Inbox/$DATE/"

# 2. Convert to standard formats
convall CR2 jpg "$LIBRARY/Inbox/$DATE/" --output-dir "$LIBRARY/Photos/$DATE/"
convall MP4 mp4 "$LIBRARY/Inbox/$DATE/" --output-dir "$LIBRARY/Videos/$DATE/"

# 3. Generate thumbnails
for f in "$LIBRARY/Videos/$DATE/"*.mp4; do
  conv --thumbnail "$f" "$LIBRARY/Thumbnails/${f##*/%.mp4}.jpg"
done

# 4. Deduplicate
conv --dedupe "$LIBRARY/Photos/" --similar
conv --dedupe "$LIBRARY/Videos/" --delete

# 5. Organize
exiftool -r '-Directory<DateTimeOriginal' -d "%Y/%m" "$LIBRARY/Photos/"

# 6. Report
conv --report "$LIBRARY/" > "$LIBRARY/Reports/ingest_$DATE.txt"

echo "Ingest complete: $DATE"
```
