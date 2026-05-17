#!/usr/bin/env bash
# Archive-grade compression — sourced into interactive shell (no set -euo pipefail)
#
# Two tiers:
#   conv --archive         visually-lossless: x265 CRF18 10-bit + JXL -d1.  ~4-6x smaller, 0 visible loss, zoom/edit safe.
#   conv --archive-master  bit-perfect:       FFV1 + FLAC + JXL -d0/-j1.    mathematically lossless, fully reversible.
#
# Flags: --dry-run (plan + est only) · --keep (don't delete source) · --out <dir>
# Guards: skip-if-output-bigger, source always kept (non-destructive), serial (CPU-bound).

_conv_arch_has() { command -v "$1" &>/dev/null; }

_conv_arch_size() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0; }

# ── one image → JXL ────────────────────────────────────────────────────────────
_conv_arch_image() {
  local in="$1" tier="$2" dry="$3" outdir="$4"
  local base ext lext out
  base="$(basename "${in%.*}")"; ext="${in##*.}"; lext="${ext,,}"
  out="${outdir:-$(dirname "$in")}/${base}.jxl"

  if [[ "$dry" == "1" ]]; then
    printf '  IMG  %-40s → %s.jxl  [%s]\n' "$(basename "$in")" "$base" "$tier"; return 0
  fi
  _conv_arch_has cjxl || { _err "cjxl missing — brew install jpeg-xl"; return 1; }

  if [[ "$lext" == "jpg" || "$lext" == "jpeg" ]]; then
    # lossless JPEG transcode — bit-exact reversible (cjxl -j 1), ~20% smaller
    cjxl "$in" "$out" -d 0 -j 1 -e 9 --quiet 2>/dev/null
  elif [[ "$tier" == "master" ]]; then
    cjxl "$in" "$out" -d 0 -e 9 --quiet 2>/dev/null          # mathematically lossless
  else
    cjxl "$in" "$out" -d 1 -e 8 --quiet 2>/dev/null          # visually lossless
  fi
  [[ -f "$out" ]] || { _err "JXL encode failed: $in"; return 1; }

  local sb sa; sb=$(_conv_arch_size "$in"); sa=$(_conv_arch_size "$out")
  if (( sa >= sb )); then
    rm -f "$out"; _warn "skip (no gain): $(basename "$in") ${sb}→${sa}B"; return 0
  fi
  _ok "$(basename "$in") → $(basename "$out")  $(awk "BEGIN{printf \"%.0f%%\",100*$sa/$sb}") of original"
}

# ── one video → x265/FFV1 ──────────────────────────────────────────────────────
_conv_arch_video() {
  local in="$1" tier="$2" dry="$3" outdir="$4"
  local base out d
  base="$(basename "${in%.*}")"; d="${outdir:-$(dirname "$in")}"

  if [[ "$tier" == "master" ]]; then
    out="${d}/${base}.archive.mkv"
    [[ "$dry" == "1" ]] && { printf '  VID  %-40s → %s.archive.mkv  [FFV1 lossless]\n' "$(basename "$in")" "$base"; return 0; }
    ffmpeg -y -i "$in" -c:v ffv1 -level 3 -g 1 -slicecrc 1 \
      -c:a flac -map_metadata 0 "$out" 2>/dev/null
  else
    out="${d}/${base}.archive.mp4"
    [[ "$dry" == "1" ]] && { printf '  VID  %-40s → %s.archive.mp4  [x265 CRF18 10-bit]\n' "$(basename "$in")" "$base"; return 0; }
    ffmpeg -y -i "$in" -c:v libx265 -crf 18 -preset slow \
      -pix_fmt yuv420p10le -x265-params "aq-mode=3:profile=main10" -tag:v hvc1 \
      -c:a copy -map_metadata 0 "$out" 2>/dev/null \
      || ffmpeg -y -i "$in" -c:v libx265 -crf 18 -preset slow \
           -pix_fmt yuv420p10le -tag:v hvc1 -c:a aac -b:a 192k -map_metadata 0 "$out" 2>/dev/null
  fi
  [[ -f "$out" ]] || { _err "video encode failed: $in"; return 1; }

  local sb sa; sb=$(_conv_arch_size "$in"); sa=$(_conv_arch_size "$out")
  if (( sa >= sb )); then
    rm -f "$out"; _warn "skip (no gain): $(basename "$in") ${sb}→${sa}B"; return 0
  fi
  _ok "$(basename "$in") → $(basename "$out")  $(awk "BEGIN{printf \"%.0f%%\",100*$sa/$sb}") of original"
}

# ── dispatcher ────────────────────────────────────────────────────────────────
_conv_archive_run() {
  local tier="$1"; shift
  local dry=0 outdir="" ; local -a targets=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry=1 ;;
      --out)     outdir="$2"; shift ;;
      *)         targets+=("$1") ;;
    esac
    shift
  done
  [[ ${#targets[@]} -eq 0 ]] && { _err "Usage: conv --archive[-master] [--dry-run] [--out DIR] <file|dir> ..."; return 1; }
  [[ -n "$outdir" ]] && mkdir -p "$outdir"

  # expand dirs → files
  local -a files=()
  local t
  for t in "${targets[@]}"; do
    if [[ -d "$t" ]]; then
      while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$t" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' -o -iname '*.heif' \
           -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.webp' -o -iname '*.bmp' \
           -o -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' -o -iname '*.avi' -o -iname '*.m4v' \) -print0)
    elif [[ -f "$t" ]]; then
      files+=("$t")
    else
      _warn "not found: $t"
    fi
  done
  [[ ${#files[@]} -eq 0 ]] && { _err "no media files"; return 1; }

  local _drylbl=""; [[ "$dry" == "1" ]] && _drylbl=" — DRY RUN"
  _info "Archive (${tier}) — ${#files[@]} files${_drylbl}"
  _conv_start_timer 2>/dev/null || true

  local img_ext='jpg jpeg png heic heif tif tiff webp bmp'
  for f in "${files[@]}"; do
    local e="${f##*.}"; e="${e,,}"
    if [[ " $img_ext " == *" $e "* ]]; then
      _conv_arch_image "$f" "$tier" "$dry" "$outdir"
    else
      _conv_arch_video "$f" "$tier" "$dry" "$outdir"
    fi
  done
  _conv_done "archive" "${#files[@]} files" 2>/dev/null || _ok "Archive ${tier} done: ${#files[@]} files"
}

conv_archive()        { _conv_archive_run visual "$@"; }
conv_archive_master() { _conv_archive_run master "$@"; }
