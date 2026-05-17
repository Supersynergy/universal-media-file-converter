#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]:-}" != "${0}" ]] || set -euo pipefail

_conv_report_classify() {
  local ext="${1,,}"
  case "$ext" in
    mp4|mkv|avi|mov|webm|flv|wmv|m4v|ts|mts) echo "videos" ;;
    jpg|jpeg|png|webp|avif|heic|bmp|tiff|tif|gif|jxl) echo "images" ;;
    mp3|opus|aac|flac|wav|m4a|ogg|wma) echo "audio" ;;
    pdf|doc|docx|xls|xlsx|ppt|pptx|txt|md|rtf|csv) echo "docs" ;;
    *) echo "other" ;;
  esac
}

conv_report() {
  local dir="${1:-.}"
  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  _info "Media audit: $dir"

  python3 - "$dir" <<'PYEOF'
import sys, os
from pathlib import Path
from collections import defaultdict

dir_path = Path(sys.argv[1])

VIDEO_EXT  = {'.mp4','.mkv','.avi','.mov','.webm','.flv','.wmv','.m4v','.ts','.mts'}
IMAGE_EXT  = {'.jpg','.jpeg','.png','.webp','.avif','.heic','.bmp','.tiff','.tif','.gif','.jxl'}
AUDIO_EXT  = {'.mp3','.opus','.aac','.flac','.wav','.m4a','.ogg','.wma'}
DOC_EXT    = {'.pdf','.doc','.docx','.xls','.xlsx','.ppt','.pptx','.txt','.md','.rtf','.csv'}

def classify(ext):
    e = ext.lower()
    if e in VIDEO_EXT: return 'videos'
    if e in IMAGE_EXT: return 'images'
    if e in AUDIO_EXT: return 'audio'
    if e in DOC_EXT:   return 'docs'
    return 'other'

def fmt(b):
    for u in ['B','KB','MB','GB','TB']:
        if b < 1024: return f"{b:.1f} {u}"
        b /= 1024
    return f"{b:.1f} PB"

type_files  = defaultdict(list)
type_sizes  = defaultdict(int)
fmt_counts  = defaultdict(int)
all_files   = []

for f in dir_path.rglob('*'):
    if not f.is_file(): continue
    ext  = f.suffix
    sz   = f.stat().st_size
    cat  = classify(ext)
    type_files[cat].append(f)
    type_sizes[cat] += sz
    fmt_counts[ext.lower()] += 1
    all_files.append((f, sz))

print("\n── By Type ────────────────────────────────────")
print(f"  {'Type':<12} {'Files':>6}  {'Size':>10}")
print(f"  {'────':<12} {'─────':>6}  {'────':>10}")
total_files = 0
total_size  = 0
for cat in ['videos','images','audio','docs','other']:
    n = len(type_files[cat])
    s = type_sizes[cat]
    total_files += n
    total_size  += s
    print(f"  {cat:<12} {n:>6}  {fmt(s):>10}")
print(f"  {'────':<12} {'─────':>6}  {'────':>10}")
print(f"  {'TOTAL':<12} {total_files:>6}  {fmt(total_size):>10}")

print("\n── Top 10 Largest Files ───────────────────────")
for f, sz in sorted(all_files, key=lambda x: -x[1])[:10]:
    print(f"  {fmt(sz):>10}  {f.name}")

print("\n── Format Distribution ────────────────────────")
for ext, cnt in sorted(fmt_counts.items(), key=lambda x: -x[1])[:20]:
    bar = '█' * min(cnt, 40)
    print(f"  {ext:<8} {cnt:>5}  {bar}")

print()
PYEOF
}

