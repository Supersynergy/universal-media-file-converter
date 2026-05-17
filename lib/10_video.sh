#!/usr/bin/env bash
# set -euo pipefail not used here — file is sourced into interactive shell

conv_video() {
  local input=$1
  local output=$2
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  _conv_start_timer
  _info "Converting: $(basename "$input") → $(basename "$output")"

  # Route through adaptive engine when CONV_BUDGET_MODE is set explicitly
  if [[ -n "${CONV_BUDGET_MODE:-}" && "${CONV_BUDGET_MODE}" != "balanced" ]] \
     && declare -f _conv_adaptive_video &>/dev/null; then
    _conv_adaptive_video "$input" "$output" "$CONV_BUDGET_MODE"
    _conv_done "$input" "$output"
    return $?
  fi

  local ext="${output##*.}"
  ext="${ext,,}"

  local in_codec
  in_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$input" 2>/dev/null || echo "unknown")

  local tmp_progress
  tmp_progress=$(mktemp /tmp/conv_progress.XXXXXX)

  _parse_ffmpeg_progress() {
    local duration_ms=0
    duration_ms=$(ffprobe -v error -show_entries format=duration \
      -of default=noprint_wrappers=1:nokey=1 "$input" 2>/dev/null || echo "0")
    duration_ms=$(awk "BEGIN { printf \"%d\", $duration_ms * 1000000 }")

    local out_time_us=0
    while IFS= read -r line; do
      if [[ "$line" == out_time_us=* ]]; then
        out_time_us="${line#out_time_us=}"
        if (( duration_ms > 0 && out_time_us > 0 )); then
          _conv_bar "$out_time_us" "$duration_ms"
        fi
      fi
    done < "$tmp_progress"
  }

  case "$ext" in
    mp4)
      if [[ "$in_codec" == "h264" ]]; then
        ffmpeg -y -i "$input" -c copy -map_metadata 0 \
          -progress "$tmp_progress" "$output" 2>/dev/null &
      else
        ffmpeg -y -i "$input" \
          -c:v h264_videotoolbox -b:v "$CONV_H264_BITRATE" \
          -c:a aac -b:a 192k \
          -map_metadata 0 \
          -progress "$tmp_progress" "$output" 2>/dev/null &
      fi
      ;;
    mkv)
      ffmpeg -y -i "$input" \
        -c:v hevc_videotoolbox -b:v "$CONV_H265_BITRATE" \
        -c:a copy \
        -map_metadata 0 \
        -progress "$tmp_progress" "$output" 2>/dev/null &
      ;;
    gif)
      if [[ "$CONV_RAM_TIER" == "high" ]] && command -v gifski &>/dev/null; then
        local tmp_frames
        tmp_frames=$(mktemp -d /tmp/conv_frames.XXXXXX)
        ffmpeg -y -i "$input" "$tmp_frames/frame%05d.png" 2>/dev/null
        gifski -o "$output" "$tmp_frames"/frame*.png
        rm -rf "$tmp_frames"
      else
        ffmpeg -y -i "$input" \
          -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
          -progress "$tmp_progress" "$output" 2>/dev/null &
      fi
      ;;
    webm)
      ffmpeg -y -i "$input" \
        -c:v libsvtav1 -preset "$CONV_AV1_SPEED" \
        -c:a libopus -b:a 128k \
        -map_metadata 0 \
        -progress "$tmp_progress" "$output" 2>/dev/null &
      ;;
    *)
      ffmpeg -y -i "$input" \
        -c:v h264_videotoolbox -b:v "$CONV_H264_BITRATE" \
        -map_metadata 0 \
        -progress "$tmp_progress" "$output" 2>/dev/null &
      ;;
  esac

  local ffmpeg_pid=$!
  # tail progress file while ffmpeg runs
  while kill -0 "$ffmpeg_pid" 2>/dev/null; do
    _parse_ffmpeg_progress
    sleep 0.5
  done
  wait "$ffmpeg_pid" || { _err "ffmpeg failed"; rm -f "$tmp_progress"; return 1; }
  rm -f "$tmp_progress"

  _conv_done "$input" "$output"
}

