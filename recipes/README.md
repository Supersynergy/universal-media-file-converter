# Universal Media Converter — Recipe Book

800 real-world recipes for `conv`, `convall`, and the full tool suite. Covers video, audio, image, PDF, print, metadata, archives, and bulk workflows.

## Recipe Files

| File | Category | Subsections |
|------|----------|-------------|
| [01_video.md](01_video.md) | Video | Conversion, Compress, Trim/Join/Split, Extract, Subtitles, Thumbnails, HDR, Rotate/Speed, Social Media, Troubleshooting |
| [02_audio.md](02_audio.md) | Audio | Format Conversion, Bitrate Presets, Normalization, Editing, Channel/Sample Rate, ID3 Tagging, Splitting, Podcast, Transcription |
| [03_image.md](03_image.md) | Image | Format Conversion, Resize/Crop, Color, EXIF/Metadata, Optimization, Social Media Sizes, Print Prep, Batch, Watermarking |
| [04_pdf.md](04_pdf.md) | PDF | Merge/Split, Page Ops, Compression, OCR/Text, Conversion, Security, Metadata, Redaction, Inspection |
| [05_print.md](05_print.md) | Print Production | Preflight, PDF/X, Color, Bleed/Sizes, Imposition, 25+ Printer Profiles, POD Platforms, Wide Format |
| [06_metadata.md](06_metadata.md) | Metadata & EXIF | Read/Write, Strip/Anonymize, GPS, Date/Time, ID3, PDF Metadata, Bulk Ops, Export/Inventory |
| [07_archive.md](07_archive.md) | Archive & Backup | Extract, Compress, Split, Verification, Encryption, Format-Specific, Developer, Backup, Cold Storage |
| [08_bulk.md](08_bulk.md) | Bulk & Organization | Bulk Convert, Dedupe, Smart Rename, Folder Org, Cleanup, Filters, Reports, Import Pipelines |

---

## Quick Find — 20 Most-Asked Scenarios

