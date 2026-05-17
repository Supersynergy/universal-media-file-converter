#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]:-}" != "${0}" ]] || set -euo pipefail

convall() {
  local src_ext="$1" dst_ext="$2"
  local dir="${3:-.}"
  shift 3 2>/dev/null || shift $#

  local parallel="${CONV_CORES:-4}"
  local recursive=0
  local older_than="" larger_than=""
  local dry_run=0
  local output_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --parallel)    parallel="$2";    shift 2 ;;
      --recursive)   recursive=1;      shift ;;
      --older-than)  older_than="$2";  shift 2 ;;
      --larger-than) larger_than="$2"; shift 2 ;;
      --dry-run)     dry_run=1;        shift ;;
      --output-dir)  output_dir="$2";  shift 2 ;;
      *) _warn "Unknown option: $1";   shift ;;
    esac
  done

  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  local find_args=("$dir")
  [[ $recursive -eq 0 ]] && find_args+=(-maxdepth 1)
  find_args+=(-type f -iname "*.${src_ext}")

  if [[ -n "$older_than" ]]; then
    local days="${older_than//[^0-9]/}"
    find_args+=(-mtime "+${days}")
  fi
  if [[ -n "$larger_than" ]]; then
    local size_val="${larger_than//[^0-9]/}"
    local size_unit="${larger_than//[0-9]/}"
    local find_size="${size_val}${size_unit,,}"
    find_args+=(-size "+${find_size}")
  fi

  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "${find_args[@]}" -print0 2>/dev/null)

  local total=${#files[@]}
  [[ $total -gt 0 ]] || { _warn "No .${src_ext} files found in $dir"; return 0; }

  if [[ -n "$output_dir" ]]; then
    mkdir -p "$output_dir"
  fi

  _info "Found $total .${src_ext} files → converting to .${dst_ext}"
  [[ $dry_run -eq 1 ]] && _warn "(dry-run: no conversion)"

  local done_count=0 fail_count=0
  local size_before=0 size_after=0
  local tmpfile
  tmpfile=$(mktemp)

  _do_one() {
    local f="$1" out_ext="$2" odir="$3"
    local base="${f%.*}"
    local out
    if [[ -n "$odir" ]]; then
      out="${odir}/$(basename "$base").${out_ext}"
    else
      out="${base}.${out_ext}"
    fi
    conv "$f" "$out" 2>/dev/null && echo "ok:$f:$out" || echo "fail:$f"
  }
  export -f _do_one

  _bulk_convert_one() {
    local f="$1"
    local base="${f%.*}"
    local out
    if [[ -n "$output_dir" ]]; then
      out="${output_dir}/$(basename "$base").${dst_ext}"
    else
      out="${base}.${dst_ext}"
    fi
    fsize=$(stat -f%z "$f" 2>/dev/null || echo 0)
    size_before=$(( size_before + fsize ))

    if declare -f _conv_incremental &>/dev/null; then
      _conv_incremental "$f" "$out" conv "$f" "$out" 2>/dev/null \
        && echo "ok:$f:$out" >> "$tmpfile" \
        || echo "fail:$f" >> "$tmpfile"
    else
      conv "$f" "$out" 2>/dev/null \
        && echo "ok:$f:$out" >> "$tmpfile" \
        || echo "fail:$f" >> "$tmpfile"
    fi
    local completed
    completed=$(wc -l < "$tmpfile" | tr -d ' ')
    printf "\r[%d/%d] converting..." "$completed" "$total" >&2
  }

  if [[ $dry_run -eq 1 ]]; then
    for f in "${files[@]}"; do
      local base="${f%.*}"
      local out="${output_dir:-$(dirname "$f")}/${base##*/}.${dst_ext}"
      local fsize
      fsize=$(stat -f%z "$f" 2>/dev/null || echo 0)
      size_before=$(( size_before + fsize ))
      echo "  would convert: $f → $out"
    done
  elif declare -f _conv_parallel &>/dev/null; then
    export -f _bulk_convert_one 2>/dev/null || true
    export tmpfile total dst_ext output_dir size_before
    _conv_parallel -j "$parallel" _bulk_convert_one "${files[@]}"
  else
    local job_count=0
    local pids=()
    for f in "${files[@]}"; do
      local fsize
      fsize=$(stat -f%z "$f" 2>/dev/null || echo 0)
      size_before=$(( size_before + fsize ))
      ( _bulk_convert_one "$f" ) &
      pids+=($!)
      job_count=$(( job_count + 1 ))
      if [[ $job_count -ge $parallel ]]; then
        wait "${pids[0]}" 2>/dev/null || true
        pids=("${pids[@]:1}")
        job_count=$(( job_count - 1 ))
      fi
    done
    wait
  fi

  echo ""

  while IFS= read -r line; do
    if [[ "$line" == ok:* ]]; then
      done_count=$(( done_count + 1 ))
      local out_file="${line#ok:*:}"
      local osize
      osize=$(stat -f%z "$out_file" 2>/dev/null || echo 0)
      size_after=$(( size_after + osize ))
      printf "  [%d/%d] %s\n" "$done_count" "$total" "$(basename "${line#ok:}")"
    elif [[ "$line" == fail:* ]]; then
      fail_count=$(( fail_count + 1 ))
      _warn "FAILED: ${line#fail:}"
    fi
  done < "$tmpfile"
  rm -f "$tmpfile"

  echo ""
  _info "Summary: $done_count converted, $fail_count failed"
  if [[ $dry_run -eq 0 && $size_before -gt 0 ]]; then
    _info "Size: before=$(_conv_size_fmt $size_before) after=$(_conv_size_fmt $size_after)"
  fi
}

conv_dedupe() {
  local dir="${1:-.}"
  local do_delete=0
  local do_similar=0
  shift 1 2>/dev/null || true

  for arg in "$@"; do
    case "$arg" in
      --delete)  do_delete=1 ;;
      --similar) do_similar=1 ;;
    esac
  done

  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  _info "Hashing files in $dir ..."

  if [[ $do_similar -eq 1 ]]; then
    python3 - "$dir" "$do_delete" <<'PYEOF'
