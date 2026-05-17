#!/usr/bin/env bash
# 20_flow.sh — Smart + Fast + Adaptive Flow Engine
# Patterns stolen from: libmagic, BuildKit, GNU parallel, Watchman, httpx, rsync, ffmpeg, claude-token-saver

CONV_CACHE_DIR="${HOME}/.cache/conv"
CONV_BUDGET_MODE="${CONV_BUDGET_MODE:-balanced}"

# ── Pattern 1: Content Sniffer ──────────────────────────────────────────────

declare -A _CONV_SNIFF_CACHE 2>/dev/null || true

_conv_sniff() {
  local file="$1"
  [[ -f "$file" ]] || { echo "other"; return 1; }

  local cache_key="$file"
  if [[ -n "${_CONV_SNIFF_CACHE[$cache_key]:-}" ]]; then
    echo "${_CONV_SNIFF_CACHE[$cache_key]}"
    return 0
  fi

  local mime
  mime=$(file --mime-type -b "$file" 2>/dev/null || echo "application/octet-stream")

  local category
  case "$mime" in
    video/*)                    category="video"   ;;
    audio/*)                    category="audio"   ;;
    image/*)                    category="image"   ;;
    application/pdf)            category="pdf"     ;;
    application/zip|\
    application/x-7z-compressed|\
    application/x-tar|\
    application/gzip|\
    application/x-bzip2|\
    application/x-xz|\
    application/x-rar*)         category="archive" ;;
    text/*)                     category="text"    ;;
    *)
      local ext="${file##*.}"
      case "${ext}" in
        mp4|mkv|avi|mov|webm|flv|wmv|m4v|ts|mts) category="video"   ;;
        mp3|opus|aac|flac|wav|m4a|ogg)            category="audio"   ;;
        jpg|jpeg|png|webp|avif|heic|bmp|tiff|jxl) category="image"   ;;
        pdf)                                       category="pdf"     ;;
        zip|7z|tar|gz|bz2|xz|rar)                 category="archive" ;;
        txt|md|csv|json|xml|html)                  category="text"    ;;
        *)                                         category="other"   ;;
      esac
      ;;
  esac

  _CONV_SNIFF_CACHE[$cache_key]="$category"
  echo "$category"
}

_conv_suggest_tool() {
  local file="$1"
  local category
  category=$(_conv_sniff "$file")

  case "$category" in
    video)
      echo "ffmpeg -hwaccel auto"
      ;;
    audio)
      echo "ffmpeg"
      ;;
    pdf)
      echo "qpdf"
      ;;
    archive)
      local fsize
      fsize=$(stat -f%z "$file" 2>/dev/null || echo 0)
      if [[ $fsize -gt 104857600 ]]; then
        echo "7z"
      else
        echo "unzip"
      fi
      ;;
    image)
      local fsize
      fsize=$(stat -f%z "$file" 2>/dev/null || echo 0)
      if [[ $fsize -lt 2097152 ]]; then
        echo "sips"
      elif [[ "${CONV_RAM_TIER:-medium}" == "high" ]]; then
        echo "vips"
      else
        echo "magick"
      fi
      ;;
    *)
      echo "file"
      ;;
  esac
}

# ── Pattern 2: 4-Stage Fallback Chain ──────────────────────────────────────

_conv_fallback() {
  local stages=()
  local args=()
  local in_args=0

  for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
      in_args=1
    elif [[ $in_args -eq 0 ]]; then
      stages+=("$arg")
    else
      args+=("$arg")
    fi
  done

  for stage in "${stages[@]}"; do
    if ! declare -f "$stage" &>/dev/null; then
      _warn "Fallback: stage '$stage' not defined, skipping"
      continue
    fi
    "$stage" "${args[@]}"
    local rc=$?
    if [[ $rc -eq 0 ]]; then
      return 0
    elif [[ $rc -eq 2 ]]; then
      _err "Fallback: hard fail at stage '$stage'"
      return 2
    fi
  done

  _err "All fallback stages failed"
  return 1
}

# ── Pattern 3: Content-Addressable Cache ───────────────────────────────────

_conv_cache_key() {
  local file="$1" op="$2"
  local fhash
  fhash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
  printf "%s" "${fhash}:${op}" | sha256sum | awk '{print $1}'
}

_conv_cache_get() {
  local key="$1"
  local prefix="${key:0:2}"
  local cached="${CONV_CACHE_DIR}/${prefix}/${key}"
  if [[ -f "$cached" ]]; then
    echo "$cached"
    return 0
  fi
  return 1
}

_conv_cache_put() {
  local key="$1" result="$2"
  local prefix="${key:0:2}"
  local dest="${CONV_CACHE_DIR}/${prefix}/${key}"
  mkdir -p "${CONV_CACHE_DIR}/${prefix}"
  ln "$result" "$dest" 2>/dev/null || cp "$result" "$dest"
}

_conv_cache_clear() {
  local older_than=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --older-than) older_than="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ -n "$older_than" ]]; then
    local days="${older_than//[^0-9]/}"
    find "$CONV_CACHE_DIR" -type f -mtime "+${days}" -delete 2>/dev/null
    _ok "Cache: cleared entries older than ${days} days"
  else
    rm -rf "$CONV_CACHE_DIR"
    _ok "Cache: cleared all entries"
  fi
}

_conv_flow_stats() {
  local total hits misses size
  total=$(find "$CONV_CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
  size=$(du -sh "$CONV_CACHE_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
  _info "Flow Engine Cache:"
  _info "  Entries : $total"
  _info "  Size    : $size"
  _info "  Dir     : $CONV_CACHE_DIR"
  _info "  Budget  : ${CONV_BUDGET_MODE}"
}

# ── Pattern 4: Parallel Work-Stealing ──────────────────────────────────────

_conv_parallel() {
  local jobs="${CONV_CORES:-4}"
  local show_progress=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -j) jobs="$2"; shift 2 ;;
      -p) show_progress=1; shift ;;
      *)  break ;;
    esac
  done

  local fn="$1"; shift
  local items=("$@")
  local total=${#items[@]}
  [[ $total -eq 0 ]] && return 0

  local tmpcount
  tmpcount=$(mktemp)
  echo "0" > "$tmpcount"

  local done_n=0
  local active=0

  _run_one_item() {
    local item="$1"
    "$fn" "$item"
  }

  for item in "${items[@]}"; do
    _run_one_item "$item" &
    active=$(( active + 1 ))
    done_n=$(( done_n + 1 ))
    if [[ $show_progress -eq 1 ]]; then
      printf "\r[%d/%d] %s" "$done_n" "$total" "$(basename "$item")" >&2
    fi
    while [[ $active -ge $jobs ]]; do
      wait -n 2>/dev/null || { wait; active=0; break; }
      active=$(( active - 1 ))
    done
  done
  wait
  [[ $show_progress -eq 1 ]] && echo "" >&2
  return 0
  local rc=$?
  rm -f "$tmpcount"
  return $rc
}

# ── Pattern 5: Debounced Watch ─────────────────────────────────────────────

_conv_watch() {
  local watch_dir="$1" handler="$2"
  local debounce=2
  local ignore_pattern=""

  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --debounce) debounce="$2"; shift 2 ;;
      --ignore)   ignore_pattern="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if ! command -v fswatch &>/dev/null; then
    _warn "fswatch not installed. Install: brew install fswatch"
    return 1
  fi

  _info "Watching: $watch_dir (debounce: ${debounce}s)"

  local pending
  pending=$(mktemp)
  local last_event=0

  fswatch -0 "$watch_dir" | while IFS= read -r -d '' fpath; do
    [[ -n "$ignore_pattern" && "$fpath" == *"$ignore_pattern"* ]] && continue
    [[ ! -f "$fpath" ]] && continue

    echo "$fpath" >> "$pending"
    last_event=$(date +%s)

    sleep "$debounce"
    local now
    now=$(date +%s)
    local diff=$(( now - last_event ))
    if [[ $diff -ge $debounce ]]; then
      while IFS= read -r queued; do
        local mtime_before mtime_after
        mtime_before=$(stat -f%m "$queued" 2>/dev/null || echo 0)
        sleep 0.1
        mtime_after=$(stat -f%m "$queued" 2>/dev/null || echo 0)
        if [[ "$mtime_before" == "$mtime_after" ]]; then
          "$handler" "$queued"
        fi
      done < "$pending"
      > "$pending"
    fi
  done

  rm -f "$pending"
}

# ── Pattern 6: Adaptive Quality Router ─────────────────────────────────────

_conv_adaptive_video() {
  local input="$1" output="$2"
  local target="${3:-${CONV_BUDGET_MODE:-balanced}}"
  local hw="${CONV_HW_TIER:-base}"

  declare -A _pipelines
  _pipelines[speed:ultra]="h264_videotoolbox -b:v 8M -preset ultrafast"
  _pipelines[speed:max]="h264_videotoolbox -b:v 8M -preset ultrafast"
  _pipelines[speed:pro]="h264_videotoolbox -b:v 6M"
  _pipelines[speed:base]="libx264 -preset veryfast -crf 28"
  _pipelines[speed:intel]="libx264 -preset veryfast -crf 28"
  _pipelines[balanced:ultra]="hevc_videotoolbox -b:v 8M"
  _pipelines[balanced:max]="hevc_videotoolbox -b:v 8M"
  _pipelines[balanced:pro]="hevc_videotoolbox -b:v 6M"
  _pipelines[balanced:base]="libx265 -preset medium -crf 26"
  _pipelines[balanced:intel]="libx265 -preset medium -crf 26"
  _pipelines[quality:ultra]="libsvtav1 -preset 4 -crf 28"
  _pipelines[quality:max]="libsvtav1 -preset 4 -crf 28"
  _pipelines[quality:pro]="libsvtav1 -preset 6 -crf 30"
  _pipelines[quality:base]="libsvtav1 -preset 8 -crf 32"
  _pipelines[quality:intel]="libsvtav1 -preset 8 -crf 32"
  _pipelines[archival:ultra]="libsvtav1 -preset 2 -crf 20"
  _pipelines[archival:max]="libsvtav1 -preset 2 -crf 20"
  _pipelines[archival:pro]="libsvtav1 -preset 2 -crf 20"
  _pipelines[archival:base]="libsvtav1 -preset 4 -crf 22"
  _pipelines[archival:intel]="libsvtav1 -preset 4 -crf 22"

  local lookup="${target}:${hw}"
  local codec_args="${_pipelines[$lookup]:-libx264 -preset medium -crf 26}"

  _info "Adaptive encode: target=$target hw=$hw → $codec_args"
  ffmpeg -y -i "$input" -c:v $codec_args -c:a aac -b:a 192k -map_metadata 0 "$output"
}

# ── Pattern 7: Streaming Pipes ─────────────────────────────────────────────

conv_pipe_heic2jpg() {
  local tmp_in tmp_out
  tmp_in=$(mktemp /tmp/conv_pipe_in.XXXXXX.heic)
  tmp_out=$(mktemp /tmp/conv_pipe_out.XXXXXX.jpg)
  cat > "$tmp_in"
  sips -s format jpeg "$tmp_in" --out "$tmp_out" &>/dev/null \
    || magick "$tmp_in" "$tmp_out"
  cat "$tmp_out"
  rm -f "$tmp_in" "$tmp_out"
}

conv_pipe_resize() {
  local width="${1:-1920}"
  local tmp_in tmp_out ext="jpg"
  tmp_in=$(mktemp /tmp/conv_pipe_in.XXXXXX.${ext})
  tmp_out=$(mktemp /tmp/conv_pipe_out.XXXXXX.${ext})
  cat > "$tmp_in"
  if [[ "${CONV_RAM_TIER:-medium}" == "high" ]]; then
    vips thumbnail "$tmp_in" "$tmp_out" "$width" &>/dev/null
  else
    sips --resampleWidth "$width" "$tmp_in" --out "$tmp_out" &>/dev/null
  fi
  cat "$tmp_out"
  rm -f "$tmp_in" "$tmp_out"
}

conv_pipe_strip() {
  local tmp_in tmp_out ext="jpg"
  tmp_in=$(mktemp /tmp/conv_pipe_in.XXXXXX.${ext})
  tmp_out=$(mktemp /tmp/conv_pipe_out.XXXXXX.${ext})
  cat > "$tmp_in"
  exiftool -all= -o "$tmp_out" "$tmp_in" &>/dev/null \
    || cp "$tmp_in" "$tmp_out"
  cat "$tmp_out"
  rm -f "$tmp_in" "$tmp_out"
}

# ── Pattern 8: Retry with Exponential Backoff ──────────────────────────────

_conv_retry() {
  local max_attempts="$1"; shift
  local wait=1
  local attempt=1

  while [[ $attempt -le $max_attempts ]]; do
    "$@" && return 0
    [[ $attempt -eq $max_attempts ]] && break
    _warn "Retry $attempt/$max_attempts failed, waiting ${wait}s..."
    sleep "$wait"
    wait=$(( wait * 2 ))
    attempt=$(( attempt + 1 ))
  done

  _err "All $max_attempts attempts failed: $*"
  return 1
}

# ── Pattern 9: Incremental Processing ──────────────────────────────────────

_CONV_MANIFEST="${CONV_CACHE_DIR}/manifest.json"

_conv_incremental() {
  local src="$1" dst="$2"; shift 2
  local cmd=("$@")

  mkdir -p "$CONV_CACHE_DIR"

  local src_hash
  src_hash=$(sha256sum "$src" 2>/dev/null | awk '{print $1}')

  if [[ -f "$dst" ]]; then
    local src_mtime dst_mtime
    src_mtime=$(stat -f%m "$src" 2>/dev/null || echo 0)
    dst_mtime=$(stat -f%m "$dst" 2>/dev/null || echo 0)

    if [[ $src_mtime -le $dst_mtime ]]; then
      local recorded=""
      if [[ -f "$_CONV_MANIFEST" ]]; then
        recorded=$(python3 -c "
import json,sys
d=json.load(open('$_CONV_MANIFEST'))
print(d.get('$(basename "$src")', {}).get('hash',''))
" 2>/dev/null || true)
      fi
      if [[ "$recorded" == "$src_hash" ]]; then
        _info "Incremental: skip (unchanged) $(basename "$src")"
        return 0
      fi
    fi
  fi

  "${cmd[@]}" && {
    python3 -c "
import json,os
mf='$_CONV_MANIFEST'
d={}
if os.path.exists(mf):
    try: d=json.load(open(mf))
    except: pass
d['$(basename "$src")']={'hash':'$src_hash','dst':'$dst'}
json.dump(d,open(mf,'w'),indent=2)
" 2>/dev/null || true
  }
}

# ── Pattern 10: Time-Budget Aware ──────────────────────────────────────────

_conv_budget() {
  local budget_seconds="$1" fn="$2"; shift 2
  local args=("$@")

  if command -v timeout &>/dev/null; then
    timeout "$budget_seconds" "$fn" "${args[@]}"
    return $?
  else
    "$fn" "${args[@]}" &
    local pid=$!
    local elapsed=0
    while kill -0 $pid 2>/dev/null; do
      sleep 1
      elapsed=$(( elapsed + 1 ))
      if [[ $elapsed -ge $budget_seconds ]]; then
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        return 124
      fi
    done
    wait "$pid"
    return $?
  fi
}

# Ensure cache dir exists
mkdir -p "$CONV_CACHE_DIR"
