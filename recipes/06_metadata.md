# Metadata & EXIF Recipes

100 real-world metadata reading, writing, stripping, and management recipes using `conv`.

## TOC
- [Read Metadata](#read-metadata) — 1–10
- [Write & Edit Metadata](#write--edit-metadata) — 11–24
- [Strip & Anonymize](#strip--anonymize) — 25–34
- [GPS & Location](#gps--location) — 35–44
- [Date & Time](#date--time) — 45–56
- [Audio ID3 & Tags](#audio-id3--tags) — 57–66
- [PDF & Document Metadata](#pdf--document-metadata) — 67–74
- [Bulk Metadata Operations](#bulk-metadata-operations) — 75–84
- [Metadata Export & Inventory](#metadata-export--inventory) — 85–92
- [Troubleshooting & Detection](#troubleshooting--detection) — 93–96
- [Combo Workflows](#combo-workflows) — 97–100

---

## Read Metadata

### 1. Read all metadata from photo
**Use case:** Inspect before processing  
**Command:**
```
conv --meta-read Foto.jpg
```

### 2. Read EXIF from RAW file
**Use case:** Camera settings for shoot log  
**Command:**
```
exiftool IMG_5678.CR2
```

### 3. Read GPS coordinates from photo
**Use case:** Where was this photo taken?  
**Command:**
```
exiftool -GPSLatitude -GPSLongitude -GPSAltitude Urlaubsfoto.jpg
```

### 4. Read image creation date
**Use case:** Sort photos by capture time  
**Command:**
```
exiftool -DateTimeOriginal photo.jpg
```

### 5. Read camera model info
**Use case:** Which camera took this shot?  
**Command:**
```
exiftool -Make -Model -LensModel photo.jpg
```

### 6. Read all video metadata
**Use case:** Inspect video stream properties  
**Command:**
```
conv --meta-read video.mp4
```

### 7. Read audio file tags
**Use case:** Inspect MP3 tags before editing  
**Command:**
```
conv --meta-read track.mp3
```

### 8. Read PDF metadata
**Use case:** Check author/title before distributing  
**Command:**
```
conv --meta-read Dokument.pdf
```

### 9. Read IPTC keywords
**Use case:** Check stock photo tagging  
**Command:**
```
exiftool -IPTC:Keywords -XMP:Subject photo.jpg
```

### 10. Read all metadata in JSON format
**Use case:** Parse metadata programmatically  
**Command:**
```
exiftool -json photo.jpg > photo_meta.json
```

---

## Write & Edit Metadata

### 11. Write basic metadata
**Use case:** Add info to untagged file  
**Command:**
```
conv --meta-write photo.jpg Copyright="© 2026 Supersynergy" Artist="Maxim"
```

### 12. Write XMP metadata
**Use case:** Stock photo agency requires XMP  
**Command:**
```
exiftool -XMP:Creator="Maxim Supersynergy" -XMP:Rights="© 2026 All Rights Reserved" photo.jpg
```

### 13. Set copyright on multiple fields simultaneously
**Use case:** Full copyright embedding for portfolio  
**Command:**
```
exiftool -Copyright="© 2026 Supersynergy" -IPTC:CopyrightNotice="© 2026 Supersynergy" -XMP:Rights="© 2026 Supersynergy" photo.jpg
```

### 14. Add IPTC caption/description
**Use case:** Stock agency requires image description  
**Command:**
```
exiftool -IPTC:Caption-Abstract="Aerial view of Berlin cityscape at sunset, Germany" photo.jpg
```

### 15. Set IPTC keywords for stock
**Use case:** Tag photo for searchability  
**Command:**
```
exiftool -Keywords="berlin,germany,cityscape,aerial,sunset,urban" photo.jpg
```

### 16. Write video title and description
**Use case:** Tag video file for media library  
**Command:**
```
ffmpeg -i input.mp4 -metadata title="Supersynergy Showreel 2026" -metadata comment="Annual showreel" -c copy tagged.mp4
```

### 17. Write custom metadata field
**Use case:** Internal project ID tracking  
**Command:**
```
conv --meta-write Foto.jpg ProjectID="SS-2026-042" ClientName="Muster GmbH"
```

### 18. Update creator info after rename
**Use case:** Contractor hand-off — add your name  
**Command:**
```
exiftool -Artist="Supersynergy" -Creator="Supersynergy" *.jpg
```

### 19. Set rating/star rating
**Use case:** Mark keeper photos for culling  
**Command:**
```
exiftool -XMP:Rating=5 best_shot.jpg
```

### 20. Write EPUB metadata
**Use case:** Set title/author on EPUB ebook  
**Command:**
```
exiftool -Title="Mein Buch 2026" -Author="Maxim Supersynergy" -Publisher="Supersynergy Verlag" buch.epub
```

### 21. Tag MP4 with chapter info
**Use case:** Video with navigation chapters  
**Command:**
```
ffmpeg -i video.mp4 -metadata:s:v title="Main Video" -metadata title="Tutorial 2026" -c copy tagged.mp4
```

### 22. Set camera serial for ownership proof
**Use case:** Camera registration/theft recovery  
**Command:**
```
exiftool -CameraSerialNumber="SN12345678" photo.jpg
```

### 23. Add photographer contact info
**Use case:** Portfolio images with contact embed  
**Command:**
```
exiftool -IPTC:Contact="true@supersynergy.de" -XMP:ContactInfoCiEmail="true@supersynergy.de" photo.jpg
```

### 24. Write subtitle sync offset as metadata
**Use case:** Note correct offset for future reference  
**Command:**
```
ffmpeg -i video.mp4 -metadata subtitle_offset="+2.5s" -c copy noted.mp4
```

---

## Strip & Anonymize

### 25. Strip all metadata from photo
**Use case:** Privacy — remove all info before public upload  
**Command:**
```
conv --strip-exif photo.jpg clean.jpg
```

### 26. Strip metadata from PDF
**Use case:** Remove author/software info from PDF  
**Command:**
```
conv --meta-strip Dokument.pdf Dokument_clean.pdf
```

### 27. Strip metadata from MP3
**Use case:** Remove recording studio metadata  
**Command:**
```
conv --meta-strip track.mp3 track_clean.mp3
```

### 28. Strip GPS only (keep camera EXIF)
**Use case:** Share photo publicly, keep camera info for portfolio  
**Command:**
```
exiftool -GPSLatitude= -GPSLongitude= -GPSAltitude= -GPSPosition= photo.jpg
```

### 29. Strip all IPTC data
**Use case:** Remove agency tags before reselling rights  
**Command:**
```
exiftool -IPTC:all= photo.jpg
```

### 30. Strip XMP data
**Use case:** Remove Adobe Photoshop history  
**Command:**
```
exiftool -XMP:all= photo.jpg
```

### 31. Anonymize batch of family photos
**Use case:** Remove GPS/names before uploading to social  
**Command:**
```
exiftool -GPSLatitude= -GPSLongitude= -Author= -Artist= -Copyright= Familienfotos/*.jpg
```

### 32. Strip metadata from video
**Use case:** Location privacy for phone videos  
**Command:**
```
ffmpeg -i personal.mp4 -map_metadata -1 -c:a copy -c:v copy stripped.mp4
```

### 33. Remove thumbnails embedded in EXIF
**Use case:** Reduce file size + remove embedded preview  
**Command:**
```
exiftool -ThumbnailImage= -PreviewImage= photo.jpg
```

### 34. Strip all metadata except copyright
**Use case:** Protect rights while maximizing privacy  
**Command:**
```
exiftool -all= -tagsFromFile @ -Copyright photo.jpg
```

---

## GPS & Location

### 35. Add GPS coordinates to photo
**Use case:** Non-GPS camera photo — add location manually  
**Command:**
```
exiftool -GPSLatitude=52.5200 -GPSLatitudeRef=N -GPSLongitude=13.4050 -GPSLongitudeRef=E Berlin_foto.jpg
```

### 36. Remove all GPS data
**Use case:** Full GPS anonymization  
**Command:**
```
exiftool -GPS:all= Standort_foto.jpg
```

### 37. Shift GPS coordinates (privacy obfuscation)
**Use case:** Roughly correct location, not precise  
**Command:**
```
exiftool -GPSLatitude+=0.001 -GPSLongitude+=0.001 foto.jpg
```

### 38. Copy GPS from one photo to another
**Use case:** Non-GPS camera with same location as GPS camera  
**Command:**
```
exiftool -TagsFromFile reference_with_gps.jpg -GPS:all target_no_gps.jpg
```

### 39. Geotag batch photos from GPX track
**Use case:** Hiking photos + GPS logger → auto geotag  
**Command:**
```
exiftool -geotag track.gpx Wanderfotos/*.jpg
```

### 40. Extract GPS from all photos to CSV
**Use case:** Map all shoot locations  
**Command:**
```
exiftool -csv -GPSLatitude -GPSLongitude -FileName *.jpg > locations.csv
```

### 41. Show GPS as decimal degrees
**Use case:** Copy to Google Maps  
**Command:**
```
exiftool -n -GPSLatitude -GPSLongitude photo.jpg
```

### 42. Reverse geocode (city from GPS)
**Use case:** Auto-rename photos by city  
**Command:**
```
exiftool -GPSLatitude -GPSLongitude photo.jpg
# then use: curl "https://nominatim.openstreetmap.org/reverse?lat=LAT&lon=LON&format=json"
```

### 43. Set altitude data
**Use case:** Mountain hike photo — add altitude  
**Command:**
```
exiftool -GPSAltitude=1850 -GPSAltitudeRef=0 Berggipfel.jpg
```

### 44. Remove GPS from all files in directory recursively
**Use case:** Full location wipe before upload  
**Command:**
```
exiftool -r -GPS:all= ./Fotos/
```

---

## Date & Time

### 45. Fix wrong camera clock (shift +2 hours)
**Use case:** Camera was in UTC, should be UTC+2  
**Command:**
```
exiftool -DateTimeOriginal+="0:0:0 2:0:0" -CreateDate+="0:0:0 2:0:0" Urlaub/*.jpg
```

### 46. Fix wrong date (camera showed 2023 instead of 2026)
**Use case:** New year rollover — camera not updated  
**Command:**
```
exiftool -DateTimeOriginal+="3:0:0 0:0:0" -CreateDate+="3:0:0 0:0:0" falsch_2023/*.jpg
```

### 47. Set date from filename
**Use case:** Scanned photos named "Foto_1998-07-15.jpg"  
**Command:**
```
conv --set-date "Foto_1998-07-15.jpg" --date "1998:07:15 12:00:00"
```

### 48. Sync file modification time to EXIF date
**Use case:** Finder/Explorer date matches capture date  
**Command:**
```
exiftool '-FileModifyDate<DateTimeOriginal' *.jpg
```

### 49. Add capture date to filename
**Use case:** Rename camera photos by date  
**Command:**
```
exiftool '-FileName<DateTimeOriginal' -d "%Y-%m-%d_%H-%M-%S.%%e" *.jpg
```

### 50. Set creation date for scanned documents
**Use case:** Scanned invoice with no date metadata  
**Command:**
```
exiftool -DateTimeOriginal="2026:01:15 09:30:00" Scan_Rechnung.jpg
```

### 51. Batch fix timezone offset for Japan trip
**Use case:** Shot in Tokyo (UTC+9), camera set to local home (UTC+1)  
**Command:**
```
exiftool -DateTimeOriginal+="0:0:0 8:0:0" Japan_Urlaub/*.jpg
```

### 52. Extract date from EXIF to text
**Use case:** Inventory or spreadsheet  
**Command:**
```
exiftool -DateTimeOriginal -FileName *.jpg | grep -E "Date|File"
```

### 53. Correct date for batch of scanned negatives
**Use case:** Film scans have today's date — set correct year  
**Command:**
```
exiftool -DateTimeOriginal="1985:08:20 00:00:00" Negative_1985/*.jpg
```

### 54. Add date taken to photos without EXIF
**Use case:** Screenshots have no creation date  
**Command:**
```
for f in Screenshots/*.png; do
  mdate=$(stat -f "%Sm" -t "%Y:%m:%d %H:%M:%S" "$f")
  exiftool -DateTimeOriginal="$mdate" "$f"
done
```

### 55. Find photos older than 2020 by EXIF
**Use case:** Find old photos for archiving  
**Command:**
```
exiftool -if '$DateTimeOriginal lt "2020:01:01"' -FileName *.jpg
```

### 56. Fix date order in mixed batch (DST overlap)
**Use case:** Photos from two cameras with different DST settings  
**Command:**
```
exiftool -DateTimeOriginal-="0:0:0 1:0:0" Camera2/*.jpg
```

---

## Audio ID3 & Tags

### 57. Set complete ID3 tags
**Use case:** Tag downloaded untagged MP3  
**Command:**
```
conv --id3 track.mp3 --artist "Supersynergy" --title "Track 01" --album "Album 2026" --year 2026 --track 1
```

### 58. Embed album cover art
**Use case:** MP3 shows no album art on phone  
**Command:**
```
conv --id3 track.mp3 --cover cover.jpg
```

### 59. Read ID3 tags
**Use case:** Inspect before bulk edit  
**Command:**
```
conv --id3 track.mp3
```

### 60. Remove cover art (reduce file size)
**Use case:** Large artwork embedded, want smaller file  
**Command:**
```
ffmpeg -i track.mp3 -map 0:a -c:a copy no_artwork.mp3
```

### 61. Copy ID3 from MP3 to FLAC
**Use case:** Converted to FLAC, lost tags  
**Command:**
```
conv --meta-copy source.mp3 destination.flac
```

### 62. Bulk set album for directory
**Use case:** All tracks in folder → same album  
**Command:**
```
for f in Album_Dir/*.mp3; do conv --id3 "$f" --album "Albumtitel" --artist "Künstler" --year 2026; done
```

### 63. Set podcast-specific ID3 fields
**Use case:** Podcast players show episode info  
**Command:**
```
ffmpeg -i episode.mp3 -metadata title="Folge 42" -metadata artist="SuperPodcast" -metadata album="Staffel 3" -metadata comment="Interview mit Maxim" -c:a copy tagged_episode.mp3
```

### 64. Add lyrics to FLAC
**Use case:** Karaoke/lyric display in player  
**Command:**
```
ffmpeg -i track.flac -metadata lyrics="$(cat lyrics.txt)" -c:a copy track_lyrics.flac
```

### 65. Convert ID3v1 to ID3v2 (encoding fix)
**Use case:** Umlauts show as garbage in player  
**Command:**
```
mid3iconv -e latin-1 --write *.mp3
```

### 66. Tag entire music library with MusicBrainz Picard
**Use case:** Automated metadata from fingerprint  
**Command:**
```
beet import ~/Musik/Neue_Alben/
```

---

## PDF & Document Metadata

### 67. Read PDF metadata
**Use case:** Check title/author before distributing  
**Command:**
```
conv --meta-read Bericht.pdf
```

### 68. Write PDF metadata
**Use case:** Set proper document properties  
**Command:**
```
conv --meta-write Bericht.pdf Title="Jahresbericht 2026" Author="Supersynergy GmbH" Subject="Finanzbericht" Keywords="jahresbericht,finanzen,2026"
```

### 69. Strip PDF metadata
**Use case:** Remove author/software info before public release  
**Command:**
```
conv --meta-strip Intern.pdf Oeffentlich.pdf
```

### 70. Check PDF creator/software
**Use case:** Identify which software created file  
**Command:**
```
exiftool -Creator -Producer -CreatorTool Dokument.pdf
```

### 71. Set PDF modification date
**Use case:** Update last-modified timestamp  
**Command:**
```
exiftool -ModifyDate="2026:04:17 09:00:00" Dokument.pdf
```

### 72. Remove PDF tracking ID
**Use case:** Adobe CC embeds document ID — remove for privacy  
**Command:**
```
qpdf --no-warn --remove-unreferenced-resources=yes --empty Dokument.pdf clean.pdf
```

### 73. Add PDF title for browser display
**Use case:** Browser tab shows filename instead of title  
**Command:**
```
exiftool -Title="Produkthandbuch 2026" Handbuch.pdf
```

### 74. Set language metadata in PDF
**Use case:** Accessibility requirement  
**Command:**
```
exiftool -Language="de-DE" Dokument.pdf
```

---

## Bulk Metadata Operations

### 75. Batch backup metadata to JSON
**Use case:** Pre-processing safety net  
**Command:**
```
for f in Fotos/*.jpg; do conv --meta-backup "$f" "meta_backup/${f%.jpg}.json"; done
```

### 76. Batch copyright all images in subdirectories
**Use case:** Protect entire photo library  
**Command:**
```
exiftool -r -Copyright="© 2026 Supersynergy. All rights reserved." ~/Fotos/
```

### 77. Batch strip GPS recursively
**Use case:** Privacy wipe before cloud backup  
**Command:**
```
exiftool -r -GPS:all= ~/Fotos/
```

### 78. Batch set artist for music library
**Use case:** Fix "Unknown Artist" across all MP3s  
**Command:**
```
for f in ~/Musik/**/*.mp3; do conv --id3 "$f" --artist "Various Artists"; done
```

### 79. Copy metadata from original to batch-converted files
**Use case:** Batch HEIC→JPG lost all metadata  
**Command:**
```
exiftool -TagsFromFile %f.HEIC converted/*.jpg
```

### 80. Batch rename by camera make/model
**Use case:** Sort photos by which camera took them  
**Command:**
```
exiftool '-FileName<${Make}_${Model}_${DateTimeOriginal}' -d "%Y%m%d_%H%M%S.%%e" *.jpg
```

### 81. Set keywords batch from CSV
**Use case:** Stock agency keyword import  
**Command:**
```
while IFS=, read file keywords; do
  exiftool -Keywords="$keywords" "$file"
done < keywords.csv
```

### 82. Batch fix encoding issues in ID3 tags
**Use case:** German umlauts broken across music library  
**Command:**
```
find ~/Musik -name "*.mp3" -exec mid3iconv -e latin-1 --write {} \;
```

### 83. Export all photo metadata to CSV
**Use case:** Inventory spreadsheet for client  
**Command:**
```
exiftool -csv -FileName -DateTimeOriginal -Make -Model -GPSLatitude -GPSLongitude -Copyright Fotos/*.jpg > inventory.csv
```

### 84. Batch verify copyright is set
**Use case:** Audit before delivery  
**Command:**
```
exiftool -if '!$Copyright' -FileName *.jpg
```

---

## Metadata Export & Inventory

### 85. Export metadata to JSON
**Use case:** Feed into database or search index  
**Command:**
```
exiftool -json -r ./Fotos/ > fotos_metadata.json
```

### 86. Generate metadata inventory CSV
**Use case:** Client asset register  
**Command:**
```
exiftool -csv ./Assets/ > assets_inventory.csv
```

### 87. Export GPS data to KML (Google Earth)
**Use case:** Visualize photo shoot locations on map  
**Command:**
```
exiftool -p gpx.fmt -r ./Fotos/ > foto_track.gpx
```

### 88. List all unique cameras in library
**Use case:** Audit which cameras were used  
**Command:**
```
exiftool -r -Model -Make ./Fotos/ | sort | uniq -c | sort -rn
```

### 89. Find photos without copyright tag
**Use case:** Compliance audit before publishing  
**Command:**
```
exiftool -r -if '!$Copyright || $Copyright eq ""' -FileName ./Fotos/
```

### 90. Disk usage by file type (metadata report)
**Use case:** Understand storage composition  
**Command:**
```
conv --format-stats ./Archiv/
```

### 91. Age report for files
**Use case:** Find oldest/newest assets  
**Command:**
```
conv --age-report ./Fotos/
```

### 92. Full metadata report for directory
**Use case:** Project handover documentation  
**Command:**
```
conv --report ./Projekt/
```

---

## Troubleshooting & Detection

### 93. Detect photos that were edited (missing original EXIF)
**Use case:** Find screenshots vs real photos  
**Command:**
```
exiftool -if '!$DateTimeOriginal' -FileName *.jpg
```

### 94. Find duplicate metadata (same GPS, different file)
**Use case:** Detect copy-paste location tagging errors  
**Command:**
```
exiftool -csv -FileName -GPSLatitude -GPSLongitude *.jpg | sort -t, -k2 | awk -F, 'seen[$2$3]++{print}'
```

### 95. Verify metadata survived format conversion
**Use case:** After batch HEIC→JPG, check tags intact  
**Command:**
```
exiftool -DateTimeOriginal -Copyright -Artist converted.jpg
```

### 96. Find all images with wrong date (year 2000 = camera reset)
**Use case:** Battery died, camera reset to 2000  
**Command:**
```
exiftool -if '$DateTimeOriginal =~ /^2000/' -FileName ./Fotos/
```

---

## Combo Workflows

### 97. iPhone Import → Strip GPS → Rename → Web Export
**Use case:** Client photos → anonymized web gallery  
**Command:**
```
convall HEIC jpg ~/Desktop/iPhone_Import/ --output-dir ./temp/
exiftool -GPS:all= ./temp/*.jpg
exiftool '-FileName<DateTimeOriginal' -d "%Y-%m-%d_%H-%M-%S.%%e" ./temp/*.jpg
for f in ./temp/*.jpg; do resize "$f" 1200; done
optall ./temp/
```

### 98. Photo Shoot → Copyright → Keyword → Deliver
**Use case:** Commercial shoot → tagged delivery  
**Command:**
```
# After shoot import
exiftool -Copyright="© 2026 Supersynergy" -Artist="Maxim Supersynergy" -IPTC:CopyrightNotice="© 2026 Supersynergy" Shooting/*.jpg
exiftool -Keywords="produkt,studio,2026" Shooting/*.jpg
exiftool -csv -FileName -DateTimeOriginal -Copyright Shooting/*.jpg > delivery_manifest.csv
```

### 99. Music Library Audit → Fix Tags → Cover Art → Export
**Use case:** Clean up music library metadata  
**Command:**
```
# Find untagged
for f in ~/Musik/**/*.mp3; do
  artist=$(exiftool -s3 -Artist "$f")
  if [ -z "$artist" ]; then echo "Untagged: $f"; fi
done > untagged.txt
# Fix and add covers
while read f; do
  conv --id3 "$f" --artist "Unknown" --album "Uncategorized"
done < untagged.txt
```

### 100. Full PII Strip Pipeline for Public Release
**Use case:** Company photos → remove all personal/location data  
**Command:**
```
mkdir -p release
for f in Internal_Fotos/*.jpg; do
  fname=$(basename "$f")
  conv --strip-exif "$f" "release/${fname}"
  # Verify clean
  exiftool -GPS:all -Author -Artist "release/${fname}" | grep -c "." && echo "WARNING: still has data in release/${fname}"
done
echo "Release folder ready: $(ls release/ | wc -l) files"
```
