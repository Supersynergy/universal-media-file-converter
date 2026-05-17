#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail

conv_audio() {
  local input="$1" output="$2"
  local ext="${output##*.}"
  local ffargs=()

  case "${ext,,}" in
    mp3)  ffargs=(-codec:a libmp3lame -q:a 2) ;;
    opus) ffargs=(-codec:a libopus -b:a 128k) ;;
    aac|m4a) ffargs=(-codec:a aac_at) ;;
    wav)  ffargs=(-codec:a pcm_s16le) ;;
    flac) ffargs=(-codec:a flac) ;;
    *)    _err "Unsupported audio format: $ext"; return 1 ;;
  esac

  _info "Audio → $ext: $(basename "$input")"
  ffmpeg -i "$input" -map_metadata 0 "${ffargs[@]}" "$output" -y 2>/dev/null
  _conv_done "$input" "$output"
}

conv_normalize() {
  local files=("$@")
  for input in "${files[@]}"; do
    local base="${input%.*}" ext="${input##*.}"
    local output="${base}_norm.${ext}"

    _info "Loudnorm 2-pass: $(basename "$input")"

    local stats
    stats=$(ffmpeg -i "$input" -af "loudnorm=I=-16:LRA=11:TP=-1:print_format=json" \
      -f null - 2>&1 | grep -A 20 '{' || true)

    local measured_I measured_LRA measured_TP measured_thresh offset
    measured_I=$(echo "$stats" | grep '"input_i"' | grep -o '[-0-9.]*')
    measured_LRA=$(echo "$stats" | grep '"input_lra"' | grep -o '[-0-9.]*')
    measured_TP=$(echo "$stats" | grep '"input_tp"' | grep -o '[-0-9.]*')
    measured_thresh=$(echo "$stats" | grep '"input_thresh"' | grep -o '[-0-9.]*')
    offset=$(echo "$stats" | grep '"target_offset"' | grep -o '[-0-9.]*')

    ffmpeg -i "$input" \
      -af "loudnorm=I=-16:LRA=11:TP=-1:measured_I=${measured_I}:measured_LRA=${measured_LRA}:measured_TP=${measured_TP}:measured_thresh=${measured_thresh}:offset=${offset}:linear=true" \
      -map_metadata 0 "$output" -y 2>/dev/null

    _conv_done "$input" "$output"
  done
}

conv_split_silence() {
  local input="$1"
  local min_duration="${2:-0.5}"
  local noise="${3:--40dB}"
  local base="${input%.*}" ext="${input##*.}"

  _info "Detecting silence in $(basename "$input")"

  local silence_log
  silence_log=$(ffmpeg -i "$input" -af "silencedetect=noise=${noise}:d=${min_duration}" \
    -f null - 2>&1 | grep -E 'silence_(start|end)' || true)

  local -a starts=() ends=()
  while IFS= read -r line; do
    if [[ "$line" =~ silence_start:\ ([0-9.]+) ]]; then
      starts+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ silence_end:\ ([0-9.]+) ]]; then
      ends+=("${BASH_REMATCH[1]}")
    fi
  done <<< "$silence_log"

  if [[ ${#ends[@]} -eq 0 ]]; then
    _warn "No silence detected"; return 0
  fi

  local segment_times
  segment_times=$(IFS=','; echo "${ends[*]}")

  ffmpeg -i "$input" -f segment -segment_times "$segment_times" \
    -reset_timestamps 1 -map_metadata 0 \
    "${base}_part_%03d.${ext}" -y 2>/dev/null

  _ok "Split complete: $(basename "$base")"
}

conv_waveform() {
  local input="$1"
  local output="${2:-${input%.*}_waveform.png}"
  local width="${3:-1920}"
  local height="${4:-200}"

  _info "Waveform: $(basename "$input")"
  ffmpeg -i "$input" \
    -filter_complex "showwavespic=s=${width}x${height}:colors=white" \
    -frames:v 1 "$output" -y 2>/dev/null
  _conv_done "$input" "$output"
}
