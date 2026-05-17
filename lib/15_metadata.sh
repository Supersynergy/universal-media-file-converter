#!/usr/bin/env bash
# Guard against set -e breaking interactive shells when sourced
[[ "${BASH_SOURCE[0]:-}" != "${0}" ]] || set -euo pipefail

conv_meta_read() {
  local file="$1"
  [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }

  local ext="${file##*.}"
  ext="${ext,,}"

  case "$ext" in
    mp3|flac|ogg|opus|m4a|aac|wav)
      _info "Audio tags: $file"
      ffprobe -v quiet -print_format json -show_format "$file" \
        | python3 -c "
import json,sys
d=json.load(sys.stdin)
tags=d.get('format',{}).get('tags',{})
for k,v in sorted(tags.items()):
    print(f'  {k:<24} {v}')
"
      ;;
    *)
      _info "Metadata: $file"
      exiftool -json -G \
        -DateTimeOriginal -CreateDate -ModifyDate \
        -GPSLatitude -GPSLongitude -GPSAltitude \
        -Make -Model -LensModel \
        -Copyright -Artist -Author -Creator \
        -ImageWidth -ImageHeight -Duration \
        "$file" 2>/dev/null \
        | python3 -c "
import json,sys
data=json.load(sys.stdin)
if not data: sys.exit(0)
d=data[0]
for k,v in sorted(d.items()):
    if k=='SourceFile': continue
    print(f'  {k:<32} {v}')
"
      ;;
  esac
}

conv_meta_write() {
  local file="$1"; shift
  [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }
  [[ $# -gt 0 ]] || { _err "Usage: conv_meta_write <file> TAG=VALUE ..."; return 1; }

  local args=()
  for tag in "$@"; do
    args+=("-${tag}")
  done

  exiftool "${args[@]}" -overwrite_original "$file"
  _ok "Metadata written: $file"
}

conv_meta_copy() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || { _err "Source not found: $src"; return 1; }
  [[ -f "$dst" ]] || { _err "Dest not found: $dst"; return 1; }

  exiftool -tagsFromFile "$src" -overwrite_original "$dst"
  _ok "Metadata copied: $src → $dst"
}

conv_meta_strip() {
  local keep_location=0
  local files=()

  for arg in "$@"; do
    if [[ "$arg" == "--keep-location" ]]; then
      keep_location=1
    else
      files+=("$arg")
    fi
  done

  [[ ${#files[@]} -gt 0 ]] || { _err "Usage: conv_meta_strip [--keep-location] <files...>"; return 1; }

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || { _warn "Skipping (not found): $f"; continue; }
    if [[ $keep_location -eq 1 ]]; then
      exiftool -all= \
        -tagsfromfile @ -DateTimeOriginal -GPSLatitude -GPSLongitude \
        -overwrite_original "$f"
    else
      exiftool -all= -overwrite_original "$f"
    fi
    _ok "Stripped: $f"
  done
}

conv_set_date() {
  local files=("$@")
  [[ ${#files[@]} -gt 0 ]] || { _err "Usage: conv_set_date <files...>"; return 1; }

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || { _warn "Skipping (not found): $f"; continue; }

    local ts
    ts=$(exiftool -DateTimeOriginal -d "%Y%m%d%H%M.%S" -p '$DateTimeOriginal' "$f" 2>/dev/null || true)

    if [[ -n "$ts" ]]; then
      touch -t "$ts" "$f"
      _ok "Date set from EXIF: $f ($ts)"
    else
      _warn "No EXIF DateTimeOriginal found: $f"
    fi
  done
}

conv_id3() {
  local file="$1"; shift
  [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }

  local artist="" title="" album="" year="" track="" cover=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --artist) artist="$2"; shift 2 ;;
      --title)  title="$2";  shift 2 ;;
      --album)  album="$2";  shift 2 ;;
      --year)   year="$2";   shift 2 ;;
      --track)  track="$2";  shift 2 ;;
      --cover)  cover="$2";  shift 2 ;;
      *) _err "Unknown flag: $1"; return 1 ;;
    esac
  done

  local ext="${file##*.}"
  local tmp="${file%.*}_tmp_id3.${ext}"

  local meta_args=()
  [[ -n "$artist" ]] && meta_args+=(-metadata "artist=$artist")
  [[ -n "$title"  ]] && meta_args+=(-metadata "title=$title")
  [[ -n "$album"  ]] && meta_args+=(-metadata "album=$album")
  [[ -n "$year"   ]] && meta_args+=(-metadata "date=$year")
  [[ -n "$track"  ]] && meta_args+=(-metadata "track=$track")

  if [[ -n "$cover" ]]; then
    [[ -f "$cover" ]] || { _err "Cover not found: $cover"; return 1; }
    ffmpeg -v quiet -y -i "$file" -i "$cover" \
      -map 0:a -map 1:v \
      "${meta_args[@]}" \
      -c:a copy -c:v mjpeg -disposition:v attached_pic \
      "$tmp"
  else
    ffmpeg -v quiet -y -i "$file" \
      "${meta_args[@]}" \
      -c copy "$tmp"
  fi

  mv "$tmp" "$file"
  _ok "ID3 tags written: $file"
}

conv_meta_backup() {
  local dir="${1:-.}"
  local output="${2:-${dir}/metadata_backup_$(date +%Y%m%d_%H%M%S).csv}"

  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  _info "Scanning: $dir"
  exiftool -csv -r "$dir" > "$output" 2>/dev/null

  local count
  count=$(tail -n +2 "$output" | wc -l | tr -d ' ')
  _ok "Backed up metadata for $count files → $output"
}
