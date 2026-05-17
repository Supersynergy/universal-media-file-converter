#!/usr/bin/env bash
# Universal Media Converter — main entry point
# Source this file: source conv.sh

# Determine CONV_DIR (works when sourced in bash or zsh)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  CONV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  CONV_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  CONV_DIR="$HOME/projects/universal-media-file-converter"
fi

# Source lib files in order
for _conv_lib in \
  "${CONV_DIR}/lib/00_hardware.sh" \
  "${CONV_DIR}/lib/01_ui.sh" \
  "${CONV_DIR}/lib/20_flow.sh" \
  "${CONV_DIR}/lib/10_video.sh" \
  "${CONV_DIR}/lib/11_audio.sh" \
  "${CONV_DIR}/lib/12_image.sh" \
  "${CONV_DIR}/lib/21_archive_media.sh" \
  "${CONV_DIR}/lib/13_pdf.sh" \
  "${CONV_DIR}/lib/18_print.sh" \
  "${CONV_DIR}/lib/19_printers.sh" \
  "${CONV_DIR}/lib/14_archive.sh" \
  "${CONV_DIR}/lib/15_metadata.sh" \
  "${CONV_DIR}/lib/16_bulk.sh" \
  "${CONV_DIR}/lib/17_report.sh"
do
  if [[ -f "$_conv_lib" ]]; then
    # shellcheck source=/dev/null
    source "$_conv_lib"
  fi
done
unset _conv_lib

# Initialise colors and hardware detection
_conv_color_init 2>/dev/null || true
_conv_hw_init    2>/dev/null || true

# ── Auto-router ────────────────────────────────────────────────────────────────

_conv_auto() {
  local input="$1"
  local output="$2"

  [[ -f "$input" ]] || { _err "Input not found: $input"; return 1; }

  local out_ext="${output##*.}"
  out_ext="${out_ext,,}"

  case "$out_ext" in
    mp4|mkv|avi|mov|webm|gif)
      conv_video "$input" "$output"
      ;;
    mp3|opus|aac|flac|wav|m4a)
      conv_audio "$input" "$output"
      ;;
    jpg|jpeg|png|webp|avif|jxl|heic)
      conv_image "$input" "$output"
      ;;
    pdf)
      local in_ext="${input##*.}"
      in_ext="${in_ext,,}"
      if [[ "$in_ext" == "md" ]]; then
        pandoc "$input" -o "$output"
        _ok "Converted: $input → $output"
      else
        qpdf --copy-encryption="$input" "$input" "$output" 2>/dev/null \
          || qpdf "$input" "$output"
        _ok "Copied PDF: $input → $output"
      fi
      ;;
    *)
      _info "Falling back to ffmpeg: $input → $output"
      ffmpeg -v quiet -stats -i "$input" "$output" && _ok "Done: $output"
      ;;
  esac
}

# ── Main dispatcher ────────────────────────────────────────────────────────────