| Scenario | Recipe Location |
|----------|----------------|
| iPhone HEIC → JPEG | [03_image.md #1](03_image.md) |
| Batch convert HEIC → JPEG | [08_bulk.md #1](08_bulk.md) |
| Compress video for email | [01_video.md #19](01_video.md) |
| MP3 → Opus (smaller) | [02_audio.md #6](02_audio.md) |
| Strip GPS/EXIF from photos | [06_metadata.md #28](06_metadata.md) |
| Merge PDFs | [04_pdf.md #1](04_pdf.md) |
| OCR scanned PDF (German) | [04_pdf.md #37](04_pdf.md) |
| PDF → compressed for email | [04_pdf.md #29](04_pdf.md) |
| Business card for Wirmachendruck | [05_print.md #48](05_print.md) |
| Deduplicate photo library | [08_bulk.md #16](08_bulk.md) |
| Rename photos by date | [08_bulk.md #27](08_bulk.md) |
| Normalize podcast loudness (-16 LUFS) | [02_audio.md #27](02_audio.md) |
| YouTube upload preset | [01_video.md #20](01_video.md) |
| Instagram Reel format | [01_video.md #22](01_video.md) |
| Extract audio from video | [01_video.md #43](01_video.md) |
| RGB → CMYK for print | [05_print.md #19](05_print.md) |
| Password-protect archive | [07_archive.md #48](07_archive.md) |
| Resize image for web | [03_image.md #19](03_image.md) |
| Set ID3 tags on MP3 | [06_metadata.md #57](06_metadata.md) |
| Sort downloads by type | [08_bulk.md #45](08_bulk.md) |

---

## Top 10 Combo Workflows

High-impact multi-step pipelines worth bookmarking:

1. **Photo Delivery Pipeline** — Strip EXIF → Resize → Watermark → Optimize → Rename  
   → [03_image.md #99](03_image.md)

2. **Podcast Episode Production** — Record → Normalize → Add Music → Tag → Export RSS  
   → [02_audio.md #97](02_audio.md)

3. **iPhone Import Pipeline** — HEIC→JPG → Auto-rotate → Organize by date → Dedupe  
   → [08_bulk.md #94](08_bulk.md)

4. **Print Production Preflight** — Design → Preflight → CMYK → PDF/X-1a → Crop marks  
   → [05_print.md #95](05_print.md)

5. **Invoice Archive** — Scan → OCR (German) → Compress → Batch merge annual  
   → [04_pdf.md #95](04_pdf.md)

6. **Video to Social Pack** — HDR → SDR → Instagram Reel + YouTube + TikTok formats  
   → [01_video.md #98](01_video.md)

7. **PII Strip for Public Release** — Strip all EXIF/GPS → Verify clean → Deliver  
   → [06_metadata.md #100](06_metadata.md)

8. **3-2-1 Backup** — Create → Checksum → External drive + NAS + Cloud  
   → [07_archive.md #100](07_archive.md)

9. **Music Library Audit** — Find untagged → Fix tags → Dedupe → Normalize loudness  
   → [08_bulk.md #95](08_bulk.md)

10. **Full Media Ingest** — SD card → RAW backup → Convert → Thumbnail → Dedupe → Organize  
    → [08_bulk.md #100](08_bulk.md)

---

## Tools Cheat-Sheet

| Command | Description |
|---------|-------------|
| `conv <in> <out>` | Convert any media file (auto-detects format from extension) |
| `conv --probe <file>` | Show technical details of any media file |
| `conv --trim <in> <out> --start T --end T` | Trim video/audio to time range |
| `conv --concat A B out` | Join two media files |
| `conv --split <in> --duration N` | Split into N-second chunks |
| `conv --extract-audio <video> <out>` | Pull audio track from video |
| `conv --thumbnail <video> <img>` | Extract thumbnail frame |
| `conv --thumbnail-grid <video> <img>` | Generate contact sheet grid |
| `conv --hdr-sdr <in> <out>` | Convert HDR video to SDR |
| `conv --subtitle-extract <video> <srt>` | Extract embedded subtitles |
| `conv --subtitle-burn <video> <srt> <out>` | Burn subtitles into video |
| `conv --frame <video> <img> --time T` | Extract specific frame |
| `conv --normalize <audio> <out>` | Loudness normalization |
| `conv --split-silence <audio>` | Split on silence gaps |
| `conv --waveform <audio> <img>` | Generate waveform image |
| `conv --id3 <mp3> --artist X --title Y` | Set ID3 metadata tags |
| `conv --strip-exif <img> <out>` | Remove all EXIF data |
| `conv --auto-rotate <img> <out>` | Fix orientation from EXIF |
| `conv --crop <img> <out>` | Crop image |
| `conv --set-date <file> --date D` | Set EXIF date |
| `conv --dpi-check <file>` | Check image resolution |
| `conv --dpi-set <file> <out> --dpi N` | Set DPI metadata |
| `conv --upscale <img> <out> --size WxH` | AI upscale image |
| `conv --pdf-merge A B C out` | Merge PDFs |
| `conv --pdf-split <in> <out_pattern>` | Split PDF |
| `conv --pdf-rotate <in> <deg> <out>` | Rotate PDF pages |
| `conv --pdf-compress <in> <out>` | Compress PDF |
| `conv --pdf-ocr <in> <out> --lang L` | OCR scan to searchable PDF |
| `conv --pdf-images <in> <dir>` | Extract images from PDF |
| `conv --pdf-text <in> <txt>` | Extract text from PDF |
| `conv --pdf-info <file>` | Show PDF properties |
| `conv --preflight <file>` | Print preflight check |
| `conv --pdf-x <in> <x1a\|x3\|x4> <out>` | Convert to PDF/X standard |
| `conv --pdf-cmyk <in> <out>` | Convert to CMYK |
| `conv --pdf-rgb <in> <out>` | Convert to RGB |
| `conv --pdf-gray <in> <out>` | Convert to grayscale |
| `conv --pdf-nup <in> N <out>` | N-up page imposition |
| `conv --pdf-booklet <in> <out>` | Booklet imposition |
| `conv --pdf-crop-marks <in> <out>` | Add crop/bleed marks |
| `conv --pdf-resize <in> <size> <out>` | Resize pages (a4/a5/letter/...) |
| `conv --pdf-extract-pages <in> <range> <out>` | Extract page range |
| `conv --img-cmyk <img> <out>` | Convert image to CMYK |
| `conv --img-rgb <img> <out>` | Convert image to RGB |
| `conv --print-ready <in> <out>` | Full print-ready export |
| `conv --poster-split <in> <size> <dir>` | Split poster for tiling |
| `conv --qr <url> <out>` | Generate QR code |
| `conv --qr-svg <url> <out>` | Generate scalable QR code |
| `conv --barcode-scan <code> <out>` | Generate barcode |
| `conv --trace <img> <svg>` | Trace bitmap to vector |
| `conv --svg-pdf <svg> <pdf>` | Convert SVG to PDF |
| `conv --for <printer> <product> <file>` | Printer-specific export |
| `conv --wizard` | Interactive setup guide |
| `conv --analyze <file>` | Analyze file specs |
| `conv --smart <in> <out>` | Auto-fix and export |
| `conv --printer-list` | List supported printers |
| `conv --meta-read <file>` | Read all metadata |
| `conv --meta-write <file> KEY=VAL` | Write metadata fields |
| `conv --meta-copy <src> <dst>` | Copy metadata between files |
| `conv --meta-strip <in> <out>` | Remove all metadata |
| `conv --meta-backup <file> <json>` | Export metadata to JSON |
| `conv --extract <archive>` | Extract any archive |
| `conv --extract-all <dir>` | Extract all archives in directory |
| `conv --compress <dir> <archive>` | Create archive |
| `conv --split-file <file> --size N` | Split large file |
| `convall <src> <dst> [dir]` | Batch convert all files |
| `convall ... --parallel N` | Set parallel worker count |
| `convall ... --recursive` | Process subdirectories |
| `convall ... --older-than Nd` | Only files older than N days |
| `convall ... --larger-than NM` | Only files larger than N MB |
| `convall ... --dry-run` | Preview without executing |
| `convall ... --output-dir <dir>` | Output destination directory |
| `conv --dedupe <dir>` | Find duplicate files |
| `conv --dedupe ... --delete` | Find and delete duplicates |
| `conv --dedupe ... --similar` | Perceptual similarity check |
| `conv --rename-batch '<pattern>' '<fmt>'` | Batch rename with pattern vars |
| `conv --sort-type <dir>` | Sort files by type into folders |
| `conv --sort-date <dir>` | Sort files by date into folders |
| `conv --remove-empty <dir>` | Remove empty directories |
| `conv --screenshot-detect <dir>` | Identify screenshot files |
| `conv --report <dir>` | Full directory analysis report |
| `conv --age-report <dir>` | File age distribution report |
| `conv --format-stats <dir>` | Format breakdown statistics |
| `resize <file> <width>` | Resize image to width (keep aspect) |
| `optimg <file>` | Optimize single image |
| `optall <dir>` | Optimize all images in directory |