import sys, os, subprocess
from pathlib import Path

try:
    from PIL import Image
    import imagehash
    HAS_IMAGEHASH = True
except ImportError:
    HAS_IMAGEHASH = False
    print("Warning: Pillow/imagehash not available, falling back to exact match")

dir_path = Path(sys.argv[1])
do_delete = sys.argv[2] == "1"
IMAGE_EXTS = {'.jpg','.jpeg','.png','.webp','.heic','.bmp','.gif','.tiff'}

files = [f for f in dir_path.rglob('*') if f.is_file() and f.suffix.lower() in IMAGE_EXTS]
print(f"Checking {len(files)} images for similarity...")

if HAS_IMAGEHASH:
    hashes = {}
    groups = []
    for f in files:
        try:
            h = imagehash.phash(Image.open(f))
        except Exception:
            continue
        matched = False
        for key, group in hashes.items():
            if abs(h - key) <= 8:
                group.append(f)
                matched = True
                break
        if not matched:
            hashes[h] = [f]

    dupes = [(k, v) for k, v in hashes.items() if len(v) > 1]
    total_wasted = 0
    for _, group in dupes:
        group_sorted = sorted(group, key=lambda x: x.stat().st_mtime)
        keeper = group_sorted[0]
        print(f"\n  Group (keep: {keeper.name}):")
        for f in group_sorted[1:]:
            sz = f.stat().st_size
            total_wasted += sz
            print(f"    dupe: {f} ({sz//1024}KB)")
            if do_delete:
                subprocess.run(['trash', str(f)], check=False)
                print(f"      → trashed")
    print(f"\nSimilar duplicates: {sum(len(v)-1 for _,v in dupes)} ({total_wasted//1048576} MB wasted)")
else:
    # fall back to exact hash
    import hashlib
    hashes = {}
    for f in files:
        h = hashlib.sha256(f.read_bytes()).hexdigest()
        hashes.setdefault(h, []).append(f)
    dupes = {k: v for k, v in hashes.items() if len(v) > 1}
    total_wasted = sum(f.stat().st_size for v in dupes.values() for f in v[1:])
    for h, group in dupes.items():
        keeper = min(group, key=lambda x: x.stat().st_mtime)
        print(f"\n  Keep: {keeper}")
        for f in group:
            if f == keeper: continue
            print(f"    dupe: {f}")
            if do_delete:
                import subprocess
                subprocess.run(['trash', str(f)], check=False)
    print(f"\nDuplicates: {sum(len(v)-1 for v in dupes.values())} ({total_wasted//1048576} MB wasted)")
