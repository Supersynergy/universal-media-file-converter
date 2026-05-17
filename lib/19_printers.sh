#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail
# Smart printer-aware dispatcher: printer profiles, product specs, wizard, auto-detect

# ── YAML helpers ──────────────────────────────────────────────────────────────

_CONV_YQ_BIN=""
_conv_find_yq() {
  [[ -n "$_CONV_YQ_BIN" ]] && return 0
  local candidate
  for candidate in yq /opt/homebrew/bin/yq /usr/local/bin/yq; do
    if type "$candidate" &>/dev/null 2>&1; then
      _CONV_YQ_BIN="$candidate"
      return 0
    fi
  done
  return 1
}

_conv_yaml_get() {
  local file="$1" path="$2"
  _conv_find_yq
  if [[ -n "$_CONV_YQ_BIN" ]]; then
    local _yqout
    _yqout=$("$_CONV_YQ_BIN" ".${path}" "$file" 2>/dev/null)
    [[ "$_yqout" == "null" || -z "$_yqout" ]] && return 0
    printf '%s\n' "$_yqout"
  else
    python3 -c "
import sys, yaml
try:
  with open('$file') as f: d = yaml.safe_load(f)
  for k in '$path'.split('.'):
    if d is None: break
    if k.isdigit(): d = d[int(k)]
    else: d = d.get(k)
  if d is not None: print(d if not isinstance(d, (list,dict)) else yaml.safe_dump(d, default_flow_style=False).rstrip())
except Exception as e: sys.exit(0)
" 2>/dev/null
  fi
}

_conv_yaml_keys() {
  local file="$1" path="${2:-}"
  _conv_find_yq
  if [[ -n "$_CONV_YQ_BIN" ]]; then
    if [[ -z "$path" ]]; then "$_CONV_YQ_BIN" 'keys | .[]' "$file" 2>/dev/null
    else "$_CONV_YQ_BIN" ".${path} | keys | .[]" "$file" 2>/dev/null
    fi
  else
    python3 -c "
import yaml
with open('$file') as f: d = yaml.safe_load(f)
parts = '${path}'.split('.') if '$path' else []
for k in parts:
  d = d.get(k) if isinstance(d, dict) else None
  if d is None: break
if isinstance(d, dict):
  for k in d.keys(): print(k)
" 2>/dev/null
  fi
}

_conv_printer_dir() {
  echo "${CONV_DIR:-$HOME/projects/universal-media-file-converter}/data/printers"
}

_conv_printer_resolve() {
  local query="$1"
  local pdir
  pdir="$(_conv_printer_dir)"
  local index="${pdir}/_INDEX.yaml"
  query=$(echo "$query" | tr '[:upper:]' '[:lower:]' | sed 's|^https\?://||;s|^www\.||;s|/$||;s|\.de$||;s|\.com$||;s|\.eu$||;s|[/ ]|-|g')
  local direct="${pdir}/${query}.yaml"
  if [[ -f "$direct" ]]; then echo "$query"; return 0; fi
  [[ -f "$index" ]] || { echo ""; return 1; }
  python3 -c "
import yaml, sys
try:
  with open('$index') as f: idx = yaml.safe_load(f) or {}
  printers = idx.get('printers', {})
  q = '$query'
  for slug, info in printers.items():
    if slug == q: print(slug); sys.exit(0)
    aliases = info.get('aliases', []) or []
    for a in aliases:
      norm = a.lower()
      for suffix in ['.de','.com','.eu','.net']:
        norm = norm.replace(suffix,'')
      norm = norm.replace('www.','').replace('/','').replace(' ','-')
      if norm == q:
        print(slug); sys.exit(0)
except: pass
print('')
" 2>/dev/null
}

_conv_check_python_yaml() {
  python3 -c "import yaml" 2>/dev/null || {
    _warn "PyYAML not found. Install: uv pip install pyyaml  OR  brew install yq"
    return 1
  }
}

# ── Printer list ──────────────────────────────────────────────────────────────

