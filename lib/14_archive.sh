#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail

conv_extract() {
  local archives=("$@")
  for archive in "${archives[@]}"; do
    local name="${archive##*/}"
    local base="${name%.tar.*}"
    base="${base%.*}"
    local outdir="${archive%/*}/${base}"
    mkdir -p "$outdir"

    _info "Extracting: $name → $base/"

    local lower="${archive,,}"
    case "$lower" in
      *.zip)
        if unzip -l "$archive" 2>&1 | grep -q "encrypted"; then
          read -rsp "Password for $name: " pw; echo
          unzip -P "$pw" "$archive" -d "$outdir"
        else
          unzip -q "$archive" -d "$outdir"
        fi
        ;;
      *.tar.gz|*.tgz)
        tar xzf "$archive" -C "$outdir" 2>/dev/null || 7z x "$archive" -o"$outdir" -y
        ;;
      *.tar.bz2|*.tbz2)
        tar xjf "$archive" -C "$outdir" 2>/dev/null || 7z x "$archive" -o"$outdir" -y
        ;;
      *.tar.xz|*.txz)
        tar xJf "$archive" -C "$outdir" 2>/dev/null || 7z x "$archive" -o"$outdir" -y
        ;;
      *.tar)
        tar xf "$archive" -C "$outdir"
        ;;
      *.7z|*.rar|*.gz|*.bz2|*.xz|*.lzma|*.cab|*.iso)
        if 7z l "$archive" 2>&1 | grep -q "Wrong password\|Encrypted = \+"; then
          read -rsp "Password for $name: " pw; echo
          7z x "$archive" -o"$outdir" -p"$pw" -y
        else
          7z x "$archive" -o"$outdir" -y
        fi
        ;;
      *)
        _warn "Unknown format: $name, trying 7z"
        7z x "$archive" -o"$outdir" -y
        ;;
    esac

    _ok "Extracted → $outdir/"
  done
}

conv_extract_all() {
  local dir="${1:-.}"
  local count=0
  _info "Scanning archives in $dir"

  while IFS= read -r -d '' archive; do
    conv_extract "$archive" && (( count++ )) || _warn "Failed: $(basename "$archive")"
  done < <(find "$dir" -type f \( \
    -iname "*.zip" -o -iname "*.7z" -o -iname "*.rar" \
    -o -iname "*.tar.gz" -o -iname "*.tgz" \
    -o -iname "*.tar.bz2" -o -iname "*.tbz2" \
    -o -iname "*.tar.xz" -o -iname "*.txz" \
    -o -iname "*.tar" \
  \) -print0)

  _ok "Extracted: $count archives"
}

conv_compress() {
  local output="$1"; shift
  local files=("$@")
  local ext="${output##*.}"

  _info "Compressing ${#files[@]} items → $(basename "$output")"

  case "${ext,,}" in
    zip)
      7z a -tzip "$output" "${files[@]}" -y
      ;;
    7z)
      7z a -t7z -mx=9 "$output" "${files[@]}" -y
      ;;
    *)
      _err "Unsupported output format: $ext (use .zip or .7z)"; return 1
      ;;
  esac

  _conv_done "${files[0]}" "$output"
}

conv_split_file() {
  local input="$1" size="$2"
  local base="${input%.*}"
  local ext="${input##*.}"

  _info "Splitting $(basename "$input") into ${size} chunks"
  split -b "$size" "$input" "${input}.part_"

  local manifest="${input}.manifest.txt"
  {
    echo "Source: $(basename "$input")"
    echo "Split-size: $size"
    echo "Parts:"
    ls "${input}.part_"* | while read -r part; do
      echo "  $(basename "$part")  $(stat -f%z "$part" 2>/dev/null || stat -c%s "$part") bytes"
    done
    echo "Rejoin: cat ${input}.part_* > $(basename "$input")"
  } > "$manifest"

  local part_count
  part_count=$(ls "${input}.part_"* | wc -l | tr -d ' ')
  _ok "Split into $part_count parts — manifest: $(basename "$manifest")"
}
