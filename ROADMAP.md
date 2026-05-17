# Roadmap — Was noch fehlt (ghgrep + thinkrich analysis)

Analysiert via ghgrep (Stirling-PDF, yt-dlp, Home Assistant, OBS patterns) + ThinkRich-Filter (8 Denkmodelle).

---

## Tier 1 — High Impact, Low Effort (< 1 Tag)

### A. Stirling-PDF Gaps (12 Features)
```bash
conv --pdf-sign <file> <signature.png> <x,y>   # digital signature overlay
conv --pdf-password <file> set|remove|change
conv --pdf-watermark <file> "TEXT" [font] [opacity]
conv --pdf-page-numbers <file> [position]
conv --pdf-flatten <file>                       # annotations → baseline
conv --pdf-redact <file> <x,y,w,h>              # black-out regions
conv --pdf-diff <file1> <file2>                 # visual PDF compare
conv --pdf-remove-blank <file>                  # strip empty pages
conv --pdf-remove-duplicate <file>              # strip repeat pages
conv --pdf-scale <file> <0.5|1.5|...>
conv --pdf-reorder <file> "3,1,2,4"             # page reorder
conv --pdf-stamp <file> "DRAFT"                 # large stamp overlay
```
**Stack:** qpdf + ghostscript + magick. Alle Tools bereits installed.

### B. LibreOffice Headless (Office ↔ PDF)
```bash
conv rechnung.docx rechnung.pdf                  # auto via soffice --headless
conv angebot.odt angebot.pdf
conv präsentation.pptx slides.pdf
conv tabelle.xlsx tabelle.pdf
conv anleitung.docx anleitung_sanitized.docx    # strip tracked changes + metadata
```
**Install:** `brew install --cask libreoffice`
**Impact:** Öffnet kompletten Office-Markt. Steuerberater, Anwälte, Schulen — alle brauchen DOCX→PDF.

### C. yt-dlp Integration
```bash
conv --download <url>                            # yt-dlp best quality
conv --download <url> --audio-only               # → MP3
conv --download <url> --subs de,en               # + subtitles
conv --download-playlist <url> --parallel 4
```
**Install:** `brew install yt-dlp`
**Impact:** Podcaster, Musiker, Content-Creator. Eine der meistgenutzten Funktionen weltweit.

---

## Tier 2 — AI Features (2-3 Tage)

### D. Whisper Transcription (Audio → Text/SRT)
```bash
conv --transcribe audio.mp3 [de|en|auto]         # → .srt + .txt
conv --transcribe video.mp4                      # auto-extract audio first
conv --subs-auto video.mp4                       # → burn in subs automatically
```
**Stack:** `whisper.cpp` oder `mlx-whisper` (M4 Max optimized). 5-10× realtime auf M4.
**Impact:** Podcaster, Kurse, Barrierefreiheit-Pflicht (EAA ab 2025).

### E. Background Removal + Smart Crop
```bash
conv --bg-remove photo.jpg                       # rembg → transparent PNG
conv --smart-crop photo.jpg 1080x1080            # subject-detection
conv --upscale photo.jpg 4                       # Real-ESRGAN 4× (MLX)
```
**Stack:** `rembg` (u2net), `mlx-realesrgan` für M-chips.
**Impact:** E-Commerce, Shops, POD (Printful/Spreadshirt).

### F. DSGVO Auto-Anonymize
```bash
conv --blur-faces photo.jpg                      # face detection + blur
conv --blur-plates photo.jpg                     # license plate blur
conv --anonymize photo.jpg                       # faces + plates + strip-exif
```
**Stack:** OpenCV DNN oder YOLO-v11 (tiny-model).
**Impact:** Immobilienmakler, Autohaus, Pflegedienste, Schulen — alle DSGVO-getrieben.

---

## Tier 3 — Niche but Valuable (1-2 Tage each)

### G. Ebook Conversion (Calibre)
```bash
conv book.pdf book.epub
conv book.epub book.mobi
conv book.md book.epub
```
**Install:** `brew install --cask calibre`

### H. Spreadsheet / CSV
```bash
conv data.xlsx data.csv
conv data.csv data.json
conv --csv-preview data.csv                      # head + stats
conv --csv-to-sqlite data.csv data.db
```
**Stack:** `csvkit` + `python3 -c pandas`.

### I. Diagrams
```bash
conv diagram.mmd diagram.png                     # mermaid
conv schema.puml schema.svg                      # plantuml
conv graph.dot graph.pdf                         # graphviz
```
**Install:** `brew install mermaid-cli plantuml graphviz`

### J. Website → PDF/Screenshot
```bash
conv https://example.com out.pdf                 # headless browser
conv https://blog.com/article clean.pdf          # readability mode
conv https://example.com screenshot.png          # full-page
```
**Stack:** camoufox/agent-browser (bereits installed für Scraping).

---

## Tier 4 — Pro-Print (Advanced)

### K. Professional Print Specs
```bash
conv --pantone-check design.pdf                  # detect spot colors
conv --overprint-sim design.pdf                  # simulate overprint
conv --booklet-creep design.pdf 48pages          # creep compensation
conv --ink-limit design.pdf 280                  # custom TAC enforcement
conv --separation-preview design.pdf             # C/M/Y/K preview
```

