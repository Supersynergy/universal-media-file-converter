# PDF Recipes

100 real-world PDF manipulation, conversion, and processing recipes using `conv`.

## TOC
- [Merge & Split](#merge--split) — 1–16
- [Page Operations](#page-operations) — 17–28
- [Compression & Optimization](#compression--optimization) — 29–36
- [OCR & Text Extraction](#ocr--text-extraction) — 37–46
- [Conversion From/To PDF](#conversion-fromto-pdf) — 47–58
- [Security & Permissions](#security--permissions) — 59–64
- [Metadata & Bookmarks](#metadata--bookmarks) — 65–72
- [Redaction & Watermarking](#redaction--watermarking) — 73–78
- [Inspection & Comparison](#inspection--comparison) — 79–84
- [Troubleshooting](#troubleshooting) — 85–90
- [Combo Workflows](#combo-workflows) — 91–100

---

## Merge & Split

### 1. Merge multiple PDFs into one
**Use case:** Combine chapter PDFs into final document  
**Command:**
```
conv --pdf-merge chapter1.pdf chapter2.pdf chapter3.pdf Handbuch_komplett.pdf
```

### 2. Merge all PDFs in folder
**Use case:** Combine all monthly reports  
**Command:**
```
conv --pdf-merge Berichte_2026/*.pdf Jahresbericht_2026.pdf
```

### 3. Split PDF into individual pages
**Use case:** Extract all pages as separate files  
**Command:**
```
conv --pdf-split Vertrag.pdf pages/page_%03d.pdf
```

### 4. Split PDF at specific page
**Use case:** Split 50-page contract at page 20  
**Command:**
```
conv --pdf-split Vertrag.pdf --at-page 20 Teil_1.pdf Teil_2.pdf
```

### 5. Split into N-page chunks
**Use case:** Send large document in 10-page segments  
**Command:**
```
conv --pdf-split Bericht.pdf --pages-per-file 10 segment_%02d.pdf
```

### 6. Extract specific page range
**Use case:** Extract pages 5-15 from large PDF  
**Command:**
```
conv --pdf-extract-pages Dokument.pdf 5-15 Auszug.pdf
```

### 7. Extract odd pages only
**Use case:** Duplex scan — front sides only  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sPageList=odd -sOutputFile=odd_pages.pdf input.pdf
```

### 8. Extract even pages only
**Use case:** Duplex scan — back sides only  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sPageList=even -sOutputFile=even_pages.pdf input.pdf
```

### 9. Merge odd + even (reassemble duplex scan)
**Use case:** Two separate scans → correct page order  
**Command:**
```
pdftk A=odd_pages.pdf B=even_pages.pdf shuffle A B output reassembled.pdf
```

### 10. Insert page at position
**Use case:** Add signature page to contract  
**Command:**
```
pdftk A=contract.pdf B=signature_page.pdf cat A1-19 B A20-end output with_signature.pdf
```

### 11. Delete specific page from PDF
**Use case:** Remove blank page 7 from scan  
**Command:**
```
pdftk Scan.pdf cat 1-6 8-end output Scan_clean.pdf
```

### 12. Replace page in PDF
**Use case:** Update single page without rewriting whole doc  
**Command:**
```
pdftk A=original.pdf B=new_page.pdf cat A1-4 B1 A6-end output updated.pdf
```

### 13. Merge with bookmark per file
**Use case:** Combine reports with chapter navigation  
**Command:**
```
conv --pdf-merge --bookmarks Quartal_Q1.pdf Quartal_Q2.pdf Quartal_Q3.pdf Quartal_Q4.pdf Jahresbericht.pdf
```

### 14. Split by bookmark/chapter
**Use case:** Book PDF → one file per chapter  
**Command:**
```
conv --pdf-split --by-bookmarks Buch.pdf chapters/
```

### 15. Interleave two PDFs (A1,B1,A2,B2...)
**Use case:** Front + back scan pages → correct order  
**Command:**
```
pdftk A=fronts.pdf B=backs.pdf shuffle A B output interleaved.pdf
```

### 16. Split every N pages for binding
**Use case:** Long print job → binding signatures  
**Command:**
```
conv --pdf-split Manuskript.pdf --pages-per-file 32 Druckbogen_%02d.pdf
```

---

## Page Operations

### 17. Rotate all pages 90° clockwise
**Use case:** Landscape PDF for portrait viewer  
**Command:**
```
conv --pdf-rotate Querformat.pdf 90 Hochformat.pdf
```

### 18. Rotate specific page
**Use case:** Page 5 is landscape in portrait document  
**Command:**
```
pdftk input.pdf rotate 5east output rotated.pdf
```

### 19. Rotate all pages 180° (upside down scan)
**Use case:** Scanner fed document upside down  
**Command:**
```
conv --pdf-rotate Scan_falsch.pdf 180 Scan_richtig.pdf
```

### 20. Crop PDF pages (remove margins)
**Use case:** Scanned pages with black borders  
**Command:**
```
pdfcrop --margins 0 Scan_mit_Rand.pdf Scan_clean.pdf
```

### 21. Add page numbers
**Use case:** Court document requires page numbers  
**Command:**
```
pdftk Dokument.pdf stamp pagenumbers.pdf output numbered.pdf
```

### 22. Resize pages to A4
**Use case:** Mixed-size PDF → unified A4  
**Command:**
```
conv --pdf-resize Gemischte_Groessen.pdf a4 A4_einheitlich.pdf
```

### 23. Resize pages to US Letter
**Use case:** German A4 PDF → US Letter for American client  
**Command:**
```
conv --pdf-resize Dokument_A4.pdf letter Dokument_Letter.pdf
```

### 24. Scale page content to fit
**Use case:** A3 CAD drawing → A4 for office printer  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=595 -dDEVICEHEIGHTPOINTS=842 -dFIXEDMEDIA -dPDFFitPage -sOutputFile=scaled.pdf a3_drawing.pdf
```

### 25. Add blank page after each page (for notes)
**Use case:** Study PDF with space for handwritten notes  
**Command:**
```
pdftk Skript.pdf cat 1-end output blank_interleaved.pdf
```
**Notes:** Requires creating blank page first: `magick -size 595x842 xc:white blank.pdf`

### 26. 2-up imposition (two pages per sheet)
**Use case:** Print booklet with two pages per A4 sheet  
**Command:**
```
conv --pdf-nup Praesentation.pdf 2 Praesentation_2up.pdf
```

### 27. 4-up imposition (four pages per sheet)
**Use case:** Handout with 4 slides per page  
**Command:**
```
conv --pdf-nup Folien.pdf 4 Handout_4up.pdf
```

### 28. Booklet imposition
**Use case:** A5 booklet printed on A4 double-sided  
**Command:**
```
conv --pdf-booklet Broschuere_A5.pdf Druckdaten_Booklet.pdf
```

---

## Compression & Optimization

### 29. Compress PDF for email (screen quality)
**Use case:** 50MB PDF → email attachment  
**Command:**
```
conv --pdf-compress Bericht_gross.pdf Bericht_klein.pdf --quality screen
```

### 30. Compress for ebook/sharing
**Use case:** Balance quality/size for Dropbox sharing  
**Command:**
```
conv --pdf-compress Handbuch.pdf Handbuch_web.pdf --quality ebook
```

### 31. Compress for print quality
**Use case:** Reduce size but keep print quality  
**Command:**
```
conv --pdf-compress Druckdatei.pdf Druckdatei_opt.pdf --quality printer
```

### 32. Prepress compression (max quality)
**Use case:** Print agency requires high quality  
**Command:**
```
conv --pdf-compress Master.pdf Prepress.pdf --quality prepress
```

### 33. Compress scanned PDF (image-heavy)
**Use case:** 200MB scan of 50 pages  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -dColorImageResolution=150 -dGrayImageResolution=150 -sOutputFile=compressed.pdf scan.pdf
```

### 34. Flatten annotations and form fields
**Use case:** Convert filled form to static PDF  
**Command:**
```
pdftk filled_form.pdf output flattened.pdf flatten
```

### 35. Remove embedded fonts (reduce size)
**Use case:** Font-heavy design PDF for web  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dNoOutputFonts -sOutputFile=no_fonts.pdf input.pdf
```

### 36. Optimize PDF for fast web viewing
**Use case:** Linearize PDF for browser streaming  
**Command:**
```
qpdf --linearize input.pdf web_optimized.pdf
```

---

## OCR & Text Extraction

### 37. OCR scanned PDF (German)
**Use case:** Scanned document → searchable PDF  
**Command:**
```
conv --pdf-ocr Scan_Rechnung.pdf Rechnung_ocr.pdf --lang deu
```

### 38. OCR scanned PDF (English)
**Use case:** English scan → searchable  
**Command:**
```
conv --pdf-ocr english_scan.pdf english_searchable.pdf --lang eng
```

### 39. OCR with multiple languages
**Use case:** Bilingual DE+EN document  
**Command:**
```
conv --pdf-ocr bilingual.pdf bilingual_ocr.pdf --lang deu+eng
```

### 40. Extract text from PDF
**Use case:** Parse invoice data for accounting  
**Command:**
```
conv --pdf-text Rechnung.pdf Rechnung.txt
```

### 41. Extract text preserving layout
**Use case:** Table-heavy report → keep columns  
**Command:**
```
pdftotext -layout Tabelle.pdf Tabelle.txt
```

### 42. Extract text from specific pages
**Use case:** Only need appendix pages 45-50  
**Command:**
```
pdftotext -f 45 -l 50 report.pdf appendix.txt
```

### 43. OCR batch scans
**Use case:** 50 scanned invoices → searchable archive  
**Command:**
```
for f in Scans/*.pdf; do conv --pdf-ocr "$f" "OCR/${f##*/}" --lang deu; done
```

### 44. Extract images from PDF
**Use case:** Designer needs original images from received PDF  
**Command:**
```
conv --pdf-images Broschuere.pdf images/
```

### 45. Extract PDF info/properties
**Use case:** Inspect PDF before processing  
**Command:**
```
conv --pdf-info Dokument.pdf
```

### 46. Search text in PDF (grep equivalent)
**Use case:** Find all mentions of "Rechnung" in PDF  
**Command:**
```
pdfgrep -n "Rechnung" Vertrag.pdf
```

---

## Conversion From/To PDF

### 47. Images to PDF
**Use case:** Scan photos → single PDF document  
**Command:**
```
magick scan_1.jpg scan_2.jpg scan_3.jpg output.pdf
```

### 48. PDF page to high-res JPEG
**Use case:** Render PDF slide as image  
**Command:**
```
magick -density 300 "Praesentation.pdf[0]" -quality 90 slide_01.jpg
```

### 49. PDF all pages to JPEG images
**Use case:** Convert entire PDF to image gallery  
**Command:**
```
magick -density 150 Dokument.pdf page_%03d.jpg
```

### 50. PDF to PNG (transparent background)
**Use case:** Extract PDF graphic with transparency  
**Command:**
```
magick -density 300 graphic.pdf -background none graphic.png
```

### 51. HTML to PDF
**Use case:** Invoice HTML template → PDF for sending  
**Command:**
```
wkhtmltopdf Rechnung.html Rechnung.pdf
```

### 52. Markdown to PDF
**Use case:** Documentation → shareable PDF  
**Command:**
```
pandoc README.md -o documentation.pdf
```

### 53. Word DOCX to PDF
**Use case:** Client sent Word file, need PDF for print  
**Command:**
```
libreoffice --headless --convert-to pdf Angebot.docx
```

### 54. Excel XLSX to PDF
**Use case:** Spreadsheet → printable PDF  
**Command:**
```
libreoffice --headless --convert-to pdf Kalkulation.xlsx
```

### 55. PowerPoint to PDF
**Use case:** Presentation → handout PDF  
**Command:**
```
libreoffice --headless --convert-to pdf Praesentation.pptx
```

### 56. PDF to DOCX (text-based PDF)
**Use case:** Edit received PDF in Word  
**Command:**
```
libreoffice --headless --infilter="writer_pdf_import" --convert-to docx Vertrag.pdf
```

### 57. EPUB to PDF
**Use case:** Ebook → printable version  
**Command:**
```
pandoc ebook.epub -o book_print.pdf
```

### 58. LaTeX to PDF
**Use case:** Academic paper compilation  
**Command:**
```
pdflatex paper.tex
```

---

## Security & Permissions

### 59. Add password to PDF
**Use case:** Send confidential report with encryption  
**Command:**
```
qpdf --encrypt "user_pass" "owner_pass" 256 -- input.pdf secured.pdf
```

### 60. Remove password from PDF
**Use case:** Unlock your own password-protected PDF  
**Command:**
```
qpdf --password="known_password" --decrypt locked.pdf unlocked.pdf
```

### 61. Set print-only permissions (no copy)
**Use case:** Send contract that can be printed but not copied  
**Command:**
```
qpdf --encrypt "" "owner_pass" 128 --print=full --modify=none --copy-text=n -- input.pdf restricted.pdf
```

### 62. Remove all PDF restrictions
**Use case:** Remove copy restriction from own document  
**Command:**
```
qpdf --password="owner_pass" --decrypt restricted.pdf unrestricted.pdf
```

### 63. Check if PDF is encrypted
**Use case:** Verify before processing  
**Command:**
```
conv --pdf-info encrypted.pdf | grep -i encrypt
```

### 64. Sign PDF (via Ghostscript)
**Use case:** Add digital signature placeholder  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=signed.pdf input.pdf signature.pdf
```

---

## Metadata & Bookmarks

### 65. Read PDF metadata
**Use case:** Inspect title/author before distributing  
**Command:**
```
conv --pdf-info Dokument.pdf
```

### 66. Set PDF metadata
**Use case:** Add proper title/author to exported PDF  
**Command:**
```
conv --meta-write Bericht.pdf Title="Jahresbericht 2026" Author="Supersynergy GmbH" Keywords="jahresbericht,finanzen"
```

### 67. Remove all PDF metadata
**Use case:** Strip personal info before public release  
**Command:**
```
qpdf --empty --from-stdin < input.pdf | exiftool -all= - -o clean_meta.pdf
```

### 68. Add bookmarks/TOC
**Use case:** Long PDF without navigation  
**Command:**
```
pdftk Buch.pdf dump_data > bookmarks.txt
# edit bookmarks.txt, then:
pdftk Buch.pdf update_info bookmarks.txt output Buch_mit_TOC.pdf
```

### 69. Extract bookmarks to text
**Use case:** Audit document structure  
**Command:**
```
pdftk document.pdf dump_data | grep -E "BookmarkTitle|BookmarkLevel|BookmarkPageNumber"
```

### 70. Set document properties
**Use case:** PDF/A archiving requires XMP metadata  
**Command:**
```
exiftool -Title="Dokument 2026" -Author="Maxim Supersynergy" -Subject="Bericht" Dokument.pdf
```

### 71. Verify PDF/A compliance
**Use case:** Archive submission requires PDF/A-1b  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=ps2write -sOutputFile=/dev/null -dPDFACompatibilityPolicy=1 input.pdf
```

### 72. Convert to PDF/A for archiving
**Use case:** Legal requirement for long-term archiving  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dPDFACompatibilityPolicy=1 -sOutputFile=archive.pdf input.pdf
```

---

## Redaction & Watermarking

### 73. Add watermark text to all pages
**Use case:** "DRAFT" watermark on work-in-progress  
**Command:**
```
pdftk Entwurf.pdf stamp watermark_draft.pdf output Entwurf_WM.pdf
```

### 74. Add logo watermark to all pages
**Use case:** Company branding on distributed report  
**Command:**
```
pdftk Bericht.pdf stamp logo_overlay.pdf output Bericht_branded.pdf
```

### 75. Watermark only first page
**Use case:** Confidential stamp on cover page  
**Command:**
```
pdftk A=Dokument.pdf B=confidential_stamp.pdf cat A1 output page1.pdf
pdftk page1.pdf stamp B output stamped_cover.pdf
pdftk stamped_cover.pdf A2-end output Dokument_vertraulich.pdf
```

### 76. Black out region (basic redaction)
**Use case:** Cover sensitive data for sharing  
**Command:**
```
magick -density 150 "page.pdf[0]" -fill black -draw "rectangle 100,200 400,220" redacted_page.jpg
magick redacted_page.jpg redacted.pdf
```

### 77. Add "COPY" diagonal watermark
**Use case:** Mark physical/digital copies  
**Command:**
```
magick -size 595x842 xc:white -font Helvetica -pointsize 100 -fill "rgba(200,200,200,0.5)" -rotate 45 -gravity center -annotate 0 "KOPIE" watermark_kopie.pdf
pdftk Dokument.pdf stamp watermark_kopie.pdf output Dokument_Kopie.pdf
```

### 78. Bates numbering
**Use case:** Legal document production numbering  
**Command:**
```
pdftk Dokument.pdf burst output page_%04d.pdf
for i in page_*.pdf; do pdftk "$i" stamp bates_stamp.pdf output "numbered/${i}"; done
```

---

## Inspection & Comparison

### 79. Compare two PDFs (diff)
**Use case:** Find changes between contract versions  
**Command:**
```
diff <(pdftotext v1.pdf -) <(pdftotext v2.pdf -)
```

### 80. Visual diff (render and compare)
**Use case:** Layout change detection between PDF versions  
**Command:**
```
magick -density 150 v1.pdf pages_v1/page_%03d.png
magick -density 150 v2.pdf pages_v2/page_%03d.png
for i in pages_v1/*.png; do magick "$i" "pages_v2/$(basename $i)" -compose Difference -composite diffs/diff_$(basename $i); done
```

### 81. Count pages in PDF
**Use case:** Verify before printing  
**Command:**
```
conv --pdf-info Buch.pdf | grep Pages
```

### 82. Check PDF version
**Use case:** Compatibility check before printing  
**Command:**
```
conv --pdf-info file.pdf | grep Version
```

### 83. List embedded fonts
**Use case:** Verify all fonts are embedded for print  
**Command:**
```
pdffonts Druckdatei.pdf
```

### 84. Check for transparency (print issue)
**Use case:** Transparencies can cause print problems  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=inkcov input.pdf 2>&1 | head -20
```

---

## Troubleshooting

### 85. Fix corrupted PDF
**Use case:** PDF won't open, may be partially corrupt  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=fixed.pdf corrupt.pdf
```

### 86. Repair cross-reference table
**Use case:** "xref table" error on open  
**Command:**
```
qpdf --recover corrupt.pdf repaired.pdf
```

### 87. Flatten PDF (resolve layers)
**Use case:** Complex layered PDF won't print correctly  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dFlattenLayers -sOutputFile=flat.pdf layered.pdf
```

### 88. Fix PDF with wrong media box
**Use case:** Pages appear too large/small in viewer  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dDEVICEWIDTHPOINTS=595 -dDEVICEHEIGHTPOINTS=842 -sOutputFile=fixed_box.pdf input.pdf
```

### 89. Resolve embedded color profile conflict
**Use case:** Colors look wrong after merge from different sources  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dColorConversionStrategy=/sRGB -sOutputFile=normalized_colors.pdf input.pdf
```

### 90. Reduce PDF that can't be opened due to size
**Use case:** 2GB PDF — no app can handle it  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dPDFSETTINGS=/screen -sOutputFile=small.pdf huge.pdf
```

---

## Combo Workflows

### 91. Scan → OCR → Compress → Archive
**Use case:** Paper invoice → searchable digital archive  
**Command:**
```
conv --pdf-ocr Scan_Rechnung_2026.pdf temp_ocr.pdf --lang deu
conv --pdf-compress temp_ocr.pdf Archiv/Rechnung_2026_ocr.pdf --quality ebook
conv --meta-write Archiv/Rechnung_2026_ocr.pdf Title="Rechnung 2026" Author="Supersynergy"
```

### 92. Report Generation → Merge → Watermark → Send
**Use case:** Monthly reports → combined → branded → distribute  
**Command:**
```
conv --pdf-merge Berichte_Jan/*.pdf Bericht_Jan.pdf
conv --pdf-compress Bericht_Jan.pdf Bericht_Jan_opt.pdf --quality ebook
pdftk Bericht_Jan_opt.pdf stamp logo_overlay.pdf output Bericht_Jan_final.pdf
```

### 93. Contract Processing → Split → Page-numbering → Sign-ready
**Use case:** Long contract → numbered sections → signing copies  
**Command:**
```
conv --pdf-split Vertrag_gesamt.pdf --at-page 25 Vertrag_Teil1.pdf Vertrag_Teil2.pdf
pdftk Vertrag_Teil1.pdf stamp pagenumbers.pdf output Vertrag_Teil1_num.pdf
qpdf --encrypt "pass123" "owner456" 256 -- Vertrag_Teil1_num.pdf Vertrag_Teil1_secure.pdf
```

### 94. Print-Ready Pipeline: Merge → Booklet → Compress
**Use case:** Book manuscript → print-ready booklet PDF  
**Command:**
```
conv --pdf-merge Kapitel_*.pdf Buch_gesamt.pdf
conv --pdf-booklet Buch_gesamt.pdf Buch_Booklet.pdf
conv --pdf-compress Buch_Booklet.pdf Buch_Druck.pdf --quality printer
```

### 95. Invoice Archive: Scan → OCR → Batch Compress → Organize
**Use case:** Year-end accounting — all paper invoices  
**Command:**
```
for f in Scans_2026/*.pdf; do
  fname=$(basename "${f%.pdf}")
  conv --pdf-ocr "$f" "OCR/${fname}_ocr.pdf" --lang deu
  conv --pdf-compress "OCR/${fname}_ocr.pdf" "Archiv/${fname}.pdf" --quality ebook
done
conv --pdf-merge Archiv/*.pdf Archiv/Alle_Rechnungen_2026.pdf
```

### 96. Duplex Scan Reassembly → Paginate → Compress
**Use case:** Flatbed duplex scan (fronts + backs separate)  
**Command:**
```
pdftk A=fronts.pdf B=backs.pdf shuffle A B output interleaved.pdf
pdftk interleaved.pdf stamp pagenumbers.pdf output numbered.pdf
conv --pdf-compress numbered.pdf final_scan.pdf --quality ebook
```

### 97. Presentation → Handout → Send-Ready
**Use case:** Keynote/PowerPoint → 4-up handout → email  
**Command:**
```
libreoffice --headless --convert-to pdf Praesentation.pptx
conv --pdf-nup Praesentation.pdf 4 Handout.pdf
conv --pdf-compress Handout.pdf Handout_mail.pdf --quality ebook
```

### 98. Confidential Report → Redact → Encrypt → Distribute
**Use case:** Board report → remove personal data → secure send  
**Command:**
```
conv --pdf-text Vorstand_Bericht.pdf text_preview.txt
# manually review, then:
conv --pdf-compress Vorstand_Bericht.pdf compressed.pdf --quality printer
qpdf --encrypt "empfaenger_pass" "admin_pass" 256 --print=full --modify=none -- compressed.pdf Bericht_vertraulich.pdf
```

### 99. Multi-Source Merge → TOC → Archive
**Use case:** Research notes + papers → single reference doc  
**Command:**
```
conv --pdf-merge Notizen.pdf paper1.pdf paper2.pdf paper3.pdf combined_raw.pdf
pdftk combined_raw.pdf dump_data > toc_template.txt
# Add bookmarks to toc_template.txt, then:
pdftk combined_raw.pdf update_info toc_template.txt output Forschung_2026.pdf
```

### 100. OCR Batch + Full-Text Index for Search
**Use case:** Document archive with search capability  
**Command:**
```
for f in Dokumente/*.pdf; do
  conv --pdf-ocr "$f" "Searchable/${f##*/}" --lang deu+eng
done
# build search index with pdfgrep
pdfgrep -rn "Suchbegriff" Searchable/ > suchergebnisse.txt
```
