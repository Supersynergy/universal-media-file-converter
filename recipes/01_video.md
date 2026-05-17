# Video Recipes

100 real-world video conversion, editing, and processing recipes using `conv`.

## TOC
- [Conversion](#conversion) — 1–18
- [Compress & Quality](#compress--quality) — 19–30
- [Trim / Join / Split](#trim--join--split) — 31–42
- [Extract](#extract) — 43–52
- [Subtitles](#subtitles) — 53–60
- [Thumbnails & Frames](#thumbnails--frames) — 61–68
- [HDR & Color](#hdr--color) — 69–74
- [Rotate / Crop / Speed](#rotate--crop--speed) — 75–82
- [Social Media Presets](#social-media-presets) — 83–90
- [Troubleshooting](#troubleshooting) — 91–95
- [Combo Workflows](#combo-workflows) — 96–100

---

## Conversion

### 1. MP4 to MKV (copy streams, no re-encode)
**Use case:** Container switch without quality loss  
**Command:**
```
conv input.mp4 output.mkv
```
**Notes:** Streams are copied when codecs are compatible

### 2. MKV to MP4 for broad compatibility
**Use case:** Sharing MKV from download with TV/phone  
**Command:**
```
conv film.mkv film.mp4
```

### 3. MOV (ProRes) to H264 MP4
**Use case:** Final Cut export → web upload  
**Command:**
```
conv export_prores.mov web_h264.mp4
```

### 4. AVI to MP4 (old camcorder footage)
**Use case:** Digitized VHS or old camcorder DivX files  
**Command:**
```
conv Urlaub_2003.avi Urlaub_2003.mp4
```

### 5. MP4 to WebM VP9 for web
**Use case:** HTML5 video embed without licensing cost  
**Command:**
```
conv video.mp4 video.webm
```

### 6. MP4 to AV1 WebM (maximum compression)
**Use case:** Streaming platform upload, minimize bandwidth  
**Command:**
```
ffmpeg -i input.mp4 -c:v libaom-av1 -crf 30 -b:v 0 -c:a libopus output.webm
```

### 7. HEVC/H265 MKV to H264 MP4
**Use case:** Old Samsung TV can't play H265  
**Command:**
```
conv hevc_film.mkv h264_film.mp4
```

### 8. MP4 to GIF (short clip)
**Use case:** Reaction GIF or README demo  
**Command:**
```
conv clip.mp4 clip.gif
```

### 9. GIF to MP4 (smaller size)
**Use case:** Replace heavy GIF on website with video  
**Command:**
```
conv animation.gif animation.mp4
```

### 10. FLV to MP4 (old Flash video)
**Use case:** Recover downloaded Flash-era content  
**Command:**
```
conv Vortrag_2009.flv Vortrag_2009.mp4
```

### 11. WMV to MP4 (Windows Media)
**Use case:** Client sent WMV, need MP4 for editing  
**Command:**
```
conv Praesentation.wmv Praesentation.mp4
```

### 12. MTS/M2TS to MP4 (AVCHD camcorder)
**Use case:** Sony/Panasonic camcorder footage  
**Command:**
```
conv 00001.MTS footage.mp4
```

### 13. MP4 to ProRes 422 MOV for editing
**Use case:** Import web video into Final Cut / Premiere  
**Command:**
```
ffmpeg -i input.mp4 -c:v prores_ks -profile:v 2 -c:a pcm_s16le edit_ready.mov
```

### 14. VP9 WebM to H264 MP4
**Use case:** Browser download → offline playback  
**Command:**
```
conv youtube_vp9.webm local_h264.mp4
```

### 15. MP4 to HEVC for Apple devices
**Use case:** Smaller file, same quality on iPhone/iPad  
**Command:**
```
ffmpeg -i input.mp4 -c:v hevc_videotoolbox -q:v 60 -c:a aac output_hevc.mp4
```

### 16. TS stream to MP4
**Use case:** TV recording .ts file → playable MP4  
**Command:**
```
conv aufnahme.ts aufnahme.mp4
```

### 17. OGV to MP4 (old Theora video)
**Use case:** Archive recovery from old Linux recordings  
**Command:**
```
conv screencast.ogv screencast.mp4
```

### 18. DV to MP4 (MiniDV tape capture)
**Use case:** Digitized family tapes  
**Command:**
```
conv Hochzeit_2001.dv Hochzeit_2001.mp4
```

---

## Compress & Quality

### 19. Compress MP4 for email attachment (<25MB)
**Use case:** Send video via email with size limit  
**Command:**
```
ffmpeg -i original.mp4 -c:v h264_videotoolbox -b:v 2M -c:a aac -b:a 128k small.mp4
```

### 20. YouTube upload preset (1080p H264)
**Use case:** Optimized for YouTube processing pipeline  
**Command:**
```
ffmpeg -i input.mp4 -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k -movflags +faststart youtube.mp4
```

### 21. YouTube 4K upload (H265)
**Use case:** 4K channel, minimize upload time  
**Command:**
```
ffmpeg -i 4k_raw.mp4 -c:v libx265 -crf 20 -preset medium -c:a aac -b:a 192k youtube_4k.mp4
```

### 22. Instagram Reels preset (1080x1920, 60s max)
**Use case:** Vertical short-form content  
**Command:**
```
ffmpeg -i clip.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -crf 23 -t 60 reel.mp4
```

### 23. TikTok export (9:16, max 287MB)
**Use case:** TikTok upload spec compliance  
**Command:**
```
ffmpeg -i input.mp4 -vf "scale=1080:1920" -c:v libx264 -b:v 8M -c:a aac -b:a 128k -fs 280M tiktok.mp4
```

### 24. Twitter/X video (max 512MB, 2:20)
**Use case:** Twitter native video upload  
**Command:**
```
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -c:a aac -b:a 128k -t 140 -fs 500M twitter.mp4
```

### 25. Vimeo upload (ProRes or high-bitrate H264)
**Use case:** Vimeo Pro upload for client review  
**Command:**
```
ffmpeg -i master.mp4 -c:v libx264 -preset veryslow -crf 16 -c:a aac -b:a 320k vimeo_master.mp4
```

### 26. Reduce file size 50% with acceptable quality
**Use case:** Quick size cut for sharing  
**Command:**
```
ffmpeg -i large.mp4 -c:v libx264 -crf 28 -preset fast -c:a aac -b:a 128k half_size.mp4
```

### 27. Lossless copy (remux only)
**Use case:** Fix container without touching quality  
**Command:**
```
ffmpeg -i broken.mkv -c copy fixed.mp4
```

### 28. CRF quality ladder for A/B testing
**Use case:** Find optimal CRF for a specific source  
**Command:**
```
for crf in 18 22 26 30; do ffmpeg -i src.mp4 -c:v libx264 -crf $crf test_crf${crf}.mp4; done
```

### 29. Two-pass encoding for exact target bitrate
**Use case:** Broadcast delivery with strict bitrate requirement  
**Command:**
```
ffmpeg -i input.mp4 -c:v libx264 -b:v 4M -pass 1 -f null /dev/null
ffmpeg -i input.mp4 -c:v libx264 -b:v 4M -pass 2 output_4mbps.mp4
```

### 30. Normalize video for streaming (faststart)
**Use case:** Progressive streaming — playback before full download  
**Command:**
```
ffmpeg -i input.mp4 -c copy -movflags +faststart streaming.mp4
```

---

## Trim / Join / Split

### 31. Trim first 30 seconds
**Use case:** Remove intro from screen recording  
**Command:**
```
conv --trim input.mp4 output.mp4 --start 0 --end 30
```

### 32. Trim from timestamp (fast seek)
**Use case:** Cut interview from 5:30 to 12:00  
**Command:**
```
conv --trim interview.mp4 clip.mp4 --start 5:30 --end 12:00
```

### 33. Trim last 2 minutes (remove outro)
**Use case:** Strip sponsor segment at end  
**Command:**
```
ffmpeg -i video.mp4 -t $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 video.mp4| awk '{print $1-120}') -c copy trimmed.mp4
```

### 34. Concat two clips (same codec)
**Use case:** Join two recordings from same session  
**Command:**
```
conv --concat part1.mp4 part2.mp4 combined.mp4
```

### 35. Concat mixed-codec files
**Use case:** Join MP4 + MKV from different cameras  
**Command:**
```
conv --concat cam_a.mp4 cam_b.mkv merged.mp4
```

### 36. Concat multiple clips from list
**Use case:** Join 10 lecture segments in order  
**Command:**
```
ls segment_*.mp4 | sort > list.txt
ffmpeg -f concat -safe 0 -i <(awk '{print "file \47"$0"\47"}' list.txt) -c copy lecture_full.mp4
```

### 37. Split video into 10-minute segments
**Use case:** Upload long video in parts  
**Command:**
```
conv --split video.mp4 --duration 600 segment_%03d.mp4
```

### 38. Split by file size (500MB chunks)
**Use case:** Large film → fit on FAT32 drive  
**Command:**
```
conv --split film.mkv --size 500M chunk_%02d.mkv
```

### 39. Split on scene changes
**Use case:** Auto-split compilation into individual clips  
**Command:**
```
ffmpeg -i compilation.mp4 -vf "select='gt(scene,0.4)',showinfo" -vsync vfr frames/frame_%04d.jpg
```

### 40. Remove section from middle (complex trim)
**Use case:** Cut out 3-minute sponsor segment from podcast video  
**Command:**
```
ffmpeg -i podcast.mp4 -t 00:10:00 -c copy part1.mp4
ffmpeg -i podcast.mp4 -ss 00:13:00 -c copy part2.mp4
conv --concat part1.mp4 part2.mp4 edited.mp4
```

### 41. Trim with re-encode (accurate frame)
**Use case:** Need frame-accurate cut for social clip  
**Command:**
```
ffmpeg -i source.mp4 -ss 00:01:23.500 -to 00:01:45.000 -c:v libx264 -crf 18 -c:a aac clip_exact.mp4
```

### 42. Loop short clip N times
**Use case:** Make 10-second clip into 1-minute loop  
**Command:**
```
ffmpeg -stream_loop 5 -i short.mp4 -c copy looped.mp4
```

---

## Extract

### 43. Extract audio as MP3
**Use case:** Rip audio from video for podcast/music  
**Command:**
```
conv --extract-audio video.mp4 audio.mp3
```

### 44. Extract audio as FLAC (lossless)
**Use case:** Preserve audio quality from Blu-ray rip  
**Command:**
```
conv --extract-audio bluray.mkv soundtrack.flac
```

### 45. Extract audio as Opus (small + quality)
**Use case:** Podcast playback, mobile-optimized  
**Command:**
```
conv --extract-audio lecture.mp4 lecture.opus
```

### 46. Extract specific audio track (multi-track MKV)
**Use case:** MKV with English + German audio — keep only German  
**Command:**
```
ffmpeg -i film.mkv -map 0:a:1 -c:a aac german_audio.aac
```

### 47. Extract video without audio
**Use case:** Mute original, will add custom audio  
**Command:**
```
ffmpeg -i input.mp4 -an -c:v copy no_audio.mp4
```

### 48. Extract single frame as JPEG
**Use case:** Pull cover image from video  
**Command:**
```
conv --frame video.mp4 cover.jpg --time 00:00:05
```

### 49. Extract frames every N seconds
**Use case:** Build storyboard / preview strip  
**Command:**
```
ffmpeg -i film.mp4 -vf fps=1/10 frames/frame_%04d.jpg
```

### 50. Extract all keyframes
**Use case:** Scene detection source images  
**Command:**
```
ffmpeg -i video.mp4 -vf "select=eq(pict_type\,I)" -vsync vfr keyframe_%04d.jpg
```

### 51. Extract thumbnail at 10% into video
**Use case:** Auto-generate YouTube thumbnail candidate  
**Command:**
```
conv --thumbnail video.mp4 thumb.jpg
```

### 52. Extract embedded subtitles
**Use case:** Get SRT from MKV for translation  
**Command:**
```
conv --subtitle-extract film.mkv subtitles.srt
```

---

## Subtitles

### 53. Extract all subtitle tracks
**Use case:** MKV with 5 language subs — export all  
**Command:**
```
conv --subtitle-extract film.mkv --all-tracks subs/
```

### 54. Burn subtitles into video
**Use case:** Permanent captions for social media (no player needed)  
**Command:**
```
conv --subtitle-burn input.mp4 subtitles.srt output_burned.mp4
```

### 55. Burn ASS/SSA styled subtitles
**Use case:** Anime fansub with styled dialogue  
**Command:**
```
ffmpeg -i anime.mkv -vf "ass=subtitles.ass" -c:v libx264 -crf 20 anime_sub.mp4
```

### 56. Add external SRT to MP4 (soft sub)
**Use case:** Distribute video + subtitle as one file  
**Command:**
```
ffmpeg -i video.mp4 -i subtitles.srt -c copy -c:s mov_text with_subs.mp4
```

### 57. Shift subtitle timing (+2.5 seconds)
**Use case:** Subtitle out of sync with downloaded video  
**Command:**
```
ffmpeg -itsoffset 2.5 -i subtitles.srt -c copy shifted.srt
```

### 58. Convert SRT to VTT (web)
**Use case:** HTML5 video player requires WebVTT  
**Command:**
```
ffmpeg -i subtitles.srt subtitles.vtt
```

### 59. Auto-generate subtitles with Whisper
**Use case:** No subtitle file — transcribe automatically  
**Command:**
```
conv --extract-audio lecture.mp4 lecture.wav
whisper lecture.wav --language de --output_format srt
```

### 60. Merge hardcoded subtitle video back to soft subs
**Use case:** Source already has burned subs — add new language on top  
**Command:**
```
ffmpeg -i burned.mp4 -i new_lang.srt -c:v copy -c:a copy -c:s mov_text dual_sub.mp4
```

---

## Thumbnails & Frames

### 61. Generate thumbnail grid (contact sheet)
**Use case:** Quick visual overview of long video  
**Command:**
```
conv --thumbnail-grid video.mp4 grid.jpg --cols 4 --rows 6
```

### 62. Thumbnail at specific timestamp
**Use case:** Pick best frame for YouTube cover  
**Command:**
```
conv --frame Vortrag.mp4 thumbnail.jpg --time 00:02:15
```

### 63. Extract 1 frame per minute
**Use case:** Long-form content preview strip  
**Command:**
```
ffmpeg -i documentary.mp4 -vf fps=1/60 previews/preview_%04d.jpg
```

### 64. High-res frame extract (PNG, no compression)
**Use case:** Extract for print or detailed inspection  
**Command:**
```
ffmpeg -i cinema.mp4 -ss 00:45:20 -vframes 1 frame_hires.png
```

### 65. Animated GIF from 5-second clip
**Use case:** Loop preview for product page  
**Command:**
```
conv --trim product_demo.mp4 clip.mp4 --start 10 --end 15
conv clip.mp4 preview.gif
```

### 66. WebP animated from short clip
**Use case:** Smaller than GIF, supported in modern browsers  
**Command:**
```
ffmpeg -i clip.mp4 -vf "fps=15,scale=480:-1" -loop 0 animation.webp
```

### 67. Extract frame at exact byte offset
**Use case:** Debug video encoding artifact  
**Command:**
```
ffmpeg -i video.mp4 -ss 00:12:34.567 -vframes 1 debug_frame.png
```

### 68. Batch thumbnails for video library
**Use case:** Generate covers for media server  
**Command:**
```
for f in *.mp4; do conv --thumbnail "$f" "thumbs/${f%.mp4}.jpg"; done
```

---

## HDR & Color

### 69. Convert HDR10 to SDR for web
**Use case:** Phone HDR footage → web-compatible  
**Command:**
```
conv --hdr-sdr hdr_clip.mp4 sdr_web.mp4
```

### 70. HDR to SDR with tonemapping (preserve look)
**Use case:** Better color preservation than naive conversion  
**Command:**
```
ffmpeg -i hdr.mp4 -vf "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p" -c:v libx264 -crf 18 sdr.mp4
```

### 71. Dolby Vision to HDR10
**Use case:** DV MKV → wider compatible HDR  
**Command:**
```
ffmpeg -i dolby_vision.mkv -c:v hevc_videotoolbox -tag:v hvc1 -color_primaries bt2020 hdr10.mp4
```

### 72. Adjust brightness/contrast
**Use case:** Dark footage from phone  
**Command:**
```
ffmpeg -i dark.mp4 -vf "eq=brightness=0.06:contrast=1.2" bright.mp4
```

### 73. Convert to grayscale
**Use case:** Artistic choice or old-style look  
**Command:**
```
ffmpeg -i color.mp4 -vf "hue=s=0" grayscale.mp4
```

### 74. Fix white balance (orange tint)
**Use case:** Indoor footage under tungsten lighting  
**Command:**
```
ffmpeg -i warm.mp4 -vf "colorchannelmixer=rr=0.9:gg=1.0:bb=1.1" fixed_wb.mp4
```

---

## Rotate / Crop / Speed

### 75. Rotate 90° clockwise (portrait phone video)
**Use case:** Sideways video from phone  
**Command:**
```
ffmpeg -i sideways.mp4 -vf "transpose=1" -c:v libx264 upright.mp4
```

### 76. Flip horizontally (mirror)
**Use case:** Webcam selfie mirror correction  
**Command:**
```
ffmpeg -i mirrored.mp4 -vf hflip -c:v libx264 correct.mp4
```

### 77. Crop to 16:9 from 4:3 source
**Use case:** Old footage for modern widescreen  
**Command:**
```
ffmpeg -i 4x3.mp4 -vf "crop=iw:iw*9/16:(iw-ow)/2:(ih-oh)/2" widescreen.mp4
```

### 78. Crop to square for Instagram feed
**Use case:** Widescreen video → 1:1 crop  
**Command:**
```
ffmpeg -i wide.mp4 -vf "crop=ih:ih" square.mp4
```

### 79. Scale to 1080p keeping aspect
**Use case:** Downscale 4K for faster upload  
**Command:**
```
ffmpeg -i 4k.mp4 -vf "scale=1920:-2" -c:v libx264 -crf 20 1080p.mp4
```

### 80. Speed up 2x (timelapse effect)
**Use case:** Long screen recording → fast overview  
**Command:**
```
ffmpeg -i screenrecording.mp4 -vf "setpts=0.5*PTS" -af "atempo=2.0" fast.mp4
```

### 81. Slow motion 0.5x
**Use case:** Emphasize action moment  
**Command:**
```
ffmpeg -i action.mp4 -vf "setpts=2.0*PTS" -af "atempo=0.5" slowmo.mp4
```

### 82. Convert 60fps to 24fps (cinematic)
**Use case:** Sports footage → film look  
**Command:**
```
ffmpeg -i 60fps.mp4 -vf "fps=24" -c:v libx264 -crf 20 cinematic.mp4
```

---

## Social Media Presets

### 83. LinkedIn video (max 5GB, 10min, 4096x2304)
**Use case:** LinkedIn native video post  
**Command:**
```
ffmpeg -i input.mp4 -c:v libx264 -crf 20 -c:a aac -b:a 192k -movflags +faststart linkedin.mp4
```

### 84. Facebook video (16:9, H264)
**Use case:** Facebook page native video  
**Command:**
```
ffmpeg -i input.mp4 -c:v libx264 -b:v 4M -vf "scale=1280:720" -c:a aac -b:a 128k fb.mp4
```

### 85. Instagram square post (1080x1080)
**Use case:** Feed video, square format  
**Command:**
```
ffmpeg -i clip.mp4 -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2:black" -c:v libx264 -crf 23 ig_square.mp4
```

### 86. Instagram Story / TikTok (1080x1920)
**Use case:** Vertical format for stories  
**Command:**
```
ffmpeg -i landscape.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" -c:v libx264 story.mp4
```

### 87. YouTube Shorts (<60s, 9:16)
**Use case:** Shorts algorithm format  
**Command:**
```
conv --trim clip.mp4 short_clip.mp4 --start 0 --end 59
ffmpeg -i short_clip.mp4 -vf "scale=1080:1920" -c:v libx264 -crf 22 short.mp4
```

### 88. Discord GIF (<8MB)
**Use case:** React GIF for server  
**Command:**
```
ffmpeg -i clip.mp4 -vf "fps=10,scale=320:-1:flags=lanczos" -loop 0 discord.gif
```

### 89. Podcast video (static image + audio)
**Use case:** Audiogram for YouTube/Spotify  
**Command:**
```
ffmpeg -loop 1 -i cover.jpg -i podcast.mp3 -c:v libx264 -c:a aac -shortest -movflags +faststart podcast_video.mp4
```

### 90. Twitch highlight clip (MP4 < 500MB)
**Use case:** Export clip for Twitch highlights  
**Command:**
```
conv --trim stream.mp4 highlight.mp4 --start 01:23:45 --end 01:28:00
ffmpeg -i highlight.mp4 -c:v libx264 -crf 22 -fs 490M twitch_clip.mp4
```

---

## Troubleshooting

### 91. Fix audio-video sync (delay audio by 200ms)
**Use case:** Desync from recording software bug  
**Command:**
```
ffmpeg -i desynced.mp4 -itsoffset 0.2 -i desynced.mp4 -map 1:v -map 0:a -c copy synced.mp4
```

### 92. Probe video metadata before converting
**Use case:** Understand source before choosing settings  
**Command:**
```
conv --probe input.mkv
```

### 93. Fix broken MP4 (moov atom at end)
**Use case:** Incomplete download, can't play  
**Command:**
```
ffmpeg -i broken.mp4 -c copy fixed.mp4 -movflags +faststart
```

### 94. Re-encode corrupt frames
**Use case:** Video has glitches from bad sectors  
**Command:**
```
ffmpeg -i corrupt.mp4 -c:v libx264 -crf 20 -c:a copy recovered.mp4
```

### 95. Convert variable frame rate to constant (VFR→CFR)
**Use case:** OBS recording VFR causes editing issues  
**Command:**
```
ffmpeg -i obs_vfr.mp4 -vf fps=30 -c:v libx264 -crf 20 cfr_30fps.mp4
```

---

## Combo Workflows

### 96. Download → Trim → Add Subs → Upload-ready
**Use case:** Edit downloaded lecture for sharing  
**Command:**
```
conv --trim raw_lecture.mp4 trimmed.mp4 --start 2:00 --end 45:00
conv --subtitle-burn trimmed.mp4 lecture.srt subtitled.mp4
ffmpeg -i subtitled.mp4 -movflags +faststart final.mp4
```

### 97. Screen recording → Compress → Thumbnail → Publish
**Use case:** Tutorial recording pipeline  
**Command:**
```
conv --trim screenrecord.mp4 clean.mp4 --start 0:05 --end 12:30
ffmpeg -i clean.mp4 -c:v libx264 -crf 24 -movflags +faststart tutorial.mp4
conv --thumbnail tutorial.mp4 thumbnail.jpg --time 00:00:10
```

### 98. HDR Phone Footage → SDR → Instagram Reel
**Use case:** iPhone HDR video for Instagram  
**Command:**
```
conv --hdr-sdr Urlaubsvideo.mp4 sdr.mp4
ffmpeg -i sdr.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -crf 22 -t 90 reel.mp4
```

### 99. Extract Podcast Audio → Normalize → ID3 Tag
**Use case:** Video podcast → audio RSS feed  
**Command:**
```
conv --extract-audio podcast_video.mp4 podcast_raw.mp3
conv --normalize podcast_raw.mp3 podcast_norm.mp3
conv --id3 podcast_norm.mp3 --title "Episode 42" --artist "Supersynergy" --year 2026
```

### 100. Multi-camera Sync → Concat → Compress → Deliver
**Use case:** Wedding multi-cam edit final delivery  
**Command:**
```
conv --trim cam_a.mp4 cam_a_trim.mp4 --start 0:30 --end 1:45:00
conv --trim cam_b.mp4 cam_b_trim.mp4 --start 0:00 --end 1:44:30
conv --concat cam_a_trim.mp4 cam_b_trim.mp4 combined.mp4
ffmpeg -i combined.mp4 -c:v libx264 -crf 20 -c:a aac -b:a 192k -movflags +faststart Hochzeit_2026_final.mp4
```

---

## Best-Practices (verified 2026-04-20)

### GOLDEN RULE — Stream-Copy First

**Before any re-encode: check source codec.** If source is AV1/HEVC/H.264 already and target container supports it → **stream-copy**. Saves 100-300× time and is lossless.

```bash
# Check source
ffprobe -v error -show_entries stream=codec_name -of csv=p=0 src.webm
# av1,opus

# AV1+Opus webm → AV1+AAC mp4 (stream-copy video, cheap audio re-encode)
ffmpeg -ss $KF -i src.webm -c:v copy -c:a aac -b:a 128k -movflags +faststart out.mp4
```

### 101. Loop-trim pre-stream replay (waiting-room countdown)

**Use case:** Downloaded Zoom/Vimeo/YouTube replay has 10-15min looping countdown before real content starts.

**Command:**
```bash
# 1. Detect scene-change timestamps
ffmpeg -i src.webm -vf "select='gt(scene,0.3)',metadata=print" -an -f null - 2>&1 \
  | grep -oE "pts_time:[0-9.]+" | awk -F: '{print $2}' > scenes.txt

# 2. Identify loop period (look for constant diff between scene clusters)
#    e.g. 37.3, 47.3, 57.3, ..., 282.7, 292.7, ... → period = 245.4s
awk 'NR>1{print $1-prev} {prev=$1}' scenes.txt | sort | uniq -c | sort -rn | head

# 3. Find last repeating loop-scene, then pick next keyframe
LAST_LOOP=832.767
ffprobe -v error -select_streams v -read_intervals ${LAST_LOOP}%+10 \
  -show_entries packet=pts_time,flags src.webm -of csv=p=0 | grep ",K"

# 4. Stream-copy from next keyframe
ffmpeg -ss 835 -i src.webm -c:v copy -c:a aac -b:a 128k -movflags +faststart cut.mp4
```

**Result:** 65min source 285MB → 51min output 178MB, 3 seconds, lossless.

### 102. Codec bake-off for unknown source (quality + size sweet-spot)

**Use case:** Source codec unknown or inefficient — want smallest file at best quality.

**Command:**
```bash
# Extract 10s test clip from middle (stream-copy, fast)
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 src.mp4)
MID=$(echo "$DUR / 2" | bc)
ffmpeg -ss $MID -t 10 -i src.mp4 -c copy /tmp/clip.mkv -y

# Bake-off (M4 Max verified, AV1 1080p 30fps source):
# svtav1  crf35 preset 8  → best compression/SSIM, 0.38× realtime
# x265    crf26 preset fast -tag:v hvc1  → widest modern-compat HEVC
# x264    crf23 preset fast  → universal H.264
# hevc_videotoolbox -b:v 1200k -tag:v hvc1  → fastest HW HEVC

for cfg in "svtav1_p8:libsvtav1 -crf 35 -preset 8" \
           "x265_fast:libx265 -crf 26 -preset fast -tag:v hvc1" \
           "x264_fast:libx264 -crf 23 -preset fast" \
           "hevc_vt:hevc_videotoolbox -b:v 1200k -tag:v hvc1"; do
  name="${cfg%%:*}"; args="${cfg#*:}"
  ffmpeg -i /tmp/clip.mkv -c:v $args -c:a aac -b:a 128k "/tmp/out_$name.mp4" -y 2>/dev/null
  ssim=$(ffmpeg -i /tmp/clip.mkv -i "/tmp/out_$name.mp4" -lavfi ssim -f null - 2>&1 | grep -oE "All:[0-9.]+" | head -1)
  size=$(stat -f%z "/tmp/out_$name.mp4")
  printf "%-12s %s %s\n" "$name" "$ssim" "$size"
done
```

### 103. Default target presets (opinionated)

| Goal | Codec | Settings | Container |
|------|-------|----------|-----------|
| **Stream-copy if source is** | AV1/HEVC/H.264 | `-c:v copy -c:a aac -b:a 128k` | `.mp4 -movflags +faststart` |
| **Smallest file, modern** | SVT-AV1 | `-crf 35 -preset 8` | `.mp4` (AV1 in mp4) |
| **Universal compat** | libx264 | `-crf 23 -preset fast -profile:v high` | `.mp4` |
| **Apple-first, small** | libx265 | `-crf 26 -preset fast -tag:v hvc1` | `.mp4` |
| **Fast HW (batch)** | hevc_videotoolbox | `-b:v 1200k -tag:v hvc1` | `.mp4` |
| **AVOID** | h264_videotoolbox | `-b:v 3500k` | (bloated, 4× larger than x264 crf23) |

### 104. Audio-only re-encode (container swap + codec change)

**Use case:** Source has Opus audio, target needs AAC for wider compat (older QuickTime, some Android), video stream stays.

**Command:**
```bash
ffmpeg -i src.webm -c:v copy -c:a aac -b:a 128k -movflags +faststart out.mp4
```

Audio re-encode ≈ 1min per hour of video — negligible vs. video transcode.