conv() {
  case "${1:-}" in
    --probe)             shift; conv_probe             "$@" ;;
    --trim)              shift; conv_trim              "$@" ;;
    --concat)            shift; conv_concat            "$@" ;;
    --split)             shift; conv_split             "$@" ;;
    --extract-audio)     shift; conv_extract_audio     "$@" ;;
    --thumbnail)         shift; conv_thumbnail         "$@" ;;
    --hdr-sdr)           shift; conv_hdr_sdr           "$@" ;;
    --subtitle-extract)  shift; conv_subtitle_extract  "$@" ;;
    --subtitle-burn)     shift; conv_subtitle_burn     "$@" ;;
    --frame)             shift; conv_frame             "$@" ;;
    --normalize)         shift; conv_normalize         "$@" ;;
    --split-silence)     shift; conv_split_silence     "$@" ;;
    --waveform)          shift; conv_waveform          "$@" ;;
    --strip-exif)        shift; conv_strip_exif        "$@" ;;
    --set-date)          shift; conv_set_date          "$@" ;;
    --auto-rotate)       shift; conv_auto_rotate       "$@" ;;
    --crop)              shift; conv_crop              "$@" ;;
    --thumbnail-grid)    shift; conv_thumbnail_grid    "$@" ;;
    --preflight)         shift; conv_pdf_preflight     "$@" ;;
    --pdf-x|--pdfx)      shift; conv_pdf_to_pdfx        "$@" ;;
    --pdf-cmyk)          shift; conv_pdf_rgb_to_cmyk    "$@" ;;
    --pdf-rgb)           shift; conv_pdf_cmyk_to_rgb    "$@" ;;
    --pdf-gray|--pdf-grayscale) shift; conv_pdf_grayscale "$@" ;;
    --pdf-nup)           shift; conv_pdf_nup            "$@" ;;
    --pdf-booklet)       shift; conv_pdf_booklet        "$@" ;;
    --pdf-crop-marks)    shift; conv_pdf_crop_marks     "$@" ;;
    --pdf-resize)        shift; conv_pdf_resize         "$@" ;;
    --pdf-extract-pages) shift; conv_pdf_extract_pages  "$@" ;;
    --img-cmyk)          shift; conv_img_to_cmyk        "$@" ;;
    --img-rgb)           shift; conv_img_to_rgb         "$@" ;;
    --dpi-check)         shift; conv_img_dpi_check      "$@" ;;
    --dpi-set)           shift; conv_img_set_dpi        "$@" ;;
    --upscale)           shift; conv_img_upscale        "$@" ;;
    --print-ready)       shift; conv_img_print_ready    "$@" ;;
    --poster-split)      shift; conv_img_poster_split   "$@" ;;
    --qr)                shift; conv_qr                 "$@" ;;
    --qr-svg)            shift; conv_qr_svg             "$@" ;;
    --barcode-scan)      shift; conv_barcode_scan       "$@" ;;
    --trace)             shift; conv_raster_to_vector   "$@" ;;
    --svg-pdf)           shift; conv_svg_to_pdf         "$@" ;;
    --print-prep)        shift; conv_print_prep         "$@" ;;
    --business-card)     shift; conv_business_card      "$@" ;;
    --archive)           shift; conv_archive        "$@" ;;
    --archive-master)    shift; conv_archive_master "$@" ;;
    --for)               shift; conv_for            "$@" ;;
    --wizard)            shift; conv_wizard         "$@" ;;
    --analyze)           shift; conv_analyze        "$@" ;;
    --smart)             shift; conv_smart          "$@" ;;
    --printer-list)      shift; conv_printer_list   "$@" ;;
    --printer-specs)     shift; conv_printer_specs  "$@" ;;
    --printer-match)     shift; conv_printer_match  "$@" ;;
    --product-list)      shift; conv_product_list   "$@" ;;
    --detect-product)    shift; conv_detect_product "$@" ;;
    --pdf-merge)         shift; conv_pdf_merge         "$@" ;;
    --pdf-split)         shift; conv_pdf_split         "$@" ;;
    --pdf-rotate)        shift; conv_pdf_rotate        "$@" ;;
    --pdf-compress)      shift; conv_pdf_compress      "$@" ;;
    --pdf-ocr)           shift; conv_pdf_ocr           "$@" ;;
    --pdf-images)        shift; conv_pdf_images        "$@" ;;
    --pdf-text)          shift; conv_pdf_text          "$@" ;;
    --pdf-info)          shift; conv_pdf_info          "$@" ;;
    --extract)           shift; conv_extract           "$@" ;;
    --extract-all)       shift; conv_extract_all       "$@" ;;
    --compress)          shift; conv_compress          "$@" ;;
    --split-file)        shift; conv_split_file        "$@" ;;
    --meta-read)         shift; conv_meta_read         "$@" ;;
    --meta-write)        shift; conv_meta_write        "$@" ;;
    --meta-copy)         shift; conv_meta_copy         "$@" ;;
    --meta-strip)        shift; conv_meta_strip        "$@" ;;
    --id3)               shift; conv_id3               "$@" ;;
    --meta-backup)       shift; conv_meta_backup       "$@" ;;
    --dedupe)            shift; conv_dedupe            "$@" ;;
    --rename-batch)      shift; conv_rename_batch      "$@" ;;
    --sort-type)         shift; conv_sort_type         "$@" ;;
    --sort-date)         shift; conv_sort_date         "$@" ;;
    --remove-empty)      shift; conv_remove_empty      "$@" ;;
    --screenshot-detect) shift; conv_screenshot_detect "$@" ;;
    --report)            shift; conv_report            "$@" ;;
    --age-report)        shift; conv_age_report        "$@" ;;
    --format-stats)      shift; conv_format_stats      "$@" ;;
    --flow-stats)        _conv_flow_stats ;;
    --cache-clear)       shift; _conv_cache_clear      "$@" ;;
    --watch)             shift; _conv_watch            "$@" ;;
    --budget)            shift; CONV_BUDGET_MODE="${1:-balanced}"; _info "Budget mode: $CONV_BUDGET_MODE" ;;
    --help|-h)           conv_help ;;
    *)
      # Natural-language dispatch: if $1 has spaces and $2 is a file, route to conv_smart
      if [[ "$1" == *" "* && -n "${2:-}" && -f "${2:-}" ]]; then
        conv_smart "$1" "$2"
      elif [[ $# -eq 2 ]]; then
        _conv_auto "$1" "$2"
      else
        _err "Usage: conv <input> <output>  OR  conv --flag [args]"
        _err "Run 'conv --help' for all commands."
        return 1
      fi
      ;;
  esac
}

# ── Help ───────────────────────────────────────────────────────────────────────

conv_help() {
  cat <<'EOF'
Universal Media Converter — conv.sh

USAGE
  conv <input> <output>          Auto-detect and convert
  conv --flag [args...]          Run specific operation

VIDEO
  conv --probe <file>            Show streams and metadata
  conv --trim <f> <s> <e> <out> Trim to start/end timestamps
  conv --concat <out> <f1> <f2> Concatenate files
  conv --split <file> <dur>      Split into segments
  conv --extract-audio <f> <out> Strip audio track
  conv --thumbnail <file> [t]    Extract thumbnail frame
  conv --hdr-sdr <file> <out>    HDR → SDR tone-map
  conv --subtitle-extract <f>    Extract subtitle tracks
  conv --subtitle-burn <f> <s>   Burn subtitles into video
  conv --frame <file> [t]        Extract single frame as PNG
  conv --thumbnail-grid <file>   Contact sheet of frames

AUDIO
  conv --normalize <file> [out]  Loudness-normalize (EBU R128)
  conv --split-silence <file>    Split on silence gaps
  conv --waveform <file> [out]   Render waveform PNG
  conv --id3 <file> [--artist X] [--title X] [--album X]
       [--year X] [--track X] [--cover img]   Set ID3 tags

IMAGE
  conv --strip-exif <files...>   Remove all EXIF metadata
  conv --auto-rotate <files...>  Auto-rotate by EXIF orientation
  conv --crop <file> WxH+X+Y     Crop region
  conv --set-date <files...>     Set mtime from EXIF date

PDF
  conv --pdf-merge <out> <f...>  Merge PDFs
  conv --pdf-split <file> [dir]  Split pages to individual PDFs
  conv --pdf-rotate <file> <deg> Rotate pages
  conv --pdf-compress <file> [o] Reduce PDF size
  conv --pdf-ocr <file> [out]    OCR with tesseract
  conv --pdf-images <file> [dir] Extract embedded images
  conv --pdf-text <file>         Extract text
  conv --pdf-info <file>         Show PDF metadata

ARCHIVE
  conv --extract <archive> [dir] Extract archive
  conv --extract-all <dir>       Extract all archives in dir
  conv --compress <out> <files>  Create archive
  conv --split-file <f> <size>   Split large file (e.g. 100M)

METADATA
  conv --meta-read <file>        Show metadata (exiftool)
  conv --meta-write <f> TAG=VAL  Write metadata tags
  conv --meta-copy <src> <dst>   Copy metadata between files
  conv --meta-strip [--keep-location] <files...>
  conv --meta-backup <dir> [csv] Export all metadata to CSV

BULK
  convall <src_ext> <dst_ext> [dir] [options]
    Options: --parallel N  --recursive  --older-than Nd
             --larger-than NM  --dry-run  --output-dir <path>
  conv --dedupe <dir> [--delete] [--similar]
  conv --rename-batch '<pattern>' [dir] [--dry-run] [--exif|--mtime]
    Pattern vars: {date} {year} {month} {day} {seq:N} {name} {ext}
  conv --sort-type <dir> [--move|--copy] [--dry-run]
  conv --sort-date <dir> [fmt] [--move|--copy] [--dry-run]
  conv --remove-empty <dir>
  conv --screenshot-detect <dir>

REPORTS
  conv --report <dir>            Full media audit table
  conv --age-report <dir> [days] Files older than N days
  conv --format-stats <dir>      Codec/resolution/bitrate stats

PRINT PRODUCTION
  conv --preflight <file>              Production-readiness audit (fonts, DPI, TAC, colorspace)
  conv --pdf-x <file> [x1a|x3|x4]     Convert to PDF/X standard (default: x1a)
  conv --pdf-cmyk <file> [out]         RGB → CMYK for offset print
  conv --pdf-rgb <file> [out]          CMYK → sRGB for web preview
  conv --pdf-gray <file> [out]         Grayscale conversion (laser)
  conv --pdf-nup <file> <c> <r>        N-up imposition (e.g. 2 2 = 4-up)
  conv --pdf-booklet <file> [out]      Saddle-stitch booklet imposition
  conv --pdf-crop-marks <file> [bleed] Add crop marks + bleed (default 3mm)
  conv --pdf-resize <file> <paper>     Resize to a4/a3/letter/business-card/...
  conv --pdf-extract-pages <f> <range> Extract pages (e.g. 1-5,8,12-15)
  conv --img-cmyk <file> [out] [icc]   Image RGB → CMYK with ICC profile
  conv --img-rgb <file> [out]          Image CMYK → sRGB
  conv --dpi-check <files...>          Audit DPI for print (flag <300 DPI)
  conv --dpi-set <file> <dpi>          Set DPI metadata (no resample)
  conv --upscale <file> <dpi> <mm>     Upscale image to print target
  conv --print-ready <files...>        Batch: CMYK + 300 DPI + flatten + ICC
  conv --poster-split <file> <r> <c>   Tile image across N pages
  conv --qr <data> [out] [size] [ecc]  Generate QR code (PNG)
  conv --qr-svg <data> [out]           Vector QR (SVG, scalable)
  conv --barcode-scan <image>          Decode QR/barcodes
  conv --trace <image>                 Raster → SVG via potrace
  conv --svg-pdf <file> [out]          SVG → print-ready PDF
  conv --print-prep <file> [target]    1-click: offset|digital|web|laser
  conv --business-card <front> [back]  Generate 85x55mm PDF with bleed + crop

SMART PRINT (printer-aware)
  conv --for <printer> <product> <file>    One-click print prep for specific printer
  conv --wizard [file]                     Interactive Q&A flow
  conv --analyze <file>                    Auto-detect everything (colorspace, DPI, bleed)
  conv --smart "flyer wirmachendruck" <f>  Natural-language dispatch
  conv --printer-list                      All supported printers
  conv --printer-specs <printer>           Show requirements
  conv --printer-match <url>              Resolve URL → printer slug
  conv --product-list [printer]            List products (per printer or all)
  conv --detect-product <file>             Heuristic: what kind of print product?

ARCHIVE-GRADE COMPRESSION (max shrink, no real quality loss)
  conv --archive [--dry-run] [--out DIR] <file|dir>...
       Visually-lossless: video→x265 CRF18 10-bit, image→JXL -d1.
       ~4-6x smaller, zoom/edit safe, source kept. Best default for phone/archive.
  conv --archive-master [--dry-run] [--out DIR] <file|dir>...
       Bit-perfect: video→FFV1+FLAC (.mkv), image→JXL -d0 (JPEG -j1 = reversible).
       Mathematically lossless, fully restorable. For master originals.

FLOW ENGINE
  conv --flow-stats              Cache hit rate, entries, budget mode
  conv --cache-clear [--older-than Nd]  Wipe ~/.cache/conv
  conv --watch <dir> <handler>   Watch dir for new files
  conv --budget <mode>           Set CONV_BUDGET_MODE (speed/balanced/quality/archival)

EXAMPLES
  conv video.mov output.mp4
  conv photo.heic photo.jpg
  conv --trim video.mp4 00:01:00 00:02:30 clip.mp4
  conv --id3 song.mp3 --artist "Max" --album "2025"
  convall mov mp4 ~/Videos --recursive --parallel 8
  conv --dedupe ~/Photos --delete
  conv --rename-batch '{year}-{month}-{day}_{seq:3}.{ext}' ~/Photos
  conv --report ~/Downloads
EOF
}

# ── Top-level aliases ──────────────────────────────────────────────────────────

convall()    { convall    "$@"; }  # already defined in 16_bulk.sh; exported here
optimg()     { conv_image "$@"; }
optall()     { convall jpg jpg "${1:-.}" --recursive "${@:2}"; }
smartencode(){ conv_video "$@"; }
resize()     { conv_image "$@"; }
# conv_info defined in lib/00_hardware.sh — do not override here
