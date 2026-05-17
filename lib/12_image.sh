#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail

conv_image() {
  local input="$1" output="$2"
  local in_ext="${input##*.}" out_ext="${output##*.}"

  _info "Image → ${out_ext}: $(basename "$input")"

  # Use flow engine tool suggestion when available
  local _suggested_tool=""
  if declare -f _conv_suggest_tool &>/dev/null; then
    _suggested_tool=$(_conv_suggest_tool "$input" 2>/dev/null)
  fi

  case "${out_ext,,}" in
    heic|heif)
      magick "$input" -profile sRGB "$output" 2>/dev/null || magick "$input" "$output"
      ;;
    avif)
      magick "$input" -quality 80 "$output"
      ;;
    jxl)
      magick "$input" "$output"
      ;;
    webp)
      cwebp -q 80 "$input" -o "$output" 2>/dev/null
      ;;
    jpg|jpeg)
      if [[ "${in_ext,,}" == "heic" || "${in_ext,,}" == "heif" ]]; then
        sips -s format jpeg "$input" --out "$output" 2>/dev/null
      elif [[ "$_suggested_tool" == "sips" ]]; then
        sips -s format jpeg "$input" --out "$output" 2>/dev/null \
          || magick "$input" -profile sRGB -quality 85 "$output"
      elif [[ "$_suggested_tool" == "vips" ]]; then
        vips copy "$input" "$output" 2>/dev/null \
          || magick "$input" -profile sRGB -quality 85 "$output"
      else
        magick "$input" -profile sRGB -quality 85 "$output" 2>/dev/null || magick "$input" "$output"
      fi
      ;;
    png)
      if [[ "$_suggested_tool" == "vips" ]]; then
        vips copy "$input" "$output" 2>/dev/null || magick "$input" "$output"
      else
        magick "$input" "$output"
      fi
      ;;
    *)
      magick "$input" "$output"
      ;;
  esac

  _conv_done "$input" "$output"
}

conv_resize() {
  local input="$1" width="$2"
  local output="${3:-${input%.*}_${width}w.${input##*.}}"
  local ram_gb
  ram_gb=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 8589934592) / 1073741824 ))

  _info "Resize → ${width}px: $(basename "$input")"

  if [[ $ram_gb -ge 32 ]]; then
    vips thumbnail "$input" "$output" "$width" 2>/dev/null
  else
    sips --resampleWidth "$width" "$input" --out "$output" 2>/dev/null
  fi

  _conv_done "$input" "$output"
}

conv_crop() {
  local input="$1" geometry="$2"
  local output="${3:-${input%.*}_crop.${input##*.}}"

  _info "Crop ${geometry}: $(basename "$input")"
  magick "$input" -crop "$geometry" +repage "$output"
  _conv_done "$input" "$output"
}

conv_auto_rotate() {
  local files=("$@")
  for f in "${files[@]}"; do
    local orient
    orient=$(exiftool -Orientation -n -S "$f" 2>/dev/null | grep -o '[0-9]*' || echo "1")
    if [[ "$orient" != "1" && -n "$orient" ]]; then
      magick "$f" -auto-orient "$f"
      exiftool -Orientation= -overwrite_original "$f" 2>/dev/null
      _ok "Rotated: $(basename "$f")"
    fi
  done
}

conv_strip_exif() {
  local files=("$@")
  local count=0
  for f in "${files[@]}"; do
    exiftool -all= -overwrite_original "$f" 2>/dev/null && (( count++ )) || true
  done
  _ok "EXIF stripped: $count files"
}

conv_thumbnail_grid() {
  local dir="$1"
  local cols="${2:-5}"
  local output="${3:-${dir}/preview_grid.jpg}"
  local tmpdir
  tmpdir=$(mktemp -d)

  _info "Building thumbnail grid from $(basename "$dir")"

  local i=0
  while IFS= read -r -d '' img; do
    local thumb="${tmpdir}/$(printf '%04d' $i).jpg"
    magick "$img" -thumbnail 200x200^ -gravity center -extent 200x200 "$thumb" 2>/dev/null && (( i++ )) || true
  done < <(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \
    -o -iname "*.png" -o -iname "*.heic" -o -iname "*.webp" -o -iname "*.avif" \) -print0 | sort -z)

  if [[ $i -eq 0 ]]; then
    _warn "No images found in $dir"; rm -rf "$tmpdir"; return 1
  fi

  magick montage "${tmpdir}"/*.jpg -geometry 200x200+2+2 -tile "${cols}x" "$output"
  rm -rf "$tmpdir"
  _conv_done "$dir" "$output"
}

optimg() {
  local files=("$@")
  local saved=0
  for f in "${files[@]}"; do
    local ext="${f##*.}" size_before size_after
    size_before=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    case "${ext,,}" in
      png)
        pngquant --force --quality=80-95 --skip-if-larger --output "$f" "$f" 2>/dev/null || true
        ;;
      jpg|jpeg)
        if [[ $size_before -gt 204800 ]]; then
          local tmp="${f}.opt.jpg"
          magick "$f" -quality 85 "$tmp" 2>/dev/null
          size_after=$(stat -f%z "$tmp" 2>/dev/null || stat -c%s "$tmp")
          if [[ $size_after -lt $size_before ]]; then
            mv "$tmp" "$f"
          else
            rm -f "$tmp"
          fi
        fi
        ;;
    esac
    size_after=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    (( saved += size_before - size_after )) || true
  done
  _ok "Saved: $(_conv_size_fmt $saved)"
}

optall() {
  local dir="${1:-.}"
  _info "Optimizing images in $dir"
  local -a files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$dir" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0)
  printf '%s\0' "${files[@]}" | xargs -0 -P "${CONV_CORES:-4}" -I{} bash -c 'optimg "{}"'
}