PYEOF
    return 0
  fi

  # Exact hash deduplication
  _info "Computing SHA-256 hashes..."
  declare -A hash_map
  local total_wasted=0
  local dupe_count=0

  while IFS= read -r -d '' f; do
    local h
    h=$(sha256sum "$f" | awk '{print $1}')
    if [[ -v "hash_map[$h]" ]]; then
      local sz
      sz=$(stat -f%z "$f" 2>/dev/null || echo 0)
      total_wasted=$(( total_wasted + sz ))
      dupe_count=$(( dupe_count + 1 ))
      echo "  dupe: $f"
      echo "  orig: ${hash_map[$h]}"
      echo ""
      if [[ $do_delete -eq 1 ]]; then
        local orig_mtime dup_mtime
        orig_mtime=$(stat -f%m "${hash_map[$h]}" 2>/dev/null || echo 0)
        dup_mtime=$(stat -f%m "$f" 2>/dev/null || echo 0)
        if [[ $dup_mtime -gt $orig_mtime ]]; then
          trash "$f" 2>/dev/null && _info "  Trashed (newer): $f"
        else
          trash "${hash_map[$h]}" 2>/dev/null && _info "  Trashed (newer): ${hash_map[$h]}"
          hash_map[$h]="$f"
        fi
      fi
    else
      hash_map[$h]="$f"
    fi
  done < <(find "$dir" -type f -print0 2>/dev/null)

  _ok "$dupe_count duplicates found ($(_conv_size_fmt $total_wasted) wasted)"
}

conv_rename_batch() {
  local pattern="$1"
  local dir="${2:-.}"
  local dry_run=0
  local use_exif=1
  shift 2 2>/dev/null || shift $# 2>/dev/null || true

  for arg in "$@"; do
    case "$arg" in
      --dry-run) dry_run=1 ;;
      --mtime)   use_exif=0 ;;
      --exif)    use_exif=1 ;;
    esac
  done

  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  local seq=1
  while IFS= read -r -d '' f; do
    local name ext date year month day ts
    name=$(basename "${f%.*}")
    ext="${f##*.}"

    if [[ $use_exif -eq 1 ]]; then
      ts=$(exiftool -DateTimeOriginal -d "%Y-%m-%d" -p '$DateTimeOriginal' "$f" 2>/dev/null || true)
    fi
    [[ -z "$ts" ]] && ts=$(date -r "$f" "+%Y-%m-%d" 2>/dev/null || date "+%Y-%m-%d")

    year="${ts:0:4}"
    month="${ts:5:2}"
    day="${ts:8:2}"
    date="${year}-${month}-${day}"

    local new_name="$pattern"
    new_name="${new_name//\{date\}/$date}"
    new_name="${new_name//\{year\}/$year}"
    new_name="${new_name//\{month\}/$month}"
    new_name="${new_name//\{day\}/$day}"
    new_name="${new_name//\{name\}/$name}"
    new_name="${new_name//\{ext\}/$ext}"

    if [[ "$new_name" =~ \{seq:([0-9]+)\} ]]; then
      local pad="${BASH_REMATCH[1]}"
      local padded
      padded=$(printf "%0${pad}d" "$seq")
      new_name="${new_name//\{seq:${pad}\}/$padded}"
    fi

    local dst="${f%/*}/${new_name}"

    if [[ $dry_run -eq 1 ]]; then
      echo "  $(basename "$f") → $new_name"
    else
      mv "$f" "$dst"
      _ok "Renamed: $(basename "$f") → $new_name"
    fi
    seq=$(( seq + 1 ))
  done < <(find "$dir" -maxdepth 1 -type f -not -name '.*' -print0 | sort -z)
}