conv_probe() {
  local file=$1
  [[ ! -f "$file" ]] && { _err "File not found: $file"; return 1; }

  local json
  json=$(ffprobe -v quiet -print_format json -show_streams -show_format "$file" 2>/dev/null)

  local codec res fps bitrate duration channels hdr size
  codec=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); v=[s for s in d['streams'] if s.get('codec_type')=='video']; print(v[0]['codec_name'] if v else 'N/A')" 2>/dev/null || echo "N/A")
  res=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); v=[s for s in d['streams'] if s.get('codec_type')=='video']; print(f\"{v[0]['width']}x{v[0]['height']}\" if v else 'N/A')" 2>/dev/null || echo "N/A")
  fps=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); v=[s for s in d['streams'] if s.get('codec_type')=='video']; r=v[0].get('r_frame_rate','0/1') if v else '0/1'; n,dd=r.split('/'); print(f'{float(n)/float(dd):.2f}' if dd!='0' else 'N/A')" 2>/dev/null || echo "N/A")
  bitrate=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); br=d.get('format',{}).get('bit_rate','0'); print(f'{int(br)//1000} kbps' if br else 'N/A')" 2>/dev/null || echo "N/A")
  duration=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); dur=float(d.get('format',{}).get('duration','0')); m=int(dur//60); s=int(dur%60); print(f'{m}m {s}s')" 2>/dev/null || echo "N/A")
  channels=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); a=[s for s in d['streams'] if s.get('codec_type')=='audio']; print(a[0].get('channels','N/A') if a else 'N/A')" 2>/dev/null || echo "N/A")
  hdr=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); v=[s for s in d['streams'] if s.get('codec_type')=='video']; print('Yes' if v and v[0].get('color_transfer')=='smpte2084' else 'No')" 2>/dev/null || echo "No")
  size=$(_conv_size_fmt "$(stat -f%z "$file" 2>/dev/null || echo 0)")

  printf "┌─────────────────────────────────────┐\n"
  printf "│ %-35s │\n" "$(basename "$file")"
  printf "├─────────────────────────────────────┤\n"
  printf "│ Codec    : %-24s │\n" "$codec"
  printf "│ Res      : %-24s │\n" "$res"
  printf "│ FPS      : %-24s │\n" "$fps"
  printf "│ Bitrate  : %-24s │\n" "$bitrate"
  printf "│ Duration : %-24s │\n" "$duration"
  printf "│ Audio Ch : %-24s │\n" "$channels"
  printf "│ HDR      : %-24s │\n" "$hdr"
  printf "│ Size     : %-24s │\n" "$size"
  printf "└─────────────────────────────────────┘\n"
}

conv_trim() {
  local input=$1
  local start=$2
  local end=$3
  local output=${4:-""}
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  if [[ -z "$output" ]]; then
    local base="${input%.*}"
    local ext="${input##*.}"
    output="${base}_trim.${ext}"
  fi

  _conv_start_timer
  _info "Trimming: $start → $end"
  ffmpeg -y -ss "$start" -to "$end" -i "$input" -c copy "$output" 2>/dev/null \
    || { _err "Trim failed"; return 1; }
  _conv_done "$input" "$output"
}

conv_concat() {
  local output=$1
  shift
  local files=("$@")
  [[ ${#files[@]} -lt 2 ]] && { _err "Need at least 2 files"; return 1; }

  local tmp_list
  tmp_list=$(mktemp /tmp/conv_concat.XXXXXX)
  for f in "${files[@]}"; do
    [[ ! -f "$f" ]] && { _err "File not found: $f"; rm -f "$tmp_list"; return 1; }
    printf "file '%s'\n" "$(realpath "$f")" >> "$tmp_list"
  done

  local first_codec
  first_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "${files[0]}" 2>/dev/null || echo "unknown")

  local all_same=1
  for f in "${files[@]:1}"; do
    local c
    c=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
      -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null || echo "unknown")
    [[ "$c" != "$first_codec" ]] && { all_same=0; break; }
  done

  _conv_start_timer
  _info "Concatenating ${#files[@]} files → $(basename "$output")"

  if (( all_same == 1 )); then
    ffmpeg -y -f concat -safe 0 -i "$tmp_list" -c copy "$output" 2>/dev/null \
      || { _err "Concat failed"; rm -f "$tmp_list"; return 1; }
  else
    ffmpeg -y -f concat -safe 0 -i "$tmp_list" \
      -c:v h264_videotoolbox -b:v "$CONV_H264_BITRATE" \
      -c:a aac -b:a 192k "$output" 2>/dev/null \
      || { _err "Concat (re-encode) failed"; rm -f "$tmp_list"; return 1; }
  fi

  rm -f "$tmp_list"
  _ok "Concatenated → $output"
}

conv_split() {
  local input=$1
  local duration=$2
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  local base="${input%.*}"
  local ext="${input##*.}"

  _conv_start_timer
  _info "Splitting into ${duration}s segments"
  ffmpeg -y -i "$input" -f segment -segment_time "$duration" \
    -c copy -reset_timestamps 1 "${base}_%03d.${ext}" 2>/dev/null \
    || { _err "Split failed"; return 1; }
  _ok "Split complete"
}

conv_extract_audio() {
  local input=$1
  local format=${2:-"mp3"}
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  local base="${input%.*}"
  local output="${base}.${format}"

  _conv_start_timer
  _info "Extracting audio as $format"

  case "$format" in
    opus)
      ffmpeg -y -i "$input" -vn -c:a libopus -b:a 128k "$output" 2>/dev/null \
        || { _err "Audio extract failed"; return 1; }
      ;;
    *)
      ffmpeg -y -i "$input" -vn -c:a libmp3lame -q:a 2 "$output" 2>/dev/null \
        || { _err "Audio extract failed"; return 1; }
      ;;
  esac

  _conv_done "$input" "$output"
}

