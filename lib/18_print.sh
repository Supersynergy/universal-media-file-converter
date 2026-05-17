#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail
# Print-production toolkit: PDF/X, CMYK, DPI, imposition, crop marks, QR, preflight

# ── Paper size table (width height in PostScript points) ──────────────────────
declare -A _CONV_PAPER_PT=(
  [a0]="2384 3370"  [a1]="1684 2384"  [a2]="1191 1684"  [a3]="842 1191"
  [a4]="595 842"    [a5]="420 595"    [a6]="298 420"     [a7]="210 298"
  [letter]="612 792" [legal]="612 1008" [tabloid]="792 1224"
  [business-card]="241 155"  [postcard]="420 298"  [square]="595 595"
)

# ── PDF Preflight & Compliance ────────────────────────────────────────────────

conv_pdf_preflight() {
  local input="$1"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "Preflight: $(basename "$input")"
  echo ""

  local pages page_size pdf_ver encrypted
  pages=$(pdfinfo "$input" 2>/dev/null | grep -i "^Pages:" | awk '{print $2}')
  page_size=$(pdfinfo "$input" 2>/dev/null | grep -i "^Page size:" | sed 's/Page size://;s/^ *//')
  pdf_ver=$(pdfinfo "$input" 2>/dev/null | grep -i "^PDF version:" | awk '{print $3}')
  encrypted=$(pdfinfo "$input" 2>/dev/null | grep -i "^Encrypted:" | awk '{print $2}')

  printf "  %-22s %s\n" "Pages:"        "${pages:-?}"
  printf "  %-22s %s\n" "Page size:"    "${page_size:-?}"
  printf "  %-22s %s\n" "PDF version:"  "${pdf_ver:-?}"
  printf "  %-22s %s\n" "Encrypted:"    "${encrypted:-no}"
  echo ""

  local issues=0 warnings=0

  # Ink coverage / color space check
  _info "Checking ink coverage..."
  local inkcov_out max_tac=0 c m y k rest tac_int sum_rgb line
  local has_cmyk=false has_rgb=false
  inkcov_out=$(command gs -dNOPAUSE -dBATCH -q -sDEVICE=inkcov -o - "$input" 2>/dev/null \
               | grep -v "^%%" | grep -iv -E "error|warning|not draw|could not")
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r c m y k rest <<< "$line"
    [[ "$c" =~ ^[0-9.]+$ ]] || continue
    [[ "$m" =~ ^[0-9.]+$ ]] || continue
    [[ "$y" =~ ^[0-9.]+$ ]] || continue
    [[ "$k" =~ ^[0-9.]+$ ]] || continue
    tac_int=$(awk -v c="$c" -v m="$m" -v y="$y" -v k="$k" \
      'BEGIN{printf "%d", (c+m+y+k)*100}' 2>/dev/null)
    [[ ${tac_int:-0} -gt $max_tac ]] && max_tac=${tac_int:-0}
    sum_rgb=$(awk -v c="$c" -v m="$m" -v y="$y" -v k="$k" \
      'BEGIN{printf "%d", (c+m+y+k)*1000}' 2>/dev/null)
    [[ ${sum_rgb:-0} -gt 0 ]] && has_cmyk=true
  done <<< "$inkcov_out"

  printf "  %-22s %d%%\n" "Max TAC:" "$max_tac"
  if [[ $max_tac -gt 300 ]]; then
    printf "  \033[31m[FAIL]\033[0m TAC > 300%% (offset print limit)\n"
    (( issues++ ))
  elif [[ $max_tac -gt 280 ]]; then
    printf "  \033[33m[WARN]\033[0m TAC > 280%% (near limit)\n"
    (( warnings++ ))
  else
    printf "  \033[32m[OK]\033[0m   TAC within limits\n"
  fi

  # Font check
  echo ""
  _info "Checking fonts..."
  if command -v pdffonts &>/dev/null; then
    local font_out non_embedded
    font_out=$(pdffonts "$input" 2>/dev/null | tail -n +3)
    non_embedded=$(echo "$font_out" | awk '{if ($5=="no") print $0}')
    local total_fonts
    total_fonts=$(echo "$font_out" | grep -c . 2>/dev/null || echo 0)
    printf "  %-22s %s\n" "Total fonts:" "$total_fonts"
    if [[ -n "$non_embedded" ]]; then
      printf "  \033[31m[FAIL]\033[0m Non-embedded fonts detected:\n"
      echo "$non_embedded" | while IFS= read -r fl; do
        printf "         %s\n" "$fl"
      done
      (( issues++ ))
    else
      printf "  \033[32m[OK]\033[0m   All fonts embedded\n"
    fi
  else
    printf "  \033[33m[WARN]\033[0m pdffonts not available (install poppler)\n"
    (( warnings++ ))
  fi

  # Image DPI check
  echo ""
  _info "Checking image resolution..."
  if command -v pdfimages &>/dev/null; then
    local low_dpi_count=0
    while IFS= read -r line; do
      local xppi yppi
      xppi=$(echo "$line" | awk '{print $12}')
      yppi=$(echo "$line" | awk '{print $13}')
      if [[ "$xppi" =~ ^[0-9]+$ && $xppi -gt 0 && $xppi -lt 300 ]]; then
        (( low_dpi_count++ ))
      fi
    done < <(pdfimages -list "$input" 2>/dev/null | tail -n +3)
    if [[ $low_dpi_count -gt 0 ]]; then
      printf "  \033[31m[FAIL]\033[0m %d image(s) below 300 DPI\n" "$low_dpi_count"
      (( issues++ ))
    else
      printf "  \033[32m[OK]\033[0m   All images ≥ 300 DPI\n"
    fi
  else
    printf "  \033[33m[WARN]\033[0m pdfimages not available\n"
    (( warnings++ ))
  fi

  echo ""
  if [[ $issues -gt 0 ]]; then
    printf "  \033[41m\033[97m  RED — %d issue(s), %d warning(s) — NOT print-ready  \033[0m\n" "$issues" "$warnings"
  elif [[ $warnings -gt 0 ]]; then
    printf "  \033[43m\033[30m  YELLOW — %d warning(s) — review before print  \033[0m\n" "$warnings"
  else
    printf "  \033[42m\033[30m  GREEN — file appears print-ready  \033[0m\n"
  fi
  echo ""
}

