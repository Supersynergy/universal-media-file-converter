# Universal Media Converter (`conv`)

One shell function for every media task — convert, trim, concat, OCR, print-prep,
and **archive-grade compression with no real quality loss**.

```bash
source conv.sh        # or: bash install.sh   (adds to shell rc)
conv --help
```

## Archive-grade compression

Max-shrink photos & videos for phone storage / long-term archive, keeping
zoom + edit + bit-exact-restore where it matters.

| Command | Codec | Size | Loss |
|---------|-------|------|------|
| `conv --archive <path>` | video x265 CRF18 10-bit · image JXL `-d1` | ~15-50% | none visible (zoom/edit safe) |
| `conv --archive-master <path>` | video FFV1+FLAC · image JXL `-d0` (JPEG `-j1`) | ~40-65% | **none — mathematically lossless, reversible** |

```bash
conv --archive --dry-run ~/Photos      # plan only
conv --archive ~/Photos ~/Videos       # recurse, visually-lossless
conv --archive-master master_clip.mov  # bit-perfect FFV1
```

Non-destructive (source kept), skip-if-bigger guard, 10-bit (no banding on
re-grade), `hvc1` tag (iOS/QuickTime playable).

**Deps:** `ffmpeg` (libx265/libsvtav1/ffv1), `cjxl` (`brew install jpeg-xl`),
ImageMagick. macOS / Apple-silicon tuned (hardware-tier auto-detect).

## Other capabilities

Video (probe/trim/concat/split/HDR→SDR/subtitles), audio (normalize/extract/ID3),
image (HEIC/AVIF/WebP/JXL, resize, EXIF), PDF (merge/OCR/compress), print
production (PDF/X, CMYK, imposition, crop-marks), bulk ops, metadata, reports.
See `conv --help`, `RECIPES.md`, `PATTERNS.md`.

## License

MIT