conv_thumbnail() {
  local input=$1
  local cols=${2:-4}
  local output=${3:-""}
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  local base="${input%.*}"
  [[ -z "$output" ]] && output="${base}_thumb.jpg"

  local total=16
  local rows=$(( (total + cols - 1) / cols ))

  local tmp_dir
  tmp_dir=$(mktemp -d /tmp/conv_thumb.XXXXXX)

  _info "Extracting $total frames for thumbnail sheet"

  local duration
  duration=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$input" 2>/dev/null || echo "60")
  local interval
  interval=$(awk "BEGIN { printf \"%f\", $duration / $total }")

  ffmpeg -y -i "$input" -vf "fps=1/${interval}" \
    -vframes "$total" "${tmp_dir}/frame%04d.jpg" 2>/dev/null \
    || { _err "Frame extraction failed"; rm -rf "$tmp_dir"; return 1; }

  magick montage "${tmp_dir}"/frame*.jpg \
    -tile "${cols}x${rows}" -geometry +2+2 "$output" 2>/dev/null \
    || { _err "Montage failed"; rm -rf "$tmp_dir"; return 1; }

  rm -rf "$tmp_dir"
  _ok "Thumbnail → $output"
}

conv_hdr_sdr() {
  local input=$1
  local output=${2:-""}
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  if [[ -z "$output" ]]; then
    local base="${input%.*}"
    local ext="${input##*.}"
    output="${base}_sdr.${ext}"
  fi

  _conv_start_timer
  _info "HDR → SDR tone mapping"

  local filter="zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p"

  ffmpeg -y -i "$input" \
    -vf "$filter" \
    -c:v h264_videotoolbox -b:v "$CONV_H264_BITRATE" \
    -c:a copy "$output" 2>/dev/null \
    || { _err "HDR→SDR conversion failed"; return 1; }

  _conv_done "$input" "$output"
}

conv_subtitle_extract() {
  local input=$1
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  local base="${input%.*}"
  local output="${base}.srt"

  _info "Extracting subtitles"
  ffmpeg -y -i "$input" -map 0:s:0 "$output" 2>/dev/null \
    || { _err "Subtitle extraction failed (no subtitle stream?)"; return 1; }
  _ok "Subtitles → $output"
}

conv_subtitle_burn() {
  local video=$1
  local srt=$2
  local output=${3:-""}
  [[ ! -f "$video" ]] && { _err "Video not found: $video"; return 1; }
  [[ ! -f "$srt" ]] && { _err "Subtitle not found: $srt"; return 1; }

  if [[ -z "$output" ]]; then
    local base="${video%.*}"
    local ext="${video##*.}"
    output="${base}_burned.${ext}"
  fi

  _conv_start_timer
  _info "Burning subtitles"

  local srt_abs
  srt_abs=$(realpath "$srt")

  ffmpeg -y -i "$video" \
    -vf "subtitles='${srt_abs}'" \
    -c:v h264_videotoolbox -b:v "$CONV_H264_BITRATE" \
    -c:a copy "$output" 2>/dev/null \
    || { _err "Subtitle burn failed"; return 1; }

  _conv_done "$video" "$output"
}

conv_frame() {
  local input=$1
  local timestamp=$2
  local output=${3:-""}
  [[ ! -f "$input" ]] && { _err "Input not found: $input"; return 1; }

  if [[ -z "$output" ]]; then
    local base="${input%.*}"
    local ts_safe="${timestamp//:/-}"
    output="${base}_frame_${ts_safe}.jpg"
  fi

  _info "Extracting frame at $timestamp"
  ffmpeg -y -ss "$timestamp" -i "$input" -vframes 1 "$output" 2>/dev/null \
    || { _err "Frame extraction failed"; return 1; }
  _ok "Frame → $output"
}