conv_pdf_to_pdfx() {
  local input="$1"
  local standard="${2:-x1a}"
  local output="${3:-${input%.*}_${standard}.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "PDF/X-$(echo "$standard" | tr '[:lower:]' '[:upper:]'): $(basename "$input") → $(basename "$output")"

  local compat="-dCompatibilityLevel=1.3"
  local extra=""
  case "$standard" in
    x3)  compat="-dCompatibilityLevel=1.4" ;;
    x4)  compat="-dCompatibilityLevel=1.6" ; extra="-dPreserveOverprintSettings=true" ;;
  esac

  command gs -dBATCH -dNOPAUSE -q \
    -sDEVICE=pdfwrite \
    $compat \
    -sColorConversionStrategy=CMYK \
    -dProcessColorModel=/DeviceCMYK \
    -dPDFSETTINGS=/prepress \
    $extra \
    -sOutputFile="$output" \
    "$input" 2>/dev/null

  _conv_done "$input" "$output"
}

conv_pdf_rgb_to_cmyk() {
  local input="$1"
  local output="${2:-${input%.*}_cmyk.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "RGB → CMYK: $(basename "$input")"

  command gs -dBATCH -dNOPAUSE -q \
    -sDEVICE=pdfwrite \
    -sColorConversionStrategy=CMYK \
    -dProcessColorModel=/DeviceCMYK \
    -dPDFSETTINGS=/prepress \
    -sOutputFile="$output" \
    "$input" 2>/dev/null

  _conv_done "$input" "$output"
}

conv_pdf_cmyk_to_rgb() {
  local input="$1"
  local output="${2:-${input%.*}_rgb.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "CMYK → sRGB: $(basename "$input")"

  command gs -dBATCH -dNOPAUSE -q \
    -sDEVICE=pdfwrite \
    -sColorConversionStrategy=sRGB \
    -dProcessColorModel=/DeviceRGB \
    -dPDFSETTINGS=/prepress \
    -sOutputFile="$output" \
    "$input" 2>/dev/null

  _conv_done "$input" "$output"
}

