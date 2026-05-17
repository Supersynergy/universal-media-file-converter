#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail

conv_pdf_merge() {
  local output="$1"; shift
  local files=("$@")
  _info "Merging ${#files[@]} PDFs → $(basename "$output")"
  qpdf --empty --pages "${files[@]}" -- "$output"
  _conv_done "${files[0]}" "$output"
}

conv_pdf_split() {
  local input="$1"
  local ranges="${2:-}"
  local base="${input%.*}"

  if [[ -z "$ranges" ]]; then
    local page_count
    page_count=$(pdfinfo "$input" 2>/dev/null | grep Pages | grep -o '[0-9]*')
    _info "Splitting $page_count pages: $(basename "$input")"
    for (( p=1; p<=page_count; p++ )); do
      local out
      out=$(printf "%s_p%03d.pdf" "$base" "$p")
      qpdf "$input" --pages "$input" "$p" -- "$out"
    done
  else
    local out="${base}_p${ranges//-/_}.pdf"
    _info "Extracting pages $ranges: $(basename "$input")"
    qpdf "$input" --pages "$input" "$ranges" -- "$out"
    _conv_done "$input" "$out"
  fi
  _ok "Split complete: $(basename "$base")"
}

conv_pdf_rotate() {
  local input="$1" degrees="$2"
  local output="${3:-${input%.*}_rot${degrees}.pdf}"
  _info "Rotate ${degrees}°: $(basename "$input")"
  qpdf --rotate="+${degrees}:1-z" "$input" "$output"
  _conv_done "$input" "$output"
}

conv_pdf_compress() {
  local input="$1"
  local output="${2:-${input%.*}_compressed.pdf}"
  local size_before
  size_before=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")

  _info "Compressing: $(basename "$input")"

  if command -v gs &>/dev/null; then
    command gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook \
      -sOutputFile="$output" "$input" 2>/dev/null
  else
    qpdf --compress-streams=y --object-streams=generate "$input" "$output"
  fi

  local size_after
  size_after=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output")
  local saved=$(( size_before - size_after ))
  _ok "Saved: $(_conv_size_fmt $saved) ($(( saved * 100 / size_before ))%)"
}

conv_pdf_ocr() {
  local input="$1"
  local lang="${2:-deu+eng}"
  local output="${3:-${input%.*}_ocr.pdf}"
  local base="${input%.*}"
  local tmpdir
  tmpdir=$(mktemp -d)

  _info "OCR (${lang}): $(basename "$input")"

  pdftoppm -r 300 -png "$input" "${tmpdir}/page"

  local -a hocr_files=()
  for png in "${tmpdir}"/page-*.png; do
    local stem="${png%.png}"
    tesseract "$png" "$stem" -l "$lang" hocr 2>/dev/null
    hocr_files+=("${stem}.hocr")
  done

  tesseract "${tmpdir}"/page-*.png "$base_ocr_tmp" -l "$lang" pdf 2>/dev/null || {
    local all_pngs=("${tmpdir}"/page-*.png)
    tesseract "${all_pngs[0]}" "${tmpdir}/combined" -l "$lang" pdf 2>/dev/null
    mv "${tmpdir}/combined.pdf" "$output"
  }

  if [[ ! -f "$output" ]]; then
    local txt_list="${tmpdir}/list.txt"
    printf '%s\n' "${tmpdir}"/page-*.png > "$txt_list"
    tesseract "$txt_list" "${tmpdir}/out" -l "$lang" pdf 2>/dev/null
    mv "${tmpdir}/out.pdf" "$output"
  fi

  rm -rf "$tmpdir"
  _conv_done "$input" "$output"
}

conv_pdf_images() {
  local input="$1"
  local outdir="${2:-${input%.*}_images}"
  mkdir -p "$outdir"
  _info "Extracting images: $(basename "$input")"
  pdfimages -all "$input" "${outdir}/img"
  _ok "Images → $outdir"
}

conv_pdf_text() {
  local input="$1"
  pdftotext -layout "$input" -
}

conv_pdf_info() {
  local input="$1"
  _info "PDF Info: $(basename "$input")"
  pdfinfo "$input" | awk -F': ' '{printf "%-20s %s\n", $1, $2}'
}