conv_printer_list() {
  local pdir f base name region prod_count found
  pdir="$(_conv_printer_dir)"
  local yamls=("${pdir}"/*.yaml)

  printf "${BOLD}  %-22s %-32s %-8s %s${RESET}\n" "SLUG" "NAME" "REGION" "PRODUCTS"
  printf "  %-22s %-32s %-8s %s\n" "──────────────────────" "────────────────────────────────" "──────" "────────"

  found=0
  for f in "${yamls[@]}"; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f" .yaml)"
    [[ "$base" == "_INDEX" || "$base" == "_defaults" ]] && continue
    name="$(_conv_yaml_get "$f" "name")"
    region="$(_conv_yaml_get "$f" "region")"
    prod_count="$(python3 -c "
import yaml
try:
  with open('$f') as fh: d = yaml.safe_load(fh) or {}
  prods = d.get('products', {})
  print(len(prods) if isinstance(prods, dict) else 0)
except: print(0)
" 2>/dev/null)"
    printf "  %-22s %-32s %-8s %s\n" "$base" "${name:-?}" "${region:-?}" "${prod_count:-0}"
    found=1
  done

  if [[ "$found" == "0" ]]; then
    _warn "No printer profiles found in $pdir"
    _info "Run 'conv --wizard' to get started, or add YAML files to $pdir"
  fi
}

# ── Printer specs ─────────────────────────────────────────────────────────────

conv_printer_specs() {
  local query="${1:-}"
  [[ -z "$query" ]] && { _err "Usage: conv --printer-specs <printer>"; return 1; }
  local pdir
  pdir="$(_conv_printer_dir)"
  local slug
  slug="$(_conv_printer_resolve "$query")"
  if [[ -z "$slug" ]]; then
    _err "Printer not found: $query"
    _info "Run 'conv --printer-list' to see available printers."
    return 1
  fi
  local f="${pdir}/${slug}.yaml"
  local name region url
  name="$(_conv_yaml_get "$f" "name")"
  region="$(_conv_yaml_get "$f" "region")"
  url="$(_conv_yaml_get "$f" "url")"
  printf "\n${BOLD}%s${RESET}  (%s)\n" "$name" "$region"
  printf "  URL: %s\n\n" "$url"
  printf "${BOLD}Defaults:${RESET}\n"
  python3 -c "
import yaml
with open('$f') as fh: d = yaml.safe_load(fh) or {}
defaults = d.get('defaults', {})
for k,v in (defaults or {}).items():
  print(f'  {k}: {v}')
" 2>/dev/null
  printf "\n${BOLD}Products:${RESET}\n"
  python3 -c "
import yaml
with open('$f') as fh: d = yaml.safe_load(fh) or {}
prods = d.get('products', {}) or {}
for slug, p in prods.items():
  print(f'  {slug}')
  for k,v in (p or {}).items():
    print(f'    {k}: {v}')
" 2>/dev/null
  local warnings
  warnings="$(_conv_yaml_get "$f" "warnings")"
  if [[ -n "$warnings" ]]; then
    printf "\n${BOLD}Warnings:${RESET}\n"
    echo "$warnings" | while IFS= read -r line; do
      _warn "$line"
    done
  fi
}

# ── Product list ──────────────────────────────────────────────────────────────

conv_product_list() {
  local printer="${1:-}"
  local pdir
  pdir="$(_conv_printer_dir)"

  if [[ -n "$printer" ]]; then
    local slug
    slug="$(_conv_printer_resolve "$printer")"
    [[ -z "$slug" ]] && { _err "Printer not found: $printer"; return 1; }
    local f="${pdir}/${slug}.yaml"
    local name
    name="$(_conv_yaml_get "$f" "name")"
    printf "${BOLD}Products for %s:${RESET}\n" "$name"
    python3 -c "
import yaml
with open('$f') as fh: d = yaml.safe_load(fh) or {}
for p in (d.get('products', {}) or {}).keys():
  print('  ' + p)
" 2>/dev/null
  else
    printf "${BOLD}All products (across all printers):${RESET}\n"
    local seen=""
    for f in "${pdir}"/*.yaml; do
      [[ -f "$f" ]] || continue
      local _bname; _bname="$(basename "$f" .yaml)"; [[ "$_bname" == "_INDEX" || "$_bname" == "_defaults" ]] && continue
      python3 -c "
import yaml
with open('$f') as fh: d = yaml.safe_load(fh) or {}
printer_name = d.get('name','?')
for p in (d.get('products', {}) or {}).keys():
  print(f'  {p:<28} [{printer_name}]')
" 2>/dev/null
    done
  fi
}

# ── File analysis ─────────────────────────────────────────────────────────────

conv_analyze() {
  local file="${1:-}"
  [[ -z "$file" ]] && { _err "Usage: conv --analyze <file>"; return 1; }
  [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }

  local ext
  ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')

  printf "\n${BOLD}Analysis: %s${RESET}\n" "$(basename "$file")"
  printf "  %-26s %s\n" "──────────────────────────" "────────────────────────────────────"

  case "$ext" in
    pdf)
      _conv_analyze_pdf "$file"
      ;;
    jpg|jpeg|png|tif|tiff|webp|bmp|psd|ai|eps)
      _conv_analyze_image "$file"
      ;;
    *)
      _warn "Unsupported file type: .$ext (supported: pdf, jpg, png, tif, webp)"
      return 1
      ;;
  esac
}

_conv_analyze_pdf() {
  local file="$1"

  # Basic info via pdfinfo
  local pages width_pt height_pt
  if command -v pdfinfo &>/dev/null; then
    local pinfo
    pinfo=$(pdfinfo "$file" 2>/dev/null)
    pages=$(echo "$pinfo" | awk '/^Pages:/{print $2}')
    local pagesize
    pagesize=$(echo "$pinfo" | grep -i "^Page size:" | head -1)
    width_pt=$(echo "$pagesize" | awk '{print $3}')
    height_pt=$(echo "$pagesize" | awk '{print $5}')
  fi

  pages="${pages:-?}"
  local width_mm height_mm
  if [[ "$width_pt" =~ ^[0-9] ]]; then
    width_mm=$(echo "$width_pt" | awk '{printf "%.1f", $1 * 25.4 / 72}')
    height_mm=$(echo "$height_pt" | awk '{printf "%.1f", $1 * 25.4 / 72}')
  fi

  # Detect paper size
  local paper_name="custom"
  if [[ -n "$width_mm" ]]; then
    paper_name=$(_conv_detect_paper_mm "$width_mm" "$height_mm")
  fi

  printf "  %-26s %s\n" "Pages:" "$pages"
  if [[ -n "$width_mm" ]]; then
    printf "  %-26s %sx%s mm (%sx%s pt) [%s]\n" "Page size:" "$width_mm" "$height_mm" "$width_pt" "$height_pt" "$paper_name"
  fi

  # Colorspace via gs inkcov
  local colorspace="unknown"
  if command -v gs &>/dev/null; then
    local gs_out
    gs_out=$(command gs -dBATCH -dNOPAUSE -dNOPROMPT -q -sDEVICE=inkcov -o /dev/null "$file" 2>/dev/null | tail -5)
    if echo "$gs_out" | grep -qE "[0-9]"; then
      local has_rgb
      has_rgb=$(echo "$gs_out" | awk '{if($1+$2+$3>0 && $4==0) print "rgb"}' | head -1)
      if [[ -n "$has_rgb" ]]; then
        colorspace="RGB"
      else
        colorspace="CMYK"
      fi
    fi
  fi
  printf "  %-26s %s\n" "Colorspace:" "$colorspace"

  # Fonts
  if command -v pdffonts &>/dev/null; then
    local font_count not_embedded
    font_count=$(pdffonts "$file" 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')
    not_embedded=$(pdffonts "$file" 2>/dev/null | tail -n +3 | awk '{print $5}' | grep -c "no" || true)
    printf "  %-26s %s total, %s not embedded\n" "Fonts:" "$font_count" "$not_embedded"
  fi

  # Image DPI
  if command -v pdfimages &>/dev/null; then
    local min_dpi
    min_dpi=$(pdfimages -list "$file" 2>/dev/null | tail -n +3 | awk '{print $13}' | grep -E '^[0-9]+$' | sort -n | head -1)
    if [[ -n "$min_dpi" ]]; then
      printf "  %-26s %s DPI (minimum found)\n" "Image DPI:" "$min_dpi"
    fi
  fi

  # Bleed heuristic via gs
  local has_bleed="unknown"
  if command -v gs &>/dev/null; then
    local mediabox trimbox
    mediabox=$(command gs -dBATCH -dNOPAUSE -q -c "($file) (r) file runpdfbegin 1 pdfgetpage /MediaBox pget pop ==" -f /dev/null 2>/dev/null | head -1 || true)
    trimbox=$(command gs -dBATCH -dNOPAUSE -q -c "($file) (r) file runpdfbegin 1 pdfgetpage /TrimBox pget pop ==" -f /dev/null 2>/dev/null | head -1 || true)
    if [[ -n "$mediabox" && -n "$trimbox" && "$mediabox" != "$trimbox" ]]; then
      has_bleed="yes (TrimBox differs from MediaBox)"
    else
      has_bleed="no bleed detected"
    fi
  fi
  printf "  %-26s %s\n" "Bleed:" "$has_bleed"

  # Readiness section
  printf "\n${BOLD}Readiness:${RESET}\n"
  local ready=1

  if [[ "$colorspace" == "RGB" ]]; then
    printf "  ${YELLOW}⚠ CMYK${RESET}     Convert to CMYK for offset printing\n"
    ready=0
  else
    printf "  ${GREEN}✓ CMYK${RESET}     Colorspace OK\n"
  fi

  if [[ -n "${not_embedded:-}" && "$not_embedded" -gt 0 ]]; then
    printf "  ${YELLOW}⚠ FONTS${RESET}    %s font(s) not embedded — embed before sending\n" "$not_embedded"
    ready=0
  else
    printf "  ${GREEN}✓ FONTS${RESET}    Fonts embedded\n"
  fi

  if [[ -n "${min_dpi:-}" ]]; then
    if [[ "$min_dpi" -lt 300 ]]; then
      printf "  ${YELLOW}⚠ DPI${RESET}      Min image DPI %s < 300 — may appear soft in print\n" "$min_dpi"
      ready=0
    else
      printf "  ${GREEN}✓ DPI${RESET}      Images at %s DPI\n" "$min_dpi"
    fi
  fi

  if [[ "$has_bleed" == "no bleed detected" ]]; then
    printf "  ${YELLOW}⚠ BLEED${RESET}    No bleed — add 3mm bleed for full-bleed designs\n"
  else
    printf "  ${GREEN}✓ BLEED${RESET}    %s\n" "$has_bleed"
  fi

  if [[ "$ready" == "1" ]]; then
    printf "\n  ${GREEN}${BOLD}Overall: READY FOR PRINT${RESET}\n"
  else
    printf "\n  ${YELLOW}${BOLD}Overall: NEEDS ATTENTION${RESET}\n"
  fi
}

_conv_analyze_image() {
  local file="$1"

  if ! command -v magick &>/dev/null; then
    _err "ImageMagick not found (magick)"; return 1
  fi

  local width height dpi_x dpi_y colorspace alpha
  width=$(magick identify -format "%w" "$file" 2>/dev/null)
  height=$(magick identify -format "%h" "$file" 2>/dev/null)
  dpi_x=$(magick identify -format "%x" "$file" 2>/dev/null | awk '{print int($1)}')
  dpi_y=$(magick identify -format "%y" "$file" 2>/dev/null | awk '{print int($1)}')
  colorspace=$(magick identify -format "%[colorspace]" "$file" 2>/dev/null)
  alpha=$(magick identify -format "%A" "$file" 2>/dev/null)

  printf "  %-26s %s x %s px\n" "Dimensions:" "$width" "$height"
  printf "  %-26s %s x %s DPI\n" "DPI:" "$dpi_x" "$dpi_y"
  printf "  %-26s %s\n" "Colorspace:" "$colorspace"
  printf "  %-26s %s\n" "Alpha channel:" "${alpha:-False}"

  # Printable size at 300 DPI
  if [[ -n "$width" && -n "$height" && -n "$dpi_x" && "$dpi_x" -gt 0 ]]; then
    local print_w_mm print_h_mm
    print_w_mm=$(echo "$width $dpi_x" | awk '{printf "%.1f", $1 / $2 * 25.4}')
    print_h_mm=$(echo "$height $dpi_x" | awk '{printf "%.1f", $1 / $2 * 25.4}')
    printf "  %-26s %s x %s mm @ %s DPI\n" "Printable size:" "$print_w_mm" "$print_h_mm" "$dpi_x"
    local paper
    paper=$(_conv_detect_paper_mm "$print_w_mm" "$print_h_mm")
    printf "  %-26s %s\n" "Nearest paper size:" "$paper"
  fi

  # Readiness
  printf "\n${BOLD}Readiness:${RESET}\n"
  local ready=1

  case "$colorspace" in
    CMYK|cmyk)
      printf "  ${GREEN}✓ CMYK${RESET}     Colorspace OK\n" ;;
    *)
      printf "  ${YELLOW}⚠ CMYK${RESET}     Convert to CMYK for offset printing\n"
      ready=0 ;;
  esac

  if [[ -n "$dpi_x" && "$dpi_x" -lt 300 ]]; then
    printf "  ${YELLOW}⚠ DPI${RESET}      %s DPI — upscale to 300 DPI for print\n" "$dpi_x"
    ready=0
  else
    printf "  ${GREEN}✓ DPI${RESET}      %s DPI\n" "${dpi_x:-?}"
  fi

  if [[ "$alpha" == "True" ]]; then
    printf "  ${YELLOW}⚠ ALPHA${RESET}    Has transparency — flatten before printing\n"
    ready=0
  else
    printf "  ${GREEN}✓ ALPHA${RESET}    No transparency\n"
  fi

  if [[ "$ready" == "1" ]]; then
    printf "\n  ${GREEN}${BOLD}Overall: READY FOR PRINT${RESET}\n"
  else
    printf "\n  ${YELLOW}${BOLD}Overall: NEEDS ATTENTION${RESET}\n"
  fi
}

_conv_detect_paper_mm() {
  local w="$1" h="$2"
  # Normalize portrait
  local lw lh
  lw=$(echo "$w $h" | awk '{if($1>$2) print $2; else print $1}')
  lh=$(echo "$w $h" | awk '{if($1>$2) print $1; else print $2}')
  python3 -c "
sizes = {
  'business_card': (55, 85),
  'A7': (74, 105),
  'A6': (105, 148),
  'A5': (148, 210),
  'A4': (210, 297),
  'A3': (297, 420),
  'A2': (420, 594),
  'A1': (594, 841),
  'A0': (841, 1189),
  'letter': (216, 279),
  'postcard': (100, 148),
}
w, h = float('$lw'), float('$lh')
best, best_d = 'custom', 999
for name, (sw, sh) in sizes.items():
    d = abs(w-sw) + abs(h-sh)
    if d < best_d and d < 10:
        best, best_d = name, d
print(best)
" 2>/dev/null
}

# ── Product auto-detection ────────────────────────────────────────────────────

conv_detect_product() {
  local file="${1:-}"
  [[ -z "$file" ]] && { _err "Usage: conv --detect-product <file>"; return 1; }
  [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }

  local ext
  ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')

  local width_mm height_mm pages=1

  if [[ "$ext" == "pdf" ]]; then
    if command -v pdfinfo &>/dev/null; then
      local pinfo pagesize width_pt height_pt
      pinfo=$(pdfinfo "$file" 2>/dev/null)
      pages=$(echo "$pinfo" | awk '/^Pages:/{print $2}')
      pagesize=$(echo "$pinfo" | grep -i "^Page size:" | head -1)
      width_pt=$(echo "$pagesize" | awk '{print $3}')
      height_pt=$(echo "$pagesize" | awk '{print $5}')
      if [[ "$width_pt" =~ ^[0-9] ]]; then
        width_mm=$(echo "$width_pt" | awk '{printf "%.1f", $1 * 25.4 / 72}')
        height_mm=$(echo "$height_pt" | awk '{printf "%.1f", $1 * 25.4 / 72}')
      fi
    fi
  elif command -v magick &>/dev/null; then
    local w h dpi
    w=$(magick identify -format "%w" "$file" 2>/dev/null)
    h=$(magick identify -format "%h" "$file" 2>/dev/null)
    dpi=$(magick identify -format "%x" "$file" 2>/dev/null | awk '{print int($1)}')
    if [[ -n "$w" && -n "$dpi" && "$dpi" -gt 0 ]]; then
      width_mm=$(echo "$w $dpi" | awk '{printf "%.1f", $1/$2*25.4}')
      height_mm=$(echo "$h $dpi" | awk '{printf "%.1f", $1/$2*25.4}')
    fi
  fi

  # Check for CutContour (sticker indicator)
  local has_cutcontour=0
  if command -v gs &>/dev/null && [[ "$ext" == "pdf" ]]; then
    command gs -dBATCH -dNOPAUSE -q -sDEVICE=nullpage -dPDFSTOPONERROR "$file" 2>&1 | grep -qi "CutContour" && has_cutcontour=1 || true
  fi

  local product="unknown"
  local lw lh
  if [[ -n "$width_mm" && -n "$height_mm" ]]; then
    lw=$(echo "$width_mm $height_mm" | awk '{if($1>$2) print $2; else print $1}')
    lh=$(echo "$width_mm $height_mm" | awk '{if($1>$2) print $1; else print $2}')
    product=$(python3 -c "
lw, lh = float('$lw'), float('$lh')
pages = int('$pages') if '$pages'.isdigit() else 1
has_cut = '$has_cutcontour' == '1'

if has_cut: print('sticker'); exit()
if pages > 10: print('book'); exit()
if abs(lw-55)<5 and abs(lh-85)<5: print('business_card'); exit()
if abs(lw-100)<10 and abs(lh-148)<10: print('postcard'); exit()
if abs(lw-148)<10 and abs(lh-210)<10: print('flyer_a5'); exit()
if abs(lw-210)<10 and abs(lh-297)<10: print('flyer_a4'); exit()
if abs(lw-105)<10 and abs(lh-148)<10: print('flyer_a6'); exit()
if lw > 400 and lh > 560: print('poster'); exit()
if lw > 280 and lh > 380: print('poster'); exit()
print('unknown')
" 2>/dev/null)
  fi

  printf "%s\n" "$product"
  _info "Detected product type: $product"
}

# ── Printer URL matcher ───────────────────────────────────────────────────────

conv_printer_match() {
  local url="${1:-}"
  [[ -z "$url" ]] && { _err "Usage: conv --printer-match <url>"; return 1; }
  local slug
  slug="$(_conv_printer_resolve "$url")"
  if [[ -n "$slug" ]]; then
    _ok "Matched: $slug"
    echo "$slug"
  else
    _warn "No printer profile matched: $url"
    _info "Run 'conv --printer-list' to see available printers."
    return 1
  fi
}

# ── conv_for: the main pipeline ───────────────────────────────────────────────

conv_for() {
  local printer="${1:-}" product="${2:-}" file="${3:-}" preview=0
  [[ "${4:-}" == "--preview" ]] && preview=1

  if [[ -z "$printer" || -z "$product" || -z "$file" ]]; then
    _err "Usage: conv --for <printer> <product> <file> [--preview]"
    return 1
  fi
  [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }

  # Resolve printer
  local slug
  slug="$(_conv_printer_resolve "$printer")"
  if [[ -z "$slug" ]]; then
    _err "Printer not found: $printer"
    _info "Run 'conv --printer-list' to see available printers."
    return 1
  fi

  local pdir
  pdir="$(_conv_printer_dir)"
  local pfile="${pdir}/${slug}.yaml"

  # Load printer name + product spec via python
  local printer_name product_spec
  printer_name="$(_conv_yaml_get "$pfile" "name")"

  # Merge defaults + product
  local spec_json
  spec_json=$(python3 -c "
import yaml, json, sys
with open('$pfile') as f: d = yaml.safe_load(f) or {}
defaults = d.get('defaults', {}) or {}
products = d.get('products', {}) or {}
prod = products.get('$product', None)
if prod is None:
  # try partial match
  for k in products:
    if '$product' in k or k in '$product':
      prod = products[k]
      break
if prod is None:
  print(json.dumps({'error': 'product not found'}))
  sys.exit(0)
merged = {**defaults, **(prod or {})}
merged['_product_name'] = prod.get('name', '$product')
merged['_product_slug'] = '$product'
print(json.dumps(merged))
" 2>/dev/null)

  if echo "$spec_json" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'error' not in d else 1)" 2>/dev/null; then
    true
  else
    _err "Product '$product' not found for printer '$slug'"
    _info "Run: conv --product-list $slug"
    return 1
  fi

  # Analyze file silently
  local ext
  ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')
  local file_info=""
  if command -v pdfinfo &>/dev/null && [[ "$ext" == "pdf" ]]; then
    local pinfo pagesize
    pinfo=$(pdfinfo "$file" 2>/dev/null)
    local pg wp hp
    pg=$(echo "$pinfo" | awk '/^Pages:/{print $2}')
    pagesize=$(echo "$pinfo" | grep -i "^Page size:" | head -1)
    wp=$(echo "$pagesize" | awk '{print $3}')
    hp=$(echo "$pagesize" | awk '{print $5}')
    local wm hm
    if [[ "$wp" =~ ^[0-9] ]]; then
      wm=$(echo "$wp" | awk '{printf "%.0f", $1 * 25.4 / 72}')
      hm=$(echo "$hp" | awk '{printf "%.0f", $1 * 25.4 / 72}')
    fi
    file_info="${pg}p, ${wm}x${hm}mm"
  fi

  # Detect colorspace
  local file_cs="unknown"
  if command -v gs &>/dev/null && [[ "$ext" == "pdf" ]]; then
    local gs_out
    gs_out=$(command gs -dBATCH -dNOPAUSE -dNOPROMPT -q -sDEVICE=inkcov -o /dev/null "$file" 2>/dev/null | tail -3)
    if echo "$gs_out" | awk '{if($1+$2+$3>0 && $4==0) print "rgb"}' | grep -q rgb; then
      file_cs="RGB"
    else
      file_cs="CMYK"
    fi
  fi

  # Build output name
  local base="${file%.*}"
  local outfile="${base}_${slug}-${product}.pdf"

  # Read spec values
  local target_cs target_icc bleed_mm target_size
  target_cs=$(echo "$spec_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('colorspace','CMYK'))" 2>/dev/null)
  target_icc=$(echo "$spec_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('icc_profile','ISOcoated_v2_eci'))" 2>/dev/null)
  bleed_mm=$(echo "$spec_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bleed_mm','3'))" 2>/dev/null)
  target_size=$(echo "$spec_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('size',''))" 2>/dev/null)
  local prod_name
  prod_name=$(echo "$spec_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('_product_name','$product'))" 2>/dev/null)

  # Build plan
  printf "\n${BOLD}Print Preparation Plan${RESET}\n"
  printf "   Printer:  %s\n" "$printer_name"
  printf "   Product:  %s\n" "$prod_name"
  printf "   File:     %s%s\n" "$(basename "$file")" "${file_info:+ ($file_info, $file_cs)}"
  printf "\n   Will apply:\n"

  local do_cmyk=0 do_preflight=1
  if [[ "$file_cs" == "RGB" && "$target_cs" == "CMYK" ]]; then
    printf "   ${GREEN}✓${RESET} Convert RGB → CMYK (%s)\n" "$target_icc"
    do_cmyk=1
  fi
  if [[ -n "$target_size" ]]; then
    printf "   ${GREEN}✓${RESET} Resize to %s\n" "$target_size"
  fi
  if [[ "${bleed_mm:-0}" != "0" ]]; then
    printf "   ${GREEN}✓${RESET} Add %smm bleed + crop marks\n" "$bleed_mm"
  fi
  printf "   ${GREEN}✓${RESET} Preflight check on output\n"
  printf "\n   Output: %s\n\n" "$(basename "$outfile")"

  if [[ "$preview" == "1" ]]; then
    _info "Preview only — use without --preview to execute."
    return 0
  fi

  # Execute pipeline
  _info "Processing..."
  local tmpdir
  tmpdir=$(mktemp -d)
  local current="$file"
  local step=0

  # Step: CMYK conversion
  if [[ "$do_cmyk" == "1" ]]; then
    step=$((step+1))
    local tmp_cmyk="${tmpdir}/step${step}_cmyk.pdf"
    conv_pdf_rgb_to_cmyk "$current" "$tmp_cmyk" 2>/dev/null || {
      _warn "CMYK conversion failed — continuing with original colorspace"
    }
    [[ -f "$tmp_cmyk" ]] && current="$tmp_cmyk"
  fi

  # Step: Resize
  if [[ -n "$target_size" ]]; then
    step=$((step+1))
    local tmp_resize="${tmpdir}/step${step}_resize.pdf"
    conv_pdf_resize "$current" "$target_size" "$tmp_resize" 2>/dev/null || {
      _warn "Resize failed — skipping"
    }
    [[ -f "$tmp_resize" ]] && current="$tmp_resize"
  fi

  # Step: Bleed + crop marks
  if [[ "${bleed_mm:-0}" != "0" ]]; then
    step=$((step+1))
    local tmp_bleed="${tmpdir}/step${step}_bleed.pdf"
    conv_pdf_crop_marks "$current" "$bleed_mm" "$tmp_bleed" 2>/dev/null || {
      _warn "Bleed/crop marks failed — skipping"
    }
    [[ -f "$tmp_bleed" ]] && current="$tmp_bleed"
  fi

  # Copy final to output
  cp "$current" "$outfile"
  rm -rf "$tmpdir"

  # Preflight
  if [[ "$do_preflight" == "1" ]]; then
    printf "\n"
    conv_pdf_preflight "$outfile" 2>/dev/null || true
  fi

  local fsize=""
  if command -v du &>/dev/null; then
    fsize=$(du -sh "$outfile" 2>/dev/null | awk '{print $1}')
  fi
  printf "\n${GREEN}${BOLD}Ready for upload: %s%s${RESET}\n" "$(basename "$outfile")" "${fsize:+ ($fsize)}"
}

# ── Interactive wizard ────────────────────────────────────────────────────────

conv_wizard() {
  local file="${1:-}"

  printf "\n${BOLD}${CYAN}🖨  Print Wizard${RESET}\n\n"

  # Ask for file if not provided
  if [[ -z "$file" || ! -f "$file" ]]; then
    read -r -p "? File path: " file
    file="${file/#\~/$HOME}"
    [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }
  fi

  # Auto-detect product
  local detected_product
  detected_product=$(conv_detect_product "$file" 2>/dev/null | head -1)

  # List printers
  local pdir b
  pdir="$(_conv_printer_dir)"
  local printer_slugs=()
  for f in "${pdir}"/*.yaml; do
    [[ -f "$f" ]] || continue
    b="$(basename "$f" .yaml)"
    [[ "$b" == "_INDEX" || "$b" == "_defaults" ]] && continue
    printer_slugs+=("$b")
  done

  if [[ "${#printer_slugs[@]}" -eq 0 ]]; then
    _warn "No printer profiles found. Add YAML files to $pdir"
    return 1
  fi

  local sluglist
  sluglist=$(IFS=/ ; echo "${printer_slugs[*]}")
  local printer_choice
  read -r -p "? Which printer? [$sluglist] " printer_choice
  [[ -z "$printer_choice" ]] && printer_choice="${printer_slugs[0]}"

  local slug
  slug="$(_conv_printer_resolve "$printer_choice")"
  if [[ -z "$slug" ]]; then
    _warn "Printer '$printer_choice' not found. Try: conv --printer-list"
    return 1
  fi

  # List products for chosen printer
  local pfile="${pdir}/${slug}.yaml"
  local products_str
  products_str=$(python3 -c "
import yaml
with open('$pfile') as f: d = yaml.safe_load(f) or {}
for p in (d.get('products', {}) or {}).keys():
  print(p)
" 2>/dev/null | tr '\n' '/')

  local product_choice
  read -r -p "? Which product? [${products_str%/}] " product_choice
  [[ -z "$product_choice" ]] && product_choice=$(echo "$products_str" | cut -d/ -f1)

  # Size hint
  local size_hint=""
  if [[ -n "$detected_product" && "$detected_product" != "unknown" ]]; then
    read -r -p "? Auto-detected type: $detected_product — keep? [Y/n] " keep_det
    if [[ "${keep_det:-Y}" =~ ^[Nn] ]]; then
      read -r -p "? Enter size/type: " size_hint
    fi
  fi

  # Transparency
  local transparency
  read -r -p "? Flatten transparency? [Y/n] " transparency
  transparency="${transparency:-Y}"

  # Show plan (preview)
  printf "\n"
  conv_for "$slug" "$product_choice" "$file" --preview

  # Confirm
  local confirm
  read -r -p "? Apply and export? [Y/n] " confirm
  confirm="${confirm:-Y}"
  if [[ "$confirm" =~ ^[Yy] ]]; then
    conv_for "$slug" "$product_choice" "$file"
  else
    _info "Aborted."
  fi
}

# ── Natural language parser ───────────────────────────────────────────────────

conv_smart() {
  local query="${1:-}" file="${2:-}"

  [[ -z "$query" ]] && { _err "Usage: conv --smart \"query text\" [file]"; return 1; }

  # Check yaml available
  if ! command -v yq &>/dev/null; then
    python3 -c "import yaml" 2>/dev/null || {
      _warn "PyYAML not found. Install: uv pip install pyyaml  OR  brew install yq"
    }
  fi

  local query_lower
  query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

  # Product keyword mapping
  local product=""
  echo "$query_lower" | grep -qiE "(business.?card|visitenkarte|visite)" && product="business_card"
  echo "$query_lower" | grep -qiE "(poster|plakat)" && product="poster"
  echo "$query_lower" | grep -qiE "(roll.?up|rollup|banner)" && product="rollup"
  echo "$query_lower" | grep -qiE "(sticker|aufkleber)" && product="sticker"
  echo "$query_lower" | grep -qiE "(buch|book|brosch)" && product="book"
  echo "$query_lower" | grep -qiE "(postkarte|postcard)" && product="postcard"
  echo "$query_lower" | grep -qiE "(flyer|flugblatt|leaflet)" && product="flyer"
  [[ -z "$product" ]] && product="flyer"

  # Size hint
  local size_hint=""
  echo "$query_lower" | grep -qiE "\ba0\b" && size_hint="a0"
  echo "$query_lower" | grep -qiE "\ba1\b" && size_hint="a1"
  echo "$query_lower" | grep -qiE "\ba2\b" && size_hint="a2"
  echo "$query_lower" | grep -qiE "\ba3\b" && size_hint="a3"
  echo "$query_lower" | grep -qiE "\ba4\b" && size_hint="a4"
  echo "$query_lower" | grep -qiE "\ba5\b" && size_hint="a5"
  echo "$query_lower" | grep -qiE "\ba6\b" && size_hint="a6"

  if [[ -n "$size_hint" ]]; then
    product="${product}_${size_hint}"
  fi

  # Extract printer: try each slug and alias
  local pdir b found_alias pname
  pdir="$(_conv_printer_dir)"
  local printer_slug=""
  for f in "${pdir}"/*.yaml; do
    [[ -f "$f" ]] || continue
    b="$(basename "$f" .yaml)"
    [[ "$b" == "_INDEX" || "$b" == "_defaults" ]] && continue
    if echo "$query_lower" | grep -qi "$b"; then
      printer_slug="$b"
      break
    fi
    # Check aliases from YAML
    found_alias=$(python3 -c "
import yaml
with open('$f') as fh: d = yaml.safe_load(fh) or {}
aliases = d.get('aliases', []) or []
q = '$query_lower'
for a in aliases:
  if a.lower() in q or q in a.lower():
    print('$b')
    break
" 2>/dev/null)
    if [[ -n "$found_alias" ]]; then
      printer_slug="$found_alias"
      break
    fi
    # Check name
    pname=$(_conv_yaml_get "$f" "name" | tr '[:upper:]' '[:lower:]')
    if [[ -n "$pname" ]] && echo "$query_lower" | grep -qi "$pname"; then
      printer_slug="$b"
      break
    fi
  done

  if [[ -z "$printer_slug" ]]; then
    _warn "Could not identify printer from: '$query'"
    _info "Dropping into wizard..."
    conv_wizard "$file"
    return
  fi

  if [[ -z "$file" || ! -f "$file" ]]; then
    _warn "No file provided or file not found."
    read -r -p "? File path: " file
    file="${file/#\~/$HOME}"
    [[ -f "$file" ]] || { _err "File not found: $file"; return 1; }
  fi

  _info "Routing: printer=$printer_slug product=$product file=$(basename "$file")"
  conv_for "$printer_slug" "$product" "$file"
}