conv_age_report() {
  local dir="${1:-.}"
  local days="${2:-365}"
  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  _info "Files older than $days days in $dir"

  python3 - "$dir" "$days" <<'PYEOF'
import sys, os, time
from pathlib import Path
from collections import defaultdict

dir_path = Path(sys.argv[1])
cutoff   = time.time() - int(sys.argv[2]) * 86400

VIDEO_EXT  = {'.mp4','.mkv','.avi','.mov','.webm','.flv','.wmv','.m4v','.ts','.mts'}
IMAGE_EXT  = {'.jpg','.jpeg','.png','.webp','.avif','.heic','.bmp','.tiff','.tif','.gif','.jxl'}
AUDIO_EXT  = {'.mp3','.opus','.aac','.flac','.wav','.m4a','.ogg','.wma'}
DOC_EXT    = {'.pdf','.doc','.docx','.xls','.xlsx','.ppt','.pptx','.txt','.md','.rtf','.csv'}

def classify(ext):
    e = ext.lower()
    if e in VIDEO_EXT: return 'videos'
    if e in IMAGE_EXT: return 'images'
    if e in AUDIO_EXT: return 'audio'
    if e in DOC_EXT:   return 'docs'
    return 'other'

def fmt(b):
    for u in ['B','KB','MB','GB','TB']:
        if b < 1024: return f"{b:.1f} {u}"
        b /= 1024
    return f"{b:.1f} PB"

type_files = defaultdict(int)
type_sizes = defaultdict(int)

for f in dir_path.rglob('*'):
    if not f.is_file(): continue
    st = f.stat()
    if st.st_mtime < cutoff:
        cat = classify(f.suffix)
        type_files[cat] += 1
        type_sizes[cat] += st.st_size

print(f"\n  {'Type':<12} {'Files':>6}  {'Reclaimable':>12}")
print(f"  {'────':<12} {'─────':>6}  {'───────────':>12}")
total_n = total_s = 0
for cat in ['videos','images','audio','docs','other']:
    n = type_files[cat]; s = type_sizes[cat]
    total_n += n; total_s += s
    if n: print(f"  {cat:<12} {n:>6}  {fmt(s):>12}")
print(f"  {'TOTAL':<12} {total_n:>6}  {fmt(total_s):>12}")
print()
PYEOF
}

conv_format_stats() {
  local dir="${1:-.}"
  [[ -d "$dir" ]] || { _err "Directory not found: $dir"; return 1; }

  local parallel="${CONV_CORES:-4}"
  _info "Probing video/audio files in $dir ..."

  local tmpfile
  tmpfile=$(mktemp)

  local VIDEO_AUDIO_EXT=(mp4 mkv avi mov webm flv wmv m4v ts mts mp3 opus aac flac wav m4a ogg wma)
  local pattern
  pattern=$(IFS='|'; echo "${VIDEO_AUDIO_EXT[*]}")

  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$dir" -type f -regextype posix-extended \
    -iregex ".*\.(${pattern})" -print0 2>/dev/null)

  local total=${#files[@]}
  [[ $total -gt 0 ]] || { _warn "No video/audio files found"; return 0; }

  _info "Probing $total files (parallel=$parallel)..."

  local sem=0
  for f in "${files[@]}"; do
    (
      ffprobe -v quiet -print_format json -show_streams -show_format "$f" 2>/dev/null \
        | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except:
    sys.exit(0)
fmt=d.get('format',{})
streams=d.get('streams',[])
vcodec=acodec=width=height=bitrate=''
for s in streams:
    ct=s.get('codec_type','')
    if ct=='video' and not vcodec:
        vcodec=s.get('codec_name','')
        width=s.get('width','')
        height=s.get('height','')
    elif ct=='audio' and not acodec:
        acodec=s.get('codec_name','')
bitrate=fmt.get('bit_rate','')
if bitrate: bitrate=str(int(bitrate)//1000)+'kbps'
res=f'{width}x{height}' if width else ''
print(f'{vcodec or acodec}\t{res}\t{bitrate}')
" >> "$tmpfile"
    ) &
    sem=$(( sem + 1 ))
    if [[ $sem -ge $parallel ]]; then
      wait; sem=0
    fi
  done
  wait

  python3 - "$tmpfile" "$total" <<'PYEOF'
import sys
from collections import defaultdict, Counter

tmpfile = sys.argv[1]
total   = int(sys.argv[2])

codecs   = Counter()
resols   = Counter()
bitrates = []

with open(tmpfile) as fh:
    for line in fh:
        parts = line.strip().split('\t')
        if len(parts) < 3: continue
        codec, res, br = parts
        if codec: codecs[codec] += 1
        if res:   resols[res]   += 1
        if br:
            try:
                bitrates.append(int(br.replace('kbps','')))
            except: pass

def fmt(b):
    for u in ['B','KB','MB','GB']:
        if b < 1024: return f"{b:.1f}{u}"
        b /= 1024
    return f"{b:.1f}TB"

print(f"\n── Codec Distribution ({total} files) ──────────")
for codec, n in codecs.most_common(15):
    bar = '█' * min(n * 30 // max(codecs.values(), default=1), 30)
    print(f"  {codec:<12} {n:>4}  {bar}")

print(f"\n── Resolution Histogram ────────────────────────")
for res, n in resols.most_common(10):
    print(f"  {res:<16} {n:>4}")

if bitrates:
    avg = sum(bitrates) // len(bitrates)
    print(f"\n── Bitrate ─────────────────────────────────────")
    print(f"  avg: {avg} kbps  min: {min(bitrates)} kbps  max: {max(bitrates)} kbps")
print()
PYEOF

  rm -f "$tmpfile"
}