### L. Smart Booklet / Book Production
```bash
conv --book-cover 300pages 90gsm A5              # calc spine width
conv --perfect-bound <front> <spine> <back>      # generate full cover
conv --saddle-stitch pages.pdf                   # 2-up with page reorder
```

---

## ThinkRich-Analyse — Strategische Filter

### 🧠 Kahneman (Bias)
✅ Tool löst echten Pain (Bayern cases validieren). Kein Feature-Bloat wenn Defaults + Wizard führen.
⚠️ **Gap:** 88 Commands kann überfordern → Top-10 Default-Dashboard beim `conv` ohne Args zeigen.

### 🔁 Munger (Inversion) — Was würde Adoption killen?
1. **Terminal-Angst** → Droplet-App (bereits in INTEGRATIONS.md, noch nicht gebaut)
2. **Breaking Changes** → Semantic Versioning + Changelog
3. **Einmalige Benutzung** → Recipes-Discovery: `conv --tip` zeigt random Power-Use-Case

### 🛡️ Taleb (Antifragile)
✅ Shell-based, keine Cloud, keine Auth — maximal robust.
✅ Battle-tested tools (ffmpeg, qpdf, exiftool seit 15+ Jahren).
→ **Verstärken:** Test-Suite gegen Tool-Updates (CI nightly mit `brew upgrade`).

### 🏎️ Dalio (Cycles)
- Print-Industrie: stabil, leicht wachsend (DE-online-druck Markt wächst 3-5% p.a.)
- Video: Explosion (TikTok/Insta/YouTube)
- AI-generiert: immer mehr Content braucht Konversion → **Tailwind**

### 🎯 Thiel (Monopoly / Moat)
Nicht monopol, aber **niche moat** für Bayern:
- 50 Printer-Profile = defensible data
- 124 Bayern-Cases = unique IP
- Wizard + NL-Dispatch = besser als reines Stirling-PDF

**Gap:** Keine Community/Contributor-Basis → GitHub-Release + Discord/Mailingliste.

### 🔑 Naval (Leverage)
✅ Code-Leverage: Skill-basiert, abrufbar aus allen Agents.
⚠️ **Gap:** Kein Revenue-Leverage. Pricing:
- Free CLI (wie Stirling-PDF)
- €49/mo DFY-Service („Wir machen eure Drucksachen print-ready")
- €299/mo White-Label für Druckereien
- €990/Setup Bayern-Handwerker-Paket (Installation + Training + 12 Mon Support)

### 🔄 Soros (Reflexivity)
Empfehlungs-Loop: erster Bayern-Kunde → 3 weitere (OUTREACH.md mapped). 
Verstärken: Case-Study-Produktion nach jedem Abschluss.

### 🏰 Buffett (Moat × Compounding)
**Moat:** Printer-Profile-DB + Bayern-Case-Library.
**Compounding:** Jeder neuer Kunde → neuer Case → neuer Recipe → tool wird besser → nächster Kunde leichter.

---

## Portfolio-Alignment

Synergie mit bestehendem System:
- **SupersynergyCRM:** Deal-Attachments automatisch processen (Integration-Hook da)
- **ZeroClaw Outreach:** PDF-Preflight vor Angebotsversand
- **Data Empire:** Lead-Enrichment mit automatischen Exposé-PDFs
- **Pocket Agent:** Push-Notification "Dokument ready"

---

## Priorisierte Build-Queue (nächste 30 Tage)

| # | Feature | Effort | Impact | Revenue-Linked |
|---|---------|--------|--------|----------------|
| 1 | LibreOffice DOCX→PDF | 2h | 🔥🔥🔥 | Steuerberater-Markt |
| 2 | Whisper transcribe | 4h | 🔥🔥🔥 | Podcaster €49/mo |
| 3 | DSGVO blur-faces | 6h | 🔥🔥🔥 | Pflege/Immobilien |
| 4 | yt-dlp download | 1h | 🔥🔥 | Universal |
| 5 | PDF watermark/sign | 3h | 🔥🔥 | Anwälte, Notare |
| 6 | Top-10 Default-Dashboard | 1h | 🔥🔥 | Onboarding |
| 7 | Droplet-App Builder | 2h | 🔥🔥 | Non-Terminal Users |
| 8 | bg-remove + upscale | 4h | 🔥 | E-Commerce POD |
| 9 | Diagram (mermaid/puml) | 2h | 🔥 | Dev/Consult |
| 10 | CSV/XLSX bulk | 3h | 🔥 | Steuerberater |

**Total: ~28h → 10 killer features**

---

## Revenue-Roadmap

**Phase 1 (Monat 1):** 10 Bayern-Kunden via OUTREACH.md channels → €490 MRR
**Phase 2 (Monat 3):** 50 Kunden + 3 White-Label-Deals → €4.300 MRR + €3K setup
**Phase 3 (Monat 6):** Pro-Tier mit AI-Features → €8-12K MRR
**Phase 4 (Monat 12):** B2B-Druckerei-White-Label + API-Tier → €20-30K MRR

Moat durch: Printer-DB + Bayern-Cases + Integration-Tiefe + Trust in Region.
