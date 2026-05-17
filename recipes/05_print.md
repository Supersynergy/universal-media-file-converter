# Print Production Recipes

100 real-world print production, preflight, and printer-specific recipes using `conv`.

## TOC
- [Preflight & Validation](#preflight--validation) — 1–10
- [PDF/X Standards](#pdfx-standards) — 11–18
- [Color Conversion](#color-conversion) — 19–28
- [Paper Sizes & Bleed](#paper-sizes--bleed) — 29–38
- [Imposition](#imposition) — 39–46
- [Printer-Specific Recipes](#printer-specific-recipes) — 47–72
- [POD Platforms](#pod-platforms) — 73–82
- [Wide Format & Banners](#wide-format--banners) — 83–88
- [Specialty Products](#specialty-products) — 89–94
- [Combo Workflows](#combo-workflows) — 95–100

---

## Preflight & Validation

### 1. Run preflight on flyer
**Use case:** Verify flyer before sending to printer  
**Command:**
```
conv --preflight Flyer_A5.pdf
```

### 2. Preflight business card
**Use case:** Check business card meets printer spec  
**Command:**
```
conv --preflight Visitenkarte.pdf
```

### 3. Preflight poster
**Use case:** Verify A1 poster has correct resolution and bleed  
**Command:**
```
conv --preflight Plakat_A1.pdf
```

### 4. DPI check on image
**Use case:** Will photo print sharp at 20x30cm?  
**Command:**
```
conv --dpi-check photo.jpg
```

### 5. DPI check on PDF
**Use case:** Check embedded image resolution  
**Command:**
```
conv --dpi-check Druckdatei.pdf
```

### 6. Check ink coverage (CMYK total)
**Use case:** Offset print has max 300% TAC limit  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=inkcov Druckdatei.pdf
```

### 7. Analyze print specs automatically
**Use case:** Unknown PDF — what print product is it?  
**Command:**
```
conv --analyze Dokument.pdf
```

### 8. Detect product type automatically
**Use case:** Match PDF to known product category  
**Command:**
```
conv --detect-product Flyer.pdf
```

### 9. Smart preflight (auto-detect + auto-fix)
**Use case:** One-click preflight and correction  
**Command:**
```
conv --smart Druckdatei.pdf print_ready.pdf
```

### 10. Print-ready export
**Use case:** Final step — ensure all requirements met  
**Command:**
```
conv --print-ready Entwurf.pdf Druckdatei_final.pdf
```

---

## PDF/X Standards

### 11. Convert to PDF/X-1a (offset press, full embed)
**Use case:** European offset press requires PDF/X-1a  
**Command:**
```
conv --pdf-x Druckdatei.pdf x1a Druckdatei_X1a.pdf
```

### 12. Convert to PDF/X-3 (device-independent color)
**Use case:** Wide-gamut print workflow  
**Command:**
```
conv --pdf-x Druckdatei.pdf x3 Druckdatei_X3.pdf
```

### 13. Convert to PDF/X-4 (transparency support)
**Use case:** Modern digital print with live transparency  
**Command:**
```
conv --pdf-x Druckdatei.pdf x4 Druckdatei_X4.pdf
```

### 14. PDF/X-1a with FOGRA39 profile
**Use case:** German/European offset print standard  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
  -dPDFX -dPDFSETTINGS=/prepress \
  -sColorConversionStrategy=CMYK \
  -sDefaultCMYKProfile=ISOcoated_v2_eci.icc \
  -sOutputFile=fogra39.pdf input.pdf
```

### 15. Verify PDF/X compliance
**Use case:** Check if file is truly PDF/X before submitting  
**Command:**
```
pdfinfo Druckdatei.pdf | grep -i pdfx
```

### 16. PDF/X-4 for digital print workflow
**Use case:** HP Indigo/Xerox digital press  
**Command:**
```
conv --pdf-x design.pdf x4 digital_print.pdf
```

### 17. Strip transparency for PDF/X-1a
**Use case:** Design with drop shadows → PDF/X-1a requires flat  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dPDFX -dCompatibilityLevel=1.3 -dFlattenTransparency -sOutputFile=flat_x1a.pdf input.pdf
```

### 18. Embed ICC profile in PDF
**Use case:** Enforce specific color profile on output  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sColorConversionStrategy=CMYK -sDefaultCMYKProfile=ISOcoated_v2_eci.icc -sOutputFile=with_icc.pdf input.pdf
```

---

## Color Conversion

### 19. RGB to CMYK (FOGRA39 / ISOcoated)
**Use case:** Screen design → European offset print  
**Command:**
```
conv --pdf-cmyk design_rgb.pdf design_cmyk.pdf
```

### 20. CMYK to RGB (for screen preview)
**Use case:** Print file → website preview image  
**Command:**
```
conv --pdf-rgb print_cmyk.pdf screen_preview.pdf
```

### 21. Convert to grayscale for black-only print
**Use case:** Cost reduction on single-color print job  
**Command:**
```
conv --pdf-gray farbig.pdf schwarz_weiss.pdf
```

### 22. Image RGB to CMYK
**Use case:** Photo for offset brochure  
**Command:**
```
conv --img-cmyk Foto.jpg Foto_CMYK.jpg
```

### 23. Image CMYK to RGB (for web use)
**Use case:** Print photo → website display  
**Command:**
```
conv --img-rgb Foto_CMYK.jpg Foto_RGB.jpg
```

### 24. Convert with SWOP profile (US market)
**Use case:** US printer requires SWOP v2  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sColorConversionStrategy=CMYK -sDefaultCMYKProfile=USWebCoatedSWOP.icc -sOutputFile=swop.pdf input.pdf
```

### 25. Convert to spot color (Pantone)
**Use case:** Brand color must be Pantone 485  
**Command:**
```
conv --pdf-cmyk design.pdf cmyk_base.pdf
# then manually set spot color in Indesign/Illustrator
```
**Notes:** True Pantone spot requires InDesign/Illustrator; conv converts process channel

### 26. Convert RGB screen colors to print-safe CMYK
**Use case:** Neon colors on screen → realistic print preview  
**Command:**
```
magick design.jpg -profile sRGB.icc -profile ISOcoated_v2_eci.icc cmyk_preview.jpg
```

### 27. Reduce ink coverage to 280% max
**Use case:** Newspaper print has lower ink limit  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dColorConversionStrategy=/CMYK -dMaxInkCoverage=280 -sOutputFile=reduced_ink.pdf input.pdf
```

### 28. Convert to ISO Newspaper (SNAP) profile
**Use case:** Newspaper print, low ink density  
**Command:**
```
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sDefaultCMYKProfile=SNAP_2007.icc -sOutputFile=newspaper.pdf input.pdf
```

---

## Paper Sizes & Bleed

### 29. Resize to A4 with bleed
**Use case:** Design is A4 content + 3mm bleed = 216x303mm  
**Command:**
```
conv --pdf-resize Inhalt.pdf a4 A4_mit_Beschnitt.pdf --bleed 3
```

### 30. Resize to A5 with 3mm bleed
**Use case:** Flyer A5 format  
**Command:**
```
conv --pdf-resize Flyer.pdf a5 Flyer_Druckdaten.pdf --bleed 3
```

### 31. Resize to A3 for large flyer
**Use case:** A3 poster/flyer  
**Command:**
```
conv --pdf-resize Plakat.pdf a3 Plakat_A3.pdf
```

### 32. Resize to business card (85x55mm)
**Use case:** Business card with bleed  
**Command:**
```
conv --pdf-resize Visitenkarte.pdf business-card Visitenkarte_Druck.pdf --bleed 2
```

### 33. Resize to postcard (148x105mm = A6)
**Use case:** Postcard for direct mail  
**Command:**
```
conv --pdf-resize Postkarte.pdf postcard Postkarte_Druck.pdf --bleed 3
```

### 34. Resize to A0 poster
**Use case:** Exhibition banner at full A0  
**Command:**
```
conv --pdf-resize design.pdf a0 Poster_A0.pdf
```

### 35. Resize to US Letter
**Use case:** German design → US client print  
**Command:**
```
conv --pdf-resize Dokument_A4.pdf letter Brief_Letter.pdf
```

### 36. Add crop marks
**Use case:** Printer needs crop marks for cutting  
**Command:**
```
conv --pdf-crop-marks Druckdatei.pdf Druckdatei_mit_Schnittmarken.pdf
```

### 37. Add crop marks with bleed
**Use case:** Flyer with 3mm bleed and crop marks  
**Command:**
```
conv --pdf-crop-marks Flyer.pdf Flyer_Schnittmarken.pdf --bleed 3
```

### 38. Check and set DPI
**Use case:** Image is 72 DPI → need 300 DPI for print  
**Command:**
```
conv --dpi-check image.jpg
conv --dpi-set image.jpg image_300dpi.jpg --dpi 300
```

---

## Imposition

### 39. 2-up booklet for A5 content on A4 sheet
**Use case:** A5 flyer two-up on A4, cut after printing  
**Command:**
```
conv --pdf-nup A5_content.pdf 2 A4_2up.pdf
```

### 40. 4-up A6 on A4
**Use case:** 4 postcards on one A4 sheet  
**Command:**
```
conv --pdf-nup Postkarte_A6.pdf 4 A4_4up_Postkarten.pdf
```

### 41. 8-up for business cards
**Use case:** 8 business cards per A4 sheet  
**Command:**
```
conv --pdf-nup Visitenkarte.pdf 8 Visitenkarten_8up.pdf
```

### 42. Booklet imposition (saddle stitch)
**Use case:** 16-page A5 booklet on A4 double-sided  
**Command:**
```
conv --pdf-booklet Broschuere_16Seiten.pdf Booklet_Druckdaten.pdf
```

### 43. Step-and-repeat label sheet
**Use case:** Label 48mm x 17mm repeated across A4  
**Command:**
```
conv --pdf-nup Label.pdf 24 Label_Sheet.pdf
```

### 44. Calendar monthly layout
**Use case:** 12 pages monthly → impositioned A3 calendar  
**Command:**
```
conv --pdf-nup Kalender_Monate.pdf 2 Kalender_A3_2up.pdf
```

### 45. Saddle-stitch booklet 32 pages
**Use case:** Product catalog printing  
**Command:**
```
conv --pdf-booklet Katalog_32Seiten.pdf Katalog_Druckbogen.pdf
```

### 46. Split poster for tiling print
**Use case:** A0 poster → 16x A4 tiles for office printer  
**Command:**
```
conv --poster-split Plakat_A0.pdf a4 Plakat_Tiles/
```

---

## Printer-Specific Recipes

### 47. Flyer A5 for Wirmachendruck
**Use case:** Standard flyer order for Wirmachendruck  
**Command:**
```
conv --for wirmachendruck flyer-a5 Flyer_Design.pdf
```

### 48. Business card for Wirmachendruck
**Use case:** Business card with correct specs  
**Command:**
```
conv --for wirmachendruck business-card Visitenkarte_Design.pdf
```

### 49. Poster A1 for Flyeralarm
**Use case:** A1 poster order at Flyeralarm  
**Command:**
```
conv --for flyeralarm poster-a1 Plakat_Design.pdf
```

### 50. Flyer DL (1/3 A4) for Flyeralarm
**Use case:** DL format flyer for mailing  
**Command:**
```
conv --for flyeralarm flyer-dl Flyer_DL.pdf
```

### 51. Business card for Moo (premium finish)
**Use case:** Square business card at Moo  
**Command:**
```
conv --for moo business-card-square Visitenkarte.pdf
```

### 52. Postcard for Saxoprint
**Use case:** A6 postcard for direct mail campaign  
**Command:**
```
conv --for saxoprint postcard-a6 Postkarte_Design.pdf
```

### 53. Flyer A4 for Saxoprint
**Use case:** A4 single-sided flyer  
**Command:**
```
conv --for saxoprint flyer-a4 Flyer_A4.pdf
```

### 54. Brochure for Onlineprinters
**Use case:** 8-page A4 brochure  
**Command:**
```
conv --for onlineprinters brochure-a4-8p Broschuere.pdf
```

### 55. Poster for Diedruckerei
**Use case:** Large format poster  
**Command:**
```
conv --for diedruckerei poster-a0 Plakat.pdf
```

### 56. Sticker with cutline for Jakprints
**Use case:** Die-cut sticker with vector cutline  
**Command:**
```
conv --for jakprints sticker-diecut Aufkleber_Design.pdf
```

### 57. T-shirt design for Printful
**Use case:** POD t-shirt upload  
**Command:**
```
conv --for printful tshirt-front Design.pdf
```

### 58. Tote bag for Spreadshirt
**Use case:** Spreadshirt product upload  
**Command:**
```
conv --for spreadshirt tote-bag Motiv.pdf
```

### 59. Banner for Vistaprint
**Use case:** Roll-up banner at Vistaprint  
**Command:**
```
conv --for vistaprint banner-rollup Banner_Design.pdf
```

### 60. Business card for Vistaprint US
**Use case:** US business card standard size  
**Command:**
```
conv --for vistaprint-us business-card Visitenkarte.pdf
```

### 61. Poster for Cewe-Print
**Use case:** Photo poster at Cewe  
**Command:**
```
conv --for cewe-print photo-poster-50x70 Poster_Foto.jpg
```

### 62. Photobook page for Cewe
**Use case:** Photo book layout  
**Command:**
```
conv --for cewe-print photobook-page Seite.jpg
```

### 63. Canvas print for Myposter
**Use case:** Photo on canvas  
**Command:**
```
conv --for myposter canvas-40x60 Urlaubsfoto.jpg
```

### 64. Flyer for Pixartprinting
**Use case:** Italian online printer, EU distribution  
**Command:**
```
conv --for pixartprinting flyer-a5 Flyer.pdf
```

### 65. Business card for Solopress (UK)
**Use case:** UK printer premium silk business card  
**Command:**
```
conv --for solopress business-card Visitenkarte.pdf
```

### 66. Sticker for Vistaprint
**Use case:** Circle sticker  
**Command:**
```
conv --for vistaprint sticker-circle Aufkleber.pdf
```

### 67. Greeting card for Zazzle
**Use case:** POD greeting card upload  
**Command:**
```
conv --for zazzle greeting-card Grußkarte.pdf
```

### 68. Book cover for Printcarrier
**Use case:** Softcover book cover  
**Command:**
```
conv --for printcarrier book-cover Buch_Cover.pdf
```

### 69. Catalog for 4over
**Use case:** US trade printer catalog  
**Command:**
```
conv --for 4over catalog-a4 Katalog.pdf
```

### 70. Brochure for Helloprint
**Use case:** Tri-fold brochure  
**Command:**
```
conv --for helloprint brochure-trifold Broschuere_3fach.pdf
```

### 71. Sticker sheet for Uprinting
**Use case:** Sheet of custom stickers  
**Command:**
```
conv --for uprinting sticker-sheet Aufkleber_Sheet.pdf
```

### 72. Postcard for Overnightprints
**Use case:** Rush order postcard  
**Command:**
```
conv --for overnightprints postcard Postkarte.pdf
```

---

## POD Platforms

### 73. Printful T-shirt (front print area 12"x16")
**Use case:** T-shirt design to Printful spec  
**Command:**
```
conv --for printful tshirt-front Design_Front.pdf
magick Design_Front.pdf -resize 3600x4800 -density 300 printful_tshirt.png
```

### 74. Printify phone case
**Use case:** Phone case skin design  
**Command:**
```
conv --for printify phone-case Handyhuelle_Design.pdf
```

### 75. Spreadshirt hoodie back
**Use case:** Hoodie print placement  
**Command:**
```
conv --for spreadshirt hoodie-back Motiv_Ruecken.pdf
```

### 76. Redbubble sticker (3000x3000px min)
**Use case:** Sticker upload to Redbubble  
**Command:**
```
magick Design.pdf -density 300 -resize 3000x3000 redbubble_sticker.png
```

### 77. Zazzle mug wrap (3.33"x9.33" at 300DPI)
**Use case:** Coffee mug print  
**Command:**
```
magick Tassen_Motiv.pdf -density 300 -resize 999x2799 zazzle_mug.png
```

### 78. Printful poster (24"x36" at 150DPI)
**Use case:** Printful premium poster  
**Command:**
```
conv --for printful poster-24x36 Poster_Design.pdf
```

### 79. Gogoprint flyer (Asia market)
**Use case:** Thai/SEA printer upload  
**Command:**
```
conv --for gogoprint flyer-a5 Flyer.pdf
```

### 80. Viaprinto canvas
**Use case:** German canvas printer  
**Command:**
```
conv --for viaprinto canvas-60x80 Foto.jpg
```

### 81. PSPrint US catalog
**Use case:** US professional printer catalog  
**Command:**
```
conv --for psprint catalog-letter Katalog.pdf
```

### 82. Gotprint business card US
**Use case:** US standard 3.5"x2" business card  
**Command:**
```
conv --for gotprint business-card Visitenkarte_US.pdf
```

---

## Wide Format & Banners

### 83. Roll-up banner (85x200cm)
**Use case:** Trade show pull-up banner  
**Command:**
```
conv --pdf-resize Banner.pdf --custom 2409x5669 Banner_Rollup.pdf
magick -density 96 Banner_Rollup.pdf Banner_96dpi.pdf
```
**Notes:** 96 DPI is sufficient for banners viewed from 1m+ distance

### 84. Large format poster at 72 DPI
**Use case:** Street banner — low DPI acceptable  
**Command:**
```
conv --dpi-set Plakat_Design.pdf Plakat_72dpi.pdf --dpi 72
```

### 85. Window graphic (full bleed)
**Use case:** Storefront window vinyl  
**Command:**
```
conv --pdf-resize Schaufenster_Design.pdf --custom 3000x2000 Schaufenster_Druck.pdf --bleed 10
```

### 86. Vehicle wrap section
**Use case:** Car door panel graphic  
**Command:**
```
conv --dpi-set Fahrzeugbeklebung.pdf Fahrzeug_72dpi.pdf --dpi 72
conv --pdf-cmyk Fahrzeug_72dpi.pdf Fahrzeug_CMYK.pdf
```

### 87. Poster split for office printing (A0 → A4 tiles)
**Use case:** Print A0 poster on home printer  
**Command:**
```
conv --poster-split Plakat_A0.pdf a4 Tiles/
```

### 88. Trade show backdrop (3x2m)
**Use case:** Event backdrop print  
**Command:**
```
conv --pdf-resize Backdrop_Design.pdf --custom 8504x5669 Backdrop_Druck.pdf
```

---

## Specialty Products

### 89. Business card wizard (guided setup)
**Use case:** First-time business card setup  
**Command:**
```
conv --wizard business-card
```

### 90. Business card finalized for production
**Use case:** Complete business card for print  
**Command:**
```
conv --business-card Visitenkarte_Design.pdf Visitenkarte_Druckdaten.pdf
```

### 91. QR code generation
**Use case:** Link QR for flyer  
**Command:**
```
conv --qr "https://supersynergy.de" qr_code.png
```

### 92. QR code as SVG (scalable)
**Use case:** QR code for print without pixelation  
**Command:**
```
conv --qr-svg "https://supersynergy.de" qr_code.svg
```

### 93. Barcode for product label
**Use case:** EAN-13 barcode for product  
**Command:**
```
conv --barcode-scan "4012345678901" barcode.png
```

### 94. Trace bitmap to vector (SVG)
**Use case:** Low-res logo → scalable vector for large format  
**Command:**
```
conv --trace logo_bitmap.png logo_vector.svg
conv --svg-pdf logo_vector.svg logo_vector.pdf
```

---

## Combo Workflows

### 95. Design → Preflight → CMYK → PDF/X → Submit
**Use case:** Complete offset print preparation  
**Command:**
```
conv --preflight Flyer_Design.pdf
conv --pdf-cmyk Flyer_Design.pdf Flyer_CMYK.pdf
conv --pdf-x Flyer_CMYK.pdf x1a Flyer_X1a.pdf
conv --pdf-crop-marks Flyer_X1a.pdf Flyer_Final.pdf --bleed 3
```

### 96. Logo Bitmap → Vector → PDF/X → Printer
**Use case:** Client sent low-res logo — vectorize and prepare  
**Command:**
```
conv --upscale logo_tiny.png logo_large.png --size 2000x2000
conv --trace logo_large.png logo_vector.svg
conv --svg-pdf logo_vector.svg logo_vector.pdf
conv --pdf-x logo_vector.pdf x1a logo_final.pdf
```

### 97. Photo → Print-Ready for Cewe Canvas
**Use case:** Holiday photo → canvas print order  
**Command:**
```
conv --dpi-check Urlaubsfoto.jpg
conv --img-cmyk Urlaubsfoto.jpg Urlaubsfoto_CMYK.jpg
conv --for cewe-print canvas-40x60 Urlaubsfoto_CMYK.jpg
```

### 98. Printful T-shirt Full Pipeline
**Use case:** Design → mockup → spec → upload  
**Command:**
```
conv --analyze TShirt_Design.pdf
conv --pdf-rgb TShirt_Design.pdf TShirt_RGB.pdf
magick TShirt_Design.pdf -density 300 -resize 4500x5400 tshirt_printful.png
# Upload tshirt_printful.png to Printful
```

### 99. Business Card Batch for Multiple Employees
**Use case:** 10 employees, same template, different names  
**Command:**
```
for name in "Max Müller" "Anna Schmidt" "Tom Weber"; do
  slug=$(echo "$name" | tr ' ' '_')
  magick Visitenkarte_Template.pdf -gravity south -pointsize 24 -annotate +0+30 "$name" "Visitenkarten/${slug}.pdf"
  conv --for wirmachendruck business-card "Visitenkarten/${slug}.pdf"
done
```

### 100. Wizard → Print Match → Printer-Specific Output
**Use case:** Unknown file → find best printer match → prepare  
**Command:**
```
conv --analyze Unbekannte_Datei.pdf
conv --printer-match Unbekannte_Datei.pdf
conv --printer-list
conv --for flyeralarm flyer-a5 Unbekannte_Datei.pdf
```
