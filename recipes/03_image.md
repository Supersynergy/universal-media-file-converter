# Image Recipes

100 real-world image conversion, resizing, and processing recipes using `conv`.

## TOC
- [Format Conversion](#format-conversion) — 1–18
- [Resize & Crop](#resize--crop) — 19–32
- [Color & Adjustments](#color--adjustments) — 33–42
- [EXIF & Metadata](#exif--metadata) — 43–55
- [Optimization & Compression](#optimization--compression) — 56–65
- [Social Media Sizes](#social-media-sizes) — 66–74
- [Print Prep](#print-prep) — 75–80
- [Batch Operations](#batch-operations) — 81–88
- [Watermarking & Overlays](#watermarking--overlays) — 89–93
- [Troubleshooting](#troubleshooting) — 94–96
- [Combo Workflows](#combo-workflows) — 97–100

---

## Format Conversion

### 1. HEIC to JPEG (iPhone photo)
**Use case:** Share iPhone photo with non-Apple devices  
**Command:**
```
conv IMG_1234.HEIC IMG_1234.jpg
```

### 2. JPEG to WebP (web optimization)
**Use case:** Replace JPEG on website for smaller size  
**Command:**
```
conv hero_image.jpg hero_image.webp
```

### 3. PNG to AVIF (next-gen format)
**Use case:** Modern browser with best compression  
**Command:**
```
conv logo.png logo.avif
```

### 4. PNG to JPEG (remove transparency)
**Use case:** Image with transparency → opaque JPEG  
**Command:**
```
conv graphic.png graphic.jpg
```

### 5. JPEG to PNG (need transparency)
**Use case:** Logo for web needs transparent background  
**Command:**
```
conv logo_white_bg.jpg logo.png
```

### 6. TIFF to JPEG (scanner output)
**Use case:** Scanner saves TIFF → email friendly JPEG  
**Command:**
```
conv Scan_Rechnung.tiff Rechnung.jpg
```

### 7. WebP to JPEG (compatibility)
**Use case:** Downloaded WebP won't open in old software  
**Command:**
```
conv downloaded.webp usable.jpg
```

### 8. AVIF to PNG
**Use case:** Modern format → universal compatibility  
**Command:**
```
conv modern.avif compatible.png
```

### 9. BMP to PNG
**Use case:** Old Windows paint/screenshot → compressed PNG  
**Command:**
```
conv screenshot.bmp screenshot.png
```

### 10. JPEG XL to JPEG (compatibility)
**Use case:** JXL not yet supported everywhere  
**Command:**
```
conv photo.jxl photo.jpg
```

### 11. HEIC to PNG (lossless from iPhone)
**Use case:** Screenshots from iPhone for document use  
**Command:**
```
conv Bildschirmfoto.HEIC Bildschirmfoto.png
```

### 12. GIF to PNG (single frame)
**Use case:** Extract first frame of animated GIF  
**Command:**
```
ffmpeg -i animation.gif -vframes 1 frame_0.png
```

### 13. PDF page to JPEG (rasterize)
**Use case:** Convert first PDF page to image for preview  
**Command:**
```
magick "Dokument.pdf[0]" -density 150 Dokument_preview.jpg
```

### 14. SVG to PNG (rasterize)
**Use case:** SVG logo → PNG for email signature  
**Command:**
```
magick -background none logo.svg logo_512.png
```

### 15. RAW (CR2/NEF/ARW) to JPEG
**Use case:** Camera RAW → shareable JPEG  
**Command:**
```
magick RAW_5678.CR2 -auto-level Foto.jpg
```

### 16. JPEG to JPEG XL (smaller, lossless-ish)
**Use case:** Archiving photos with better compression  
**Command:**
```
conv Urlaubsfoto.jpg Urlaubsfoto.jxl
```

### 17. PNG to ICO (favicon)
**Use case:** Website favicon from logo PNG  
**Command:**
```
magick logo.png -resize 32x32 favicon.ico
```

### 18. Multiple sizes to ICO
**Use case:** Multi-resolution favicon  
**Command:**
```
magick logo.png -resize 16x16 -resize 32x32 -resize 48x48 -resize 64x64 favicon.ico
```

---

## Resize & Crop

### 19. Resize to specific width (keep aspect)
**Use case:** Resize product photo to 800px wide  
**Command:**
```
resize product.jpg 800
```

### 20. Resize to max dimension
**Use case:** Ensure image fits within 1920px  
**Command:**
```
magick large.jpg -resize 1920x1920\> resized.jpg
```

### 21. Resize to exact dimensions (stretch)
**Use case:** Avatar must be exactly 400x400  
**Command:**
```
magick photo.jpg -resize 400x400! avatar.jpg
```

### 22. Resize and pad to exact size (letterbox)
**Use case:** Thumbnail must be 300x200 without cropping  
**Command:**
```
magick photo.jpg -resize 300x200 -background white -gravity center -extent 300x200 thumb.jpg
```

### 23. Crop center square
**Use case:** Profile picture from landscape photo  
**Command:**
```
conv --crop photo.jpg square.jpg --gravity center --size 500x500
```

### 24. Crop to specific region
**Use case:** Extract product from catalog scan  
**Command:**
```
magick scan.jpg -crop 400x300+100+50 product.jpg
```

### 25. Auto-rotate by EXIF orientation
**Use case:** Phone photo sideways — fix without re-shoot  
**Command:**
```
conv --auto-rotate IMG_9999.jpg IMG_9999_fixed.jpg
```

### 26. Rotate 90° clockwise
**Use case:** Scanned document in wrong orientation  
**Command:**
```
magick Scan_Vertrag.tiff -rotate 90 Scan_Vertrag_rotiert.jpg
```

### 27. Flip horizontally
**Use case:** Mirror selfie correction  
**Command:**
```
magick selfie.jpg -flop mirror.jpg
```

### 28. Smart crop (face-aware) via gravity
**Use case:** Headshot crop centered on face  
**Command:**
```
magick portrait.jpg -gravity north -crop 500x500+0+0 headshot.jpg
```

### 29. Generate retina variant (2x)
**Use case:** @2x image for Retina display  
**Command:**
```
resize icon.png 128
cp icon.png icon@2x.png
resize icon.png 64
```

### 30. Thumbnail for product listing (320x320)
**Use case:** E-commerce product grid  
**Command:**
```
conv --thumbnail-grid product.jpg thumb.jpg --size 320
```

### 31. Batch resize all JPEG to 1200px
**Use case:** Photo gallery web prep  
**Command:**
```
convall jpg jpg ./Fotos/ --resize 1200 --output-dir ./Fotos_Web/
```

### 32. Resize only if larger than threshold
**Use case:** Don't upscale small images in batch  
**Command:**
```
magick photo.jpg -resize 1920x1920\> safe_resized.jpg
```

---

## Color & Adjustments

### 33. Convert to grayscale
**Use case:** Documentary style, black & white  
**Command:**
```
magick color.jpg -grayscale Rec709Luma bw.jpg
```

### 34. Apply sepia tone
**Use case:** Vintage look for old-style project  
**Command:**
```
magick photo.jpg -sepia-tone 80% sepia.jpg
```

### 35. Adjust brightness and contrast
**Use case:** Fix underexposed indoor photo  
**Command:**
```
magick dark.jpg -brightness-contrast 15x20 bright.jpg
```

### 36. Increase saturation
**Use case:** Travel photo needs more color pop  
**Command:**
```
magick Urlaubsfoto.jpg -modulate 100,140,100 vibrant.jpg
```

### 37. Correct white balance (cool to warm)
**Use case:** Indoor photo with blue cast  
**Command:**
```
magick cold.jpg -color-matrix "1.1 0 0 0 1 0 0 0 0.9" warm.jpg
```

### 38. HDR tone mapping
**Use case:** Flatten HDR image for standard display  
**Command:**
```
magick hdr.tiff -tone-map 100x100 tonemapped.jpg
```

### 39. Remove color cast (auto white balance)
**Use case:** Scanner has yellow cast  
**Command:**
```
magick scan.jpg -auto-level auto_wb.jpg
```

### 40. Sharpen blurry photo
**Use case:** Slightly out-of-focus shot  
**Command:**
```
magick blurry.jpg -unsharp 0x1+1.5+0.05 sharpened.jpg
```

### 41. Apply vignette effect
**Use case:** Portrait with darkened edges  
**Command:**
```
magick portrait.jpg -vignette 0x8+4+4 portrait_vignette.jpg
```

### 42. Desaturate specific color range (make sky grey)
**Use case:** Selective color editing  
**Command:**
```
magick photo.jpg -region "200x100+300+0" -modulate 100,0,100 edited.jpg
```

---

## EXIF & Metadata

### 43. Strip all EXIF (privacy)
**Use case:** Remove GPS/camera data before sharing  
**Command:**
```
conv --strip-exif photo.jpg clean_photo.jpg
```

### 44. Strip GPS only (keep camera info)
**Use case:** Keep camera model but remove location  
**Command:**
```
magick photo.jpg -strip -set EXIF:Make "$(identify -verbose photo.jpg | grep 'exif:Make' | cut -d= -f2)" no_gps.jpg
```
**Notes:** Use exiftool for precise GPS-only removal: `exiftool -GPSLatitude= -GPSLongitude= photo.jpg`

### 45. Read all EXIF data
**Use case:** Inspect photo before processing  
**Command:**
```
conv --meta-read photo.jpg
```

### 46. Set creation date from filename
**Use case:** Scanned photos with date in filename  
**Command:**
```
conv --set-date "Foto_2024-08-15.jpg" --date "2024:08:15 12:00:00"
```

### 47. Fix camera clock (shift date by 2 hours)
**Use case:** Camera was in wrong timezone  
**Command:**
```
exiftool -DateTimeOriginal+="0:0:0 2:0:0" *.jpg
```

### 48. Embed copyright in EXIF
**Use case:** Watermark photos legally before upload  
**Command:**
```
conv --meta-write photo.jpg Copyright="© 2026 Supersynergy. All rights reserved." Artist="Supersynergy"
```

### 49. Batch copyright all JPEGs in folder
**Use case:** Photography business — protect entire shoot  
**Command:**
```
for f in Shooting_2026/*.jpg; do conv --meta-write "$f" Copyright="© 2026 Maxim Supersynergy"; done
```

### 50. Copy EXIF from original to converted
**Use case:** Converted image lost its EXIF  
**Command:**
```
conv --meta-copy original.jpg converted.webp
```

### 51. Backup EXIF to sidecar file
**Use case:** Non-destructive metadata backup  
**Command:**
```
conv --meta-backup photo.jpg photo_meta.json
```

### 52. Rename by EXIF date
**Use case:** Camera photos with generic names → dated filenames  
**Command:**
```
exiftool '-FileName<DateTimeOriginal' -d "%Y-%m-%d_%H-%M-%S%%-c.%%e" *.jpg
```

### 53. Detect photos without EXIF (edited/screenshots)
**Use case:** Filter out non-camera images from library  
**Command:**
```
exiftool -if '!$DateTimeOriginal' -filename *.jpg
```

### 54. Set IPTC keywords for stock photo
**Use case:** Upload to Shutterstock/Adobe Stock with tags  
**Command:**
```
exiftool -Keywords="nature,landscape,travel,summer" -Subject="nature,landscape,travel,summer" photo.jpg
```

### 55. Remove IPTC data
**Use case:** Strip stock agency watermark IPTC before edit  
**Command:**
```
exiftool -IPTC:all= photo.jpg
```

---

## Optimization & Compression

### 56. Optimize JPEG for web (reduce file size)
**Use case:** Product photo too large for page load  
**Command:**
```
optimg product.jpg
```

### 57. Optimize all images in directory
**Use case:** Entire web project image optimization  
**Command:**
```
optall ./website/images/
```

### 58. Convert PNG to WebP with quality control
**Use case:** Reduce PNG while maintaining visual quality  
**Command:**
```
magick input.png -quality 85 output.webp
```

### 59. Progressive JPEG for faster perceived load
**Use case:** Hero images on slow connections  
**Command:**
```
magick hero.jpg -interlace JPEG progressive_hero.jpg
```

### 60. Reduce JPEG quality to target file size
**Use case:** Image must be under 200KB  
**Command:**
```
magick input.jpg -define jpeg:extent=200KB output.jpg
```

### 61. PNG crush (lossless compression)
**Use case:** Reduce PNG without any quality loss  
**Command:**
```
pngcrush input.png output.png
```

### 62. WebP lossless for logos/graphics
**Use case:** Logo with transparency, smaller than PNG  
**Command:**
```
magick logo.png -define webp:lossless=true logo.webp
```

### 63. AVIF with quality tuning
**Use case:** Maximum compression AVIF for web  
**Command:**
```
magick photo.jpg -quality 70 photo.avif
```

### 64. Strip PNG metadata for smaller file
**Use case:** Exported from Photoshop with color profiles  
**Command:**
```
magick bloated.png -strip lean.png
```

### 65. Generate multiple WebP sizes for srcset
**Use case:** Responsive images for HTML srcset attribute  
**Command:**
```
for w in 480 768 1200 1920; do magick source.jpg -resize ${w}x source_${w}w.webp; done
```

---

## Social Media Sizes

### 66. Instagram square post (1080x1080)
**Use case:** Feed photo — square format  
**Command:**
```
magick photo.jpg -resize 1080x1080^ -gravity center -extent 1080x1080 instagram_square.jpg
```

### 67. Instagram portrait post (1080x1350)
**Use case:** Portrait feed, more screen real estate  
**Command:**
```
magick portrait.jpg -resize 1080x1350^ -gravity center -extent 1080x1350 instagram_portrait.jpg
```

### 68. Instagram story (1080x1920)
**Use case:** Vertical story format  
**Command:**
```
magick photo.jpg -resize 1080x1920^ -gravity center -extent 1080x1920 story.jpg
```

### 69. Twitter/X card (1200x675)
**Use case:** Link preview image  
**Command:**
```
magick banner.jpg -resize 1200x675^ -gravity center -extent 1200x675 twitter_card.jpg
```

### 70. LinkedIn banner (1584x396)
**Use case:** Profile background banner  
**Command:**
```
magick photo.jpg -resize 1584x396^ -gravity center -extent 1584x396 linkedin_banner.jpg
```

### 71. Facebook cover (820x312)
**Use case:** Facebook page cover photo  
**Command:**
```
magick cover.jpg -resize 820x312^ -gravity center -extent 820x312 fb_cover.jpg
```

### 72. YouTube thumbnail (1280x720)
**Use case:** Video thumbnail for search visibility  
**Command:**
```
magick frame.jpg -resize 1280x720^ -gravity center -extent 1280x720 youtube_thumb.jpg
```

### 73. Pinterest pin (1000x1500)
**Use case:** Optimal Pinterest pin ratio  
**Command:**
```
magick photo.jpg -resize 1000x1500^ -gravity center -extent 1000x1500 pinterest.jpg
```

### 74. OpenGraph image (1200x630)
**Use case:** Social media link preview for any platform  
**Command:**
```
magick banner.jpg -resize 1200x630^ -gravity center -extent 1200x630 og_image.jpg
```

---

## Print Prep

### 75. Convert to 300 DPI for print
**Use case:** Web image (72 DPI) → print-ready  
**Command:**
```
magick web_image.jpg -density 300 -units PixelsPerInch print_ready.jpg
```

### 76. Check DPI of image
**Use case:** Verify image meets print requirements  
**Command:**
```
conv --dpi-check image.jpg
```

### 77. Convert RGB to CMYK for offset print
**Use case:** Commercial print requires CMYK  
**Command:**
```
conv --img-cmyk photo.jpg photo_cmyk.jpg
```

### 78. Upscale small image for large print
**Use case:** Logo only available at 200px — need A3 print  
**Command:**
```
conv --upscale logo_small.png logo_large.png --size 3508x4961
```

### 79. Add bleed border (3mm bleed)
**Use case:** Business card with bleed for printer  
**Command:**
```
magick design.jpg -bordercolor white -border 35x35 design_with_bleed.jpg
```
**Notes:** 35px ≈ 3mm at 300 DPI

### 80. TIFF for professional print workflow
**Use case:** Agency requires TIFF, lossless  
**Command:**
```
magick photo.jpg -compress lzw -type TrueColor Foto_Druck.tiff
```

---

## Batch Operations

### 81. Batch HEIC to JPEG (iPhone import)
**Use case:** iPhone photo import → convert all HEIC  
**Command:**
```
convall HEIC jpg ~/Pictures/iPhone/ --output-dir ~/Pictures/JPEG/
```

### 82. Batch resize and optimize for web
**Use case:** Product photos for e-commerce upload  
**Command:**
```
convall jpg jpg ./Produktfotos/ --resize 1200 --output-dir ./web/
optall ./web/
```

### 83. Batch strip EXIF from all photos
**Use case:** Client delivery without personal metadata  
**Command:**
```
for f in Shooting_Abgabe/*.jpg; do conv --strip-exif "$f" "clean/${f##*/}"; done
```

### 84. Batch rename by date + sequence
**Use case:** Sort camera dump into dated filenames  
**Command:**
```
conv --rename-batch '*.jpg' '{date}_{seq:3}.jpg'
```

### 85. Batch convert old BMPs
**Use case:** Archive of Windows XP screenshots  
**Command:**
```
convall bmp png ./Screenshots_Alt/ --output-dir ./Screenshots_PNG/
```

### 86. Batch add watermark to all JPEGs
**Use case:** Protect photography portfolio before upload  
**Command:**
```
for f in Portfolio/*.jpg; do magick "$f" watermark.png -gravity southeast -composite -quality 90 "watermarked/${f##*/}"; done
```

### 87. Batch thumbnail for media library
**Use case:** Thumbnail previews for image manager  
**Command:**
```
for f in Bilder/*.jpg; do resize "$f" 300 && mv "${f%.jpg}_300.jpg" "thumbs/${f##*/}"; done
```

### 88. Batch auto-rotate by EXIF
**Use case:** Folder of mixed-orientation photos  
**Command:**
```
for f in Fotos/*.jpg; do conv --auto-rotate "$f" "rotiert/${f##*/}"; done
```

---

## Watermarking & Overlays

### 89. Add text watermark
**Use case:** Copyright text on product photos  
**Command:**
```
magick photo.jpg -gravity southeast -fill "rgba(255,255,255,0.5)" -pointsize 24 -annotate +10+10 "© 2026 Supersynergy" watermarked.jpg
```

### 90. Add logo watermark (bottom right)
**Use case:** Brand all photos with logo  
**Command:**
```
magick photo.jpg logo_transparent.png -gravity southeast -geometry +10+10 -composite branded.jpg
```

### 91. Create comparison before/after grid
**Use case:** Editing comparison for client presentation  
**Command:**
```
magick before.jpg after.jpg +append comparison.jpg
```

### 92. Create 4-image grid collage
**Use case:** Instagram 4-up product collage  
**Command:**
```
magick photo1.jpg photo2.jpg photo3.jpg photo4.jpg \
  \( -clone 0-1 +append \) \
  \( -clone 2-3 +append \) \
  -delete 0-3 -append collage.jpg
```

### 93. Add border frame
**Use case:** Artistic border for print  
**Command:**
```
magick photo.jpg -bordercolor black -border 20x20 framed.jpg
```

---

## Troubleshooting

### 94. Fix corrupt JPEG (partial recovery)
**Use case:** JPEG from faulty SD card  
**Command:**
```
magick -define jpeg:preserve-settings corrupt.jpg recovered.jpg
```

### 95. Convert image with unknown format
**Use case:** File with wrong extension  
**Command:**
```
conv --probe unknown_file
magick unknown_file correct_output.jpg
```

### 96. Handle very large TIFF (memory limit)
**Use case:** 1GB+ TIFF from drum scanner  
**Command:**
```
magick -limit memory 512MB -limit map 1GB huge.tiff output.jpg
```

---

## Combo Workflows

### 97. iPhone Photos → Web Gallery (HEIC → WebP → Optimized)
**Use case:** Holiday photos for family web gallery  
**Command:**
```
convall HEIC webp ~/Pictures/Urlaub_2026/ --output-dir ./gallery/
optall ./gallery/
for f in ./gallery/*.webp; do resize "$f" 1200; done
```

### 98. Product Photos → E-commerce Ready Pipeline
**Use case:** New product shoot → marketplace upload  
**Command:**
```
# Auto-rotate, convert, resize, watermark, optimize
for f in ./Produktfotos_Roh/*.jpg; do
  fname=$(basename "$f")
  conv --auto-rotate "$f" "temp/${fname}"
  magick "temp/${fname}" -resize 1200x1200^ -gravity center -extent 1200x1200 "web/${fname}"
  conv --strip-exif "web/${fname}" "web/${fname}"
done
optall ./web/
```

### 99. Photography Delivery → Strip EXIF → Watermark → Export
**Use case:** Client delivery without camera metadata but with credit  
**Command:**
```
for f in ./Shooting/*.jpg; do
  fname=$(basename "$f")
  conv --strip-exif "$f" "temp/${fname}"
  magick "temp/${fname}" watermark.png -gravity southeast -geometry +15+15 -composite "delivery/${fname}"
done
```

### 100. Social Media Multi-Format from One Hero Image
**Use case:** One photo → all platform variants  
**Command:**
```
src="hero_photo.jpg"
magick "$src" -resize 1080x1080^ -gravity center -extent 1080x1080 social/instagram_square.jpg
magick "$src" -resize 1080x1920^ -gravity center -extent 1080x1920 social/instagram_story.jpg
magick "$src" -resize 1200x675^ -gravity center -extent 1200x675 social/twitter_card.jpg
magick "$src" -resize 1200x630^ -gravity center -extent 1200x630 social/og_image.jpg
magick "$src" -resize 1584x396^ -gravity center -extent 1584x396 social/linkedin_banner.jpg
optall ./social/
```