conv_pdf_grayscale() {
  local input="$1"
  local output="${2:-${input%.*}_gray.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "Grayscale: $(basename "$input")"

  command gs -dBATCH -dNOPAUSE -q \
    -sDEVICE=pdfwrite \
    -sColorConversionStrategy=Gray \
    -dProcessColorModel=/DeviceGray \
    -dPDFSETTINGS=/prepress \
    -sOutputFile="$output" \
    "$input" 2>/dev/null

  _conv_done "$input" "$output"
}

# ── PDF Imposition & Layout ───────────────────────────────────────────────────

conv_pdf_nup() {
  local input="$1"
  local cols="${2:-2}"
  local rows="${3:-2}"
  local paper="${4:-a4}"
  local output="${5:-${input%.*}_${cols}x${rows}.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  local nup=$(( cols * rows ))
  _info "${nup}-up imposition (${cols}×${rows}): $(basename "$input")"

  if command -v pdfjam &>/dev/null; then
    pdfjam --nup "${cols}x${rows}" --paper "${paper}paper" \
      --outfile "$output" "$input" 2>/dev/null
  else
    _warn "pdfjam not found. Falling back to raster method."
    _warn "For best results: brew install --cask mactex-no-gui"
    local tmpdir
    tmpdir=$(mktemp -d)
    local paper_dims="${_CONV_PAPER_PT[$paper]:-595 842}"
    local pw ph
    read -r pw ph <<< "$paper_dims"
    local cell_w=$(( pw / cols ))
    local cell_h=$(( ph / rows ))

    pdftoppm -r 150 -png "$input" "${tmpdir}/pg" 2>/dev/null
    local pages=("${tmpdir}"/pg-*.png)
    [[ ${#pages[@]} -eq 0 ]] && { _err "rasterize failed"; rm -rf "$tmpdir"; return 1; }

    local batches=()
    local i=0
    while [[ $i -lt ${#pages[@]} ]]; do
      local batch=("${pages[@]:$i:$nup}")
      local padded=("${batch[@]}")
      while [[ ${#padded[@]} -lt $nup ]]; do padded+=("null:"); done
      local row_imgs=()
      for (( r=0; r<rows; r++ )); do
        local row_slice=("${padded[@]:$(( r * cols )):$cols}")
        magick "${row_slice[@]}" +append "${tmpdir}/row_${i}_${r}.png" 2>/dev/null
        row_imgs+=("${tmpdir}/row_${i}_${r}.png")
      done
      magick "${row_imgs[@]}" -append "${tmpdir}/sheet_${i}.png" 2>/dev/null
      batches+=("${tmpdir}/sheet_${i}.png")
      (( i += nup ))
    done

    magick "${batches[@]}" -compress jpeg -quality 90 \
      -page "${pw}x${ph}" "$output" 2>/dev/null

    rm -rf "$tmpdir"
  fi

  _conv_done "$input" "$output"
}

conv_pdf_booklet() {
  local input="$1"
  local output="${2:-${input%.*}_booklet.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "Booklet imposition: $(basename "$input")"

  local page_count
  page_count=$(pdfinfo "$input" 2>/dev/null | grep -i "^Pages:" | awk '{print $2}')
  page_count=${page_count:-0}

  # Pad to multiple of 4
  local padded=$(( (page_count + 3) / 4 * 4 ))

  # Build booklet page order
  local -a order=()
  local first=1 last=$padded
  while [[ $first -le $last ]]; do
    order+=("$last" "$first" "$((first+1))" "$((last-1))")
    (( first += 2 )); (( last -= 2 ))
  done

  if command -v pdfjam &>/dev/null; then
    local page_spec
    page_spec=$(IFS=','; echo "${order[*]}")
    pdfjam --nup "2x1" --paper "a4paper" --landscape \
      --outfile "$output" "$input" "$page_spec" 2>/dev/null
  else
    _warn "pdfjam not available. Install: brew install --cask mactex-no-gui"
    _info "Creating raster booklet fallback..."
    local tmpdir
    tmpdir=$(mktemp -d)
    pdftoppm -r 150 -png "$input" "${tmpdir}/pg" 2>/dev/null
    local -a all_pgs=()
    for p in "${order[@]}"; do
      local pg_file
      pg_file=$(printf "%s/pg-%d.png" "$tmpdir" "$p")
      [[ -f "$pg_file" ]] && all_pgs+=("$pg_file") || all_pgs+=("null:")
    done
    local i=0
    local -a sheets=()
    while [[ $i -lt ${#all_pgs[@]} ]]; do
      magick "${all_pgs[$i]}" "${all_pgs[$((i+1))]:-null:}" +append \
        "${tmpdir}/sheet_${i}.png" 2>/dev/null
      sheets+=("${tmpdir}/sheet_${i}.png")
      (( i += 2 ))
    done
    magick "${sheets[@]}" -compress jpeg -quality 90 "$output" 2>/dev/null
    rm -rf "$tmpdir"
  fi

  _conv_done "$input" "$output"
}

conv_pdf_crop_marks() {
  local input="$1"
  local bleed_mm="${2:-3}"
  local output="${3:-${input%.*}_cropmarks.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "Crop marks (${bleed_mm}mm bleed): $(basename "$input")"

  local bleed_pt
  bleed_pt=$(awk "BEGIN{printf \"%d\", $bleed_mm * 2.8346}" 2>/dev/null)
  local mark=14  # crop mark length in points (5mm)

  # Use ghostscript to add a crop-marks overlay via PostScript
  command gs -dBATCH -dNOPAUSE -q \
    -sDEVICE=pdfwrite \
    -dPDFSETTINGS=/prepress \
    -sOutputFile="$output" \
    -c "
    << /BeginPage {
      gsave
      0 setgray 0.25 setlinewidth
      currentpagedevice /PageSize get aload pop
      /ph exch def /pw exch def
      /bl ${bleed_pt} def /mk ${mark} def
      % TL horizontal
      0 ph bl sub moveto mk 0 rlineto stroke
      % TL vertical
      bl ph moveto 0 mk neg rlineto stroke
      % TR horizontal
      pw mk sub ph bl sub moveto mk 0 rlineto stroke
      % TR vertical
      pw bl sub ph moveto 0 mk neg rlineto stroke
      % BL horizontal
      0 bl moveto mk 0 rlineto stroke
      % BL vertical
      bl bl moveto 0 mk rlineto stroke
      % BR horizontal
      pw mk sub bl moveto mk 0 rlineto stroke
      % BR vertical
      pw bl sub bl moveto 0 mk rlineto stroke
      grestore
    } def >> setpagedevice
    " \
    -f "$input" 2>/dev/null

  _conv_done "$input" "$output"
}

conv_pdf_resize() {
  local input="$1"
  local paper="${2:-a4}"
  local output="${3:-${input%.*}_${paper}.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  local dims="${_CONV_PAPER_PT[$paper]:-}"
  if [[ -z "$dims" ]]; then
    _err "Unknown paper: $paper. Use: ${!_CONV_PAPER_PT[*]}"
    return 1
  fi
  local pw ph
  read -r pw ph <<< "$dims"

  _info "Resize → ${paper} (${pw}×${ph}pt): $(basename "$input")"

  command gs -dBATCH -dNOPAUSE -q \
    -sDEVICE=pdfwrite \
    -dPDFSETTINGS=/prepress \
    -dFIXEDMEDIA \
    -dPDFFitPage \
    -dDEVICEWIDTHPOINTS="$pw" \
    -dDEVICEHEIGHTPOINTS="$ph" \
    -sOutputFile="$output" \
    "$input" 2>/dev/null

  _conv_done "$input" "$output"
}

conv_pdf_extract_pages() {
  local input="$1"
  local range="$2"
  local output="${3:-${input%.*}_p${range//,/_}.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  [[ -n "$range" ]] || { _err "No page range specified (e.g. 1-5,8,12-15)"; return 1; }
  _conv_start_timer

  _info "Extract pages ${range}: $(basename "$input")"
  qpdf "$input" --pages "$input" "$range" -- "$output"
  _conv_done "$input" "$output"
}

# ── Image Print Prep ──────────────────────────────────────────────────────────

conv_img_to_cmyk() {
  local input="$1"
  local output="${2:-${input%.*}_cmyk.tif}"
  local profile="${3:-}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "RGB → CMYK: $(basename "$input")"

  local icc_opt=""
  if [[ -n "$profile" && -f "$profile" ]]; then
    icc_opt="-profile $profile"
  else
    # Try common installed ICC paths
    for candidate in \
      /opt/homebrew/share/ghostscript/*/iccprofiles/default_cmyk.icc \
      /usr/share/ghostscript/*/iccprofiles/default_cmyk.icc; do
      local resolved
      resolved=$(ls $candidate 2>/dev/null | head -1)
      if [[ -f "${resolved:-}" ]]; then
        icc_opt="-profile $resolved"
        break
      fi
    done
  fi

  magick "$input" -colorspace CMYK $icc_opt "$output" 2>/dev/null
  _conv_done "$input" "$output"
}

conv_img_to_rgb() {
  local input="$1"
  local output="${2:-${input%.*}_rgb.jpg}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "CMYK → sRGB: $(basename "$input")"
  magick "$input" -colorspace sRGB "$output" 2>/dev/null
  _conv_done "$input" "$output"
}

conv_img_dpi_check() {
  [[ $# -ge 1 ]] || { _err "Usage: conv_img_dpi_check <files...>"; return 1; }
  printf "\n  %-30s %8s %10s %12s %s\n" "File" "DPIx" "DPIy" "300dpi size" "Status"
  printf "  %s\n" "$(printf '─%.0s' {1..75})"
  local f
  for f in "$@"; do
    [[ -f "$f" ]] || { _warn "Not found: $f"; continue; }
    local xres yres pw ph
    xres=$(magick identify -format "%x" "$f" 2>/dev/null | awk '{print int($1)}')
    yres=$(magick identify -format "%y" "$f" 2>/dev/null | awk '{print int($1)}')
    pw=$(magick identify -format "%w" "$f" 2>/dev/null)
    ph=$(magick identify -format "%h" "$f" 2>/dev/null)
    xres=${xres:-72}; yres=${yres:-72}
    local print_w_mm print_h_mm
    print_w_mm=$(awk "BEGIN{printf \"%.0f\", ($pw / 300) * 25.4}" 2>/dev/null)
    print_h_mm=$(awk "BEGIN{printf \"%.0f\", ($ph / 300) * 25.4}" 2>/dev/null)
    local dpi_status="\033[32mOK\033[0m"
    [[ $xres -lt 300 ]] && dpi_status="\033[31mLOW DPI\033[0m"
    printf "  %-30s %8d %10d %9s mm  %b\n" \
      "$(basename "$f")" "$xres" "$yres" "${print_w_mm}×${print_h_mm}" "$dpi_status"
  done
  echo ""
}

conv_img_set_dpi() {
  local input="$1"
  local dpi="${2:-300}"
  local output="${3:-${input%.*}_${dpi}dpi.${input##*.}}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  _info "Set DPI → ${dpi}: $(basename "$input")"
  magick "$input" -density "$dpi" -units PixelsPerInch "$output" 2>/dev/null
  _conv_done "$input" "$output"
}

conv_img_upscale() {
  local input="$1"
  local target_dpi="${2:-300}"
  local print_width_mm="${3:-210}"
  local output="${4:-${input%.*}_upscaled.${input##*.}}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  local target_px
  target_px=$(awk "BEGIN{printf \"%d\", ($print_width_mm / 25.4) * $target_dpi}" 2>/dev/null)
  local cur_w
  cur_w=$(magick identify -format "%w" "$input" 2>/dev/null)

  local factor
  factor=$(awk "BEGIN{printf \"%.1f\", $target_px / ${cur_w:-1}}" 2>/dev/null)

  _info "Upscale ${cur_w}px → ${target_px}px (×${factor}): $(basename "$input")"
  [[ $(awk "BEGIN{print ($factor > 2.0)}") -eq 1 ]] && \
    _warn "Upscale factor ${factor}× may cause quality loss"

  vips resize "$input" "$output" "$factor" --kernel lanczos3 2>/dev/null || \
    magick "$input" -filter Lanczos -resize "${target_px}x" "$output" 2>/dev/null

  _conv_done "$input" "$output"
}

conv_img_print_ready() {
  [[ $# -ge 1 ]] || { _err "Usage: conv_img_print_ready <files...>"; return 1; }
  local f
  for f in "$@"; do
    [[ -f "$f" ]] || { _warn "Skipping (not found): $f"; continue; }
    _conv_start_timer
    local base="${f%.*}"
    local output="${base}_print.tif"
    _info "Print-ready: $(basename "$f")"
    magick "$f" \
      -colorspace CMYK \
      -density 300 -units PixelsPerInch \
      -alpha remove -background white -flatten \
      "$output" 2>/dev/null
    _conv_done "$f" "$output"
  done
}

conv_img_poster_split() {
  local input="$1"
  local rows="${2:-2}"
  local cols="${3:-3}"
  local prefix="${4:-${input%.*}_tile}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }
  _conv_start_timer

  local w h
  w=$(magick identify -format "%w" "$input" 2>/dev/null)
  h=$(magick identify -format "%h" "$input" 2>/dev/null)

  local tile_w=$(( w / cols ))
  local tile_h=$(( h / rows ))

  _info "Poster split ${rows}×${cols} tiles (${tile_w}×${tile_h}px each): $(basename "$input")"

  local r c n=0
  for (( r=0; r<rows; r++ )); do
    for (( c=0; c<cols; c++ )); do
      local x=$(( c * tile_w ))
      local y=$(( r * tile_h ))
      local out
      out=$(printf "%s_%02d_%02d.tif" "$prefix" "$r" "$c")
      magick "$input" -crop "${tile_w}x${tile_h}+${x}+${y}" +repage "$out" 2>/dev/null
      (( n++ ))
    done
  done

  _ok "Generated $n tiles with prefix $(basename "$prefix")"
}

# ── QR / Barcode ─────────────────────────────────────────────────────────────

conv_qr() {
  local data="$1"
  local output="${2:-qr.png}"
  local size="${3:-8}"
  local ecc="${4:-M}"

  [[ -n "$data" ]] || { _err "No data provided"; return 1; }

  if ! command -v qrencode &>/dev/null; then
    _err "qrencode not found. Install: brew install qrencode"
    return 1
  fi

  _conv_start_timer

  # Bulk mode: if data is a file, read each line
  if [[ -f "$data" ]]; then
    _info "Bulk QR from: $(basename "$data")"
    local n=1
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" ]] && continue
      local out
      out=$(printf "%s_%03d.png" "${output%.*}" "$n")
      qrencode -t PNG -s "$size" -l "$ecc" -o "$out" "$line" 2>/dev/null
      _ok "QR $n → $(basename "$out")"
      (( n++ ))
    done < "$data"
    return 0
  fi

  _info "QR code (ecc=$ecc size=${size}px): $(basename "$output")"
  qrencode -t PNG -s "$size" -l "$ecc" -o "$output" "$data"
  _ok "QR → $output ($(ls -lh "$output" 2>/dev/null | awk '{print $5}'))"
}

conv_qr_svg() {
  local data="$1"
  local output="${2:-qr.svg}"

  [[ -n "$data" ]] || { _err "No data provided"; return 1; }

  if ! command -v qrencode &>/dev/null; then
    _err "qrencode not found. Install: brew install qrencode"
    return 1
  fi

  _conv_start_timer
  _info "Vector QR → $(basename "$output")"
  qrencode -t SVG -o "$output" "$data"
  _ok "QR SVG → $output"
}

conv_barcode_scan() {
  local input="$1"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }

  if ! command -v zbarimg &>/dev/null; then
    _err "zbarimg not found. Install: brew install zbar"
    return 1
  fi

  _info "Scanning barcodes: $(basename "$input")"
  zbarimg --raw "$input" 2>/dev/null || {
    _warn "No barcodes detected in: $(basename "$input")"
  }
}

# ── Vector / Print Graphics ───────────────────────────────────────────────────

conv_raster_to_vector() {
  local input="$1"
  local output="${2:-${input%.*}.svg}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }

  if ! command -v potrace &>/dev/null; then
    _err "potrace not found. Install: brew install potrace"
    return 1
  fi

  _conv_start_timer
  _info "Raster → SVG: $(basename "$input")"

  magick "$input" -threshold 50% -compress none pgm:- 2>/dev/null | \
    potrace --svg -o "$output" 2>/dev/null

  _ok "SVG → $output"
}

conv_svg_to_pdf() {
  local input="$1"
  local output="${2:-${input%.*}.pdf}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }

  if ! command -v rsvg-convert &>/dev/null; then
    _err "rsvg-convert not found. Install: brew install librsvg"
    return 1
  fi

  _conv_start_timer
  _info "SVG → PDF: $(basename "$input")"
  rsvg-convert -f pdf -o "$output" "$input"
  _conv_done "$input" "$output"
}

# ── Print Workflows ───────────────────────────────────────────────────────────

conv_print_prep() {
  local input="$1"
  local target="${2:-offset}"
  [[ -f "$input" ]] || { _err "File not found: $input"; return 1; }

  _info "Print prep (${target}): $(basename "$input")"

  case "$target" in
    offset)
      conv_pdf_rgb_to_cmyk "$input"
      local cmyk_out="${input%.*}_cmyk.pdf"
      [[ -f "$cmyk_out" ]] && conv_pdf_to_pdfx "$cmyk_out" x1a
      conv_pdf_preflight "${cmyk_out%.*}_x1a.pdf" 2>/dev/null || \
        conv_pdf_preflight "$cmyk_out"
      ;;
    digital)
      conv_pdf_cmyk_to_rgb "$input"
      _ok "Digital print ready: ${input%.*}_rgb.pdf"
      ;;
    web)
      local out="${input%.*}_web.pdf"
      command gs -dBATCH -dNOPAUSE -q \
        -sDEVICE=pdfwrite \
        -dPDFSETTINGS=/screen \
        -sColorConversionStrategy=sRGB \
        -dProcessColorModel=/DeviceRGB \
        -sOutputFile="$out" "$input" 2>/dev/null
      _conv_done "$input" "$out"
      ;;
    laser)
      conv_pdf_grayscale "$input"
      local gray="${input%.*}_gray.pdf"
      local out="${gray%.*}_opt.pdf"
      command gs -dBATCH -dNOPAUSE -q \
        -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook \
        -sOutputFile="$out" "$gray" 2>/dev/null
      _conv_done "$input" "$out"
      ;;
    *)
      _err "Unknown target: $target. Use: offset|digital|web|laser"
      return 1
      ;;
  esac
}

conv_business_card() {
  local front="$1"
  local back="${2:-}"
  local output="${3:-business_card.pdf}"
  [[ -f "$front" ]] || { _err "Front image not found: $front"; return 1; }
  _conv_start_timer

  _info "Business card: $(basename "$front")"

  # 85x55mm + 3mm bleed = 91x61mm; in points: 91mm*2.8346=257.9≈258, 61mm=172.9≈173
  local card_w=258 card_h=173

  local tmpdir
  tmpdir=$(mktemp -d)
  local front_pdf="${tmpdir}/front.pdf"

  magick "$front" \
    -resize "${card_w}x${card_h}!" \
    -density 300 \
    "$front_pdf" 2>/dev/null

  if [[ -n "$back" && -f "$back" ]]; then
    local back_pdf="${tmpdir}/back.pdf"
    magick "$back" \
      -resize "${card_w}x${card_h}!" \
      -density 300 \
      "$back_pdf" 2>/dev/null
    qpdf --empty --pages "$front_pdf" 1 "$back_pdf" 1 -- "${tmpdir}/combined.pdf" 2>/dev/null
    conv_pdf_crop_marks "${tmpdir}/combined.pdf" 3 "$output"
  else
    conv_pdf_crop_marks "$front_pdf" 3 "$output"
  fi

  rm -rf "$tmpdir"
  _ok "Business card PDF → $output"
}