conv_sort_type() {
  local dir="${1:-.}"
  local mode="move"
  local dry_run=0
  shift 1 2>/dev/null || true

  for arg in "$@"; do
    case "$arg" in
      --copy)    mode="copy" ;;
      --move)    mode="move" ;;
      --dry-run) dry_run=1  ;;
    esac
  done

  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  declare -A type_map=(
    [videos]="mp4 mkv avi mov webm flv wmv m4v ts mts"
    [images]="jpg jpeg png webp avif heic bmp tiff tif gif jxl"
    [audio]="mp3 opus aac flac wav m4a ogg wma"
    [docs]="pdf doc docx xls xlsx ppt pptx txt md rtf csv"
    [archives]="zip 7z tar gz bz2 xz rar"
  )

  declare -A ext_to_type
  for type in "${!type_map[@]}"; do
    for ext in ${type_map[$type]}; do
      ext_to_type[$ext]="$type"
    done
  done

  local moved=0
  while IFS= read -r -d '' f; do
    local ext="${f##*.}"
    ext="${ext,,}"
    local target_type="${ext_to_type[$ext]:-other}"
    local target_dir="${dir}/${target_type}"

    if [[ $dry_run -eq 1 ]]; then
      echo "  $mode: $f → ${target_dir}/"
    else
      mkdir -p "$target_dir"
      if [[ "$mode" == "move" ]]; then
        mv "$f" "${target_dir}/"
      else
        cp "$f" "${target_dir}/"
      fi
      moved=$(( moved + 1 ))
    fi
  done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)

  [[ $dry_run -eq 0 ]] && _ok "$(echo "$mode" | awk '{print toupper(substr($0,1,1))substr($0,2)}')d $moved files by type"
}

conv_sort_date() {
  local dir="${1:-.}"
  local fmt="${2:-%Y/%m}"
  local mode="move"
  local dry_run=0
  shift 2 2>/dev/null || shift $# 2>/dev/null || true

  for arg in "$@"; do
    case "$arg" in
      --copy)    mode="copy" ;;
      --move)    mode="move" ;;
      --dry-run) dry_run=1  ;;
    esac
  done

  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  local moved=0
  while IFS= read -r -d '' f; do
    local ts
    ts=$(exiftool -DateTimeOriginal -d "$fmt" -p '$DateTimeOriginal' "$f" 2>/dev/null || true)
    [[ -z "$ts" ]] && ts=$(date -r "$f" "+$fmt" 2>/dev/null || date "+$fmt")

    local target_dir="${dir}/${ts}"

    if [[ $dry_run -eq 1 ]]; then
      echo "  $mode: $(basename "$f") → ${target_dir}/"
    else
      mkdir -p "$target_dir"
      if [[ "$mode" == "move" ]]; then
        mv "$f" "${target_dir}/"
      else
        cp "$f" "${target_dir}/"
      fi
      moved=$(( moved + 1 ))
    fi
  done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)

  [[ $dry_run -eq 0 ]] && _ok "$(echo "$mode" | awk '{print toupper(substr($0,1,1))substr($0,2)}')d $moved files by date ($fmt)"
}

conv_remove_empty() {
  local dir="${1:-.}"
  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  local count
  count=$(find "$dir" -type d -empty 2>/dev/null | wc -l | tr -d ' ')
  find "$dir" -type d -empty -delete 2>/dev/null
  _ok "Removed $count empty directories in $dir"
}

conv_screenshot_detect() {
  local dir="${1:-.}"
  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  local target="${dir}/screenshots"
  local moved=0

  while IFS= read -r -d '' f; do
    local base
    base=$(basename "$f")

    local is_screenshot=0

    # Filename heuristics
    if [[ "$base" =~ ^Screenshot || "$base" =~ ^Screen\ Shot || "$base" =~ ^Bildschirmfoto ]]; then
      is_screenshot=1
    fi

    # Dimension heuristic: common screen resolutions
    if [[ $is_screenshot -eq 0 ]]; then
      local ext="${f##*.}"
      ext="${ext,,}"
      if [[ "$ext" =~ ^(jpg|jpeg|png|webp)$ ]]; then
        local dims
        dims=$(exiftool -ImageWidth -ImageHeight -p '$ImageWidth x $ImageHeight' "$f" 2>/dev/null || true)
        if [[ "$dims" =~ ^(2560\ x\ 1600|2560\ x\ 1440|1920\ x\ 1200|1920\ x\ 1080|3456\ x\ 2234|3024\ x\ 1964|2880\ x\ 1800|1440\ x\ 900)$ ]]; then
          is_screenshot=1
        fi
      fi
    fi

    if [[ $is_screenshot -eq 1 ]]; then
      mkdir -p "$target"
      mv "$f" "${target}/"
      moved=$(( moved + 1 ))
    fi
  done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)

  _ok "Moved $moved screenshots → ${target}/"
}
