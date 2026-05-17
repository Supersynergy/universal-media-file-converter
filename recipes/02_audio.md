# Audio Recipes

100 real-world audio conversion, processing, and tagging recipes using `conv`.

## TOC
- [Format Conversion](#format-conversion) — 1–15
- [Bitrate & Quality Presets](#bitrate--quality-presets) — 16–25
- [Loudness & Normalization](#loudness--normalization) — 26–35
- [Editing & Processing](#editing--processing) — 36–50
- [Channel & Sample Rate](#channel--sample-rate) — 51–58
- [ID3 Tagging](#id3-tagging) — 59–72
- [Splitting & Chapters](#splitting--chapters) — 73–80
- [Podcast Production](#podcast-production) — 81–88
- [Transcription Prep](#transcription-prep) — 89–93
- [Troubleshooting](#troubleshooting) — 94–96
- [Combo Workflows](#combo-workflows) — 97–100

---

## Format Conversion

### 1. FLAC to MP3
**Use case:** Audiophile archive → portable player  
**Command:**
```
conv Album_FLAC/track01.flac track01.mp3
```

### 2. WAV to MP3 (podcast master → distribution)
**Use case:** Studio WAV → upload to Spotify/Apple  
**Command:**
```
conv podcast_master.wav podcast_dist.mp3
```

### 3. MP3 to FLAC (re-wrap, not upscale)
**Use case:** Normalize library to FLAC containers  
**Command:**
```
conv lossy.mp3 archive.flac
```
**Notes:** Quality is still MP3-level — FLAC container doesn't recover lost data

### 4. AAC M4A to MP3
**Use case:** iTunes purchase → Android player compatibility  
**Command:**
```
conv iTunes_Kauf.m4a iTunes_Kauf.mp3
```

### 5. OGG Vorbis to MP3
**Use case:** Old Linux rip → universal format  
**Command:**
```
conv track.ogg track.mp3
```

### 6. MP3 to Opus (smaller, same quality)
**Use case:** Mobile podcast app, save storage  
**Command:**
```
conv episode.mp3 episode.opus
```

### 7. WAV to AAC M4A
**Use case:** Apple ecosystem distribution  
**Command:**
```
conv recording.wav recording.m4a
```

### 8. FLAC to Opus at 128k (streaming)
**Use case:** Hi-res archive → streaming service upload  
**Command:**
```
ffmpeg -i master.flac -c:a libopus -b:a 128k stream.opus
```

### 9. MP3 to WAV (for DAW import)
**Use case:** Sample pack → Ableton/Logic import  
**Command:**
```
conv sample.mp3 sample.wav
```

### 10. WMA to MP3 (Windows Media)
**Use case:** Old Windows Media Player rip → modern player  
**Command:**
```
conv Lieblingslied.wma Lieblingslied.mp3
```

### 11. AIFF to WAV
**Use case:** Logic Pro export → cross-platform  
**Command:**
```
conv master.aiff master.wav
```

### 12. MP4 audio strip to M4A
**Use case:** Video file audio track only, keep AAC quality  
**Command:**
```
ffmpeg -i video.mp4 -vn -c:a copy audio.m4a
```

### 13. Batch OGG to MP3 directory
**Use case:** Old music library conversion  
**Command:**
```
convall ogg mp3 ~/Musik/OGG_Rips/
```

### 14. APE (Monkey's Audio) to FLAC
**Use case:** Rare lossless format → standard  
**Command:**
```
ffmpeg -i album.ape album.flac
```

### 15. DSF/DSD to FLAC
**Use case:** SACD rip → playable format  
**Command:**
```
ffmpeg -i recording.dsf -c:a flac -ar 88200 recording_dsd.flac
```

---

## Bitrate & Quality Presets

### 16. MP3 at 320kbps (max quality)
**Use case:** Music archiving with MP3 constraint  
**Command:**
```
ffmpeg -i master.wav -c:a libmp3lame -b:a 320k -q:a 0 high_quality.mp3
```

### 17. Podcast MP3 at 128kbps mono
**Use case:** Voice-only podcast standard  
**Command:**
```
ffmpeg -i stereo_recording.wav -c:a libmp3lame -b:a 128k -ac 1 podcast.mp3
```

### 18. Voice recording at 64kbps Opus
**Use case:** Maximum compression for speech (WhatsApp-quality replacement)  
**Command:**
```
ffmpeg -i voice.wav -c:a libopus -b:a 64k voice_compressed.opus
```

### 19. Hi-res 24-bit WAV to 16-bit for CD
**Use case:** Studio master → CD distribution  
**Command:**
```
ffmpeg -i 24bit_master.wav -c:a pcm_s16le -ar 44100 cd_ready.wav
```

### 20. AAC at 256kbps for Apple Music delivery
**Use case:** Apple Music vendor upload spec  
**Command:**
```
ffmpeg -i master.wav -c:a aac -b:a 256k -ar 44100 apple_music.m4a
```

### 21. Opus at 96kbps for audiobook
**Use case:** Good quality, small file, long duration  
**Command:**
```
ffmpeg -i audiobook_raw.wav -c:a libopus -b:a 96k audiobook.opus
```

### 22. Variable bitrate MP3 (VBR V0)
**Use case:** Best perceptual quality per byte  
**Command:**
```
ffmpeg -i lossless.flac -c:a libmp3lame -q:a 0 vbr_v0.mp3
```

### 23. FLAC at 96kHz/24bit for hi-res stores
**Use case:** Bandcamp / Qobuz hi-res upload  
**Command:**
```
ffmpeg -i studio_master.wav -c:a flac -ar 96000 -sample_fmt s32 hires.flac
```

### 24. Podcast at 96kbps stereo AAC
**Use case:** Music podcast with stereo content  
**Command:**
```
ffmpeg -i episode.wav -c:a aac -b:a 96k -ar 44100 podcast_stereo.m4a
```

### 25. Voice memo at 32kbps Opus (minimal size)
**Use case:** Meeting notes, max compression for voice  
**Command:**
```
ffmpeg -i meeting.wav -c:a libopus -b:a 32k meeting_tiny.opus
```

---

## Loudness & Normalization

### 26. Normalize to EBU R128 (-23 LUFS broadcast)
**Use case:** Broadcast delivery loudness standard  
**Command:**
```
conv --normalize episode.mp3 episode_r128.mp3 --target -23
```

### 27. Normalize to -16 LUFS (podcast/streaming)
**Use case:** Spotify/Apple Podcasts loudness target  
**Command:**
```
conv --normalize podcast.wav podcast_norm.wav --target -16
```

### 28. Normalize to -14 LUFS (Spotify/YouTube)
**Use case:** Music streaming platform normalization  
**Command:**
```
conv --normalize track.flac track_norm.flac --target -14
```

### 29. Two-pass loudness with ffmpeg-normalize
**Use case:** Accurate integrated loudness pass  
**Command:**
```
ffmpeg -i input.wav -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json -f null /dev/null 2>&1 | tail -n 12
ffmpeg -i input.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=-18:measured_LRA=8:measured_TP=-2:linear=true" normalized.wav
```

### 30. Peak normalization to -1dBFS
**Use case:** Quick normalize before mixing  
**Command:**
```
ffmpeg -i quiet.wav -af "volume=1dB" peaked.wav
```

### 31. Dynamic compression (reduce dynamic range)
**Use case:** Podcast sounds too quiet in loud sections  
**Command:**
```
ffmpeg -i podcast.wav -af "compand=0.3|0.3:1|1:-90/-60|-60/-40|-40/-30|-20/-20:6:0:-90:0.2" compressed.wav
```

### 32. Batch normalize album tracks
**Use case:** Consistent loudness across album  
**Command:**
```
convall wav wav ~/Album/ --normalize-lufs -14
```

### 33. ReplayGain tagging (without re-encode)
**Use case:** Player-side normalization for music library  
**Command:**
```
mp3gain -r -k *.mp3
```

### 34. Normalize voice recording (AGC effect)
**Use case:** Interview with varying mic distance  
**Command:**
```
ffmpeg -i interview.wav -af "speechnorm=e=12.5:r=0.0001:l=1" speech_norm.wav
```

### 35. Limit peaks without clipping
**Use case:** Prevent distortion on loud transients  
**Command:**
```
ffmpeg -i master.wav -af "alimiter=limit=0.9:attack=5:release=50:level=disabled" limited.wav
```

---

## Editing & Processing

### 36. Fade in first 3 seconds
**Use case:** Smooth podcast intro  
**Command:**
```
ffmpeg -i track.mp3 -af "afade=t=in:st=0:d=3" fade_in.mp3
```

### 37. Fade out last 5 seconds
**Use case:** Song ending fade  
**Command:**
```
duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 track.mp3)
ffmpeg -i track.mp3 -af "afade=t=out:st=$(echo "$duration - 5" | bc):d=5" fade_out.mp3
```

### 38. Fade in + fade out
**Use case:** Polished podcast segment  
**Command:**
```
ffmpeg -i segment.wav -af "afade=t=in:st=0:d=2,afade=t=out:st=28:d=2" segment_faded.wav
```

### 39. Remove silence at start/end
**Use case:** Clean up voice recording edges  
**Command:**
```
ffmpeg -i recording.wav -af "silenceremove=start_periods=1:start_silence=0.5:start_threshold=-50dB:stop_periods=1:stop_silence=0.5:stop_threshold=-50dB" trimmed.wav
```

### 40. Speed up 1.25x (no pitch change)
**Use case:** Audiobook at faster pace  
**Command:**
```
ffmpeg -i audiobook.m4a -af "atempo=1.25" fast.m4a
```

### 41. Speed up 2x
**Use case:** Meeting recording review  
**Command:**
```
ffmpeg -i meeting.mp3 -af "atempo=2.0" review_2x.mp3
```

### 42. Pitch shift up by semitone (no speed change)
**Use case:** Key correction for singer  
**Command:**
```
ffmpeg -i vocal.wav -af "asetrate=44100*1.059,aresample=44100" pitched_up.wav
```

### 43. Noise reduction (basic high-pass filter)
**Use case:** Remove low-frequency rumble from recording  
**Command:**
```
ffmpeg -i noisy.wav -af "highpass=f=80" clean.wav
```

### 44. Remove hiss (low-pass filter)
**Use case:** Old tape digitization, reduce hiss  
**Command:**
```
ffmpeg -i tape.wav -af "lowpass=f=8000" dehissed.wav
```

### 45. De-click (equalizer notch for 50Hz hum)
**Use case:** European electrical hum removal  
**Command:**
```
ffmpeg -i hum.wav -af "equalizer=f=50:width_type=q:width=1:g=-20,equalizer=f=100:width_type=q:width=1:g=-15" dehum.wav
```

### 46. Trim first 30 seconds
**Use case:** Remove podcast intro jingle  
**Command:**
```
ffmpeg -i podcast.mp3 -ss 30 -c copy episode_no_intro.mp3
```

### 47. Mix two audio files (overlay)
**Use case:** Add background music to narration  
**Command:**
```
ffmpeg -i narration.wav -i bgmusic.mp3 -filter_complex "amix=inputs=2:duration=first:dropout_transition=3:weights=1 0.2" mixed.wav
```

### 48. Crossfade two tracks
**Use case:** DJ-style mix transition  
**Command:**
```
ffmpeg -i track1.mp3 -i track2.mp3 -filter_complex "acrossfade=d=5" crossfade.mp3
```

### 49. Extract left or right channel
**Use case:** Dual-track interview (L=interviewer, R=guest) split  
**Command:**
```
ffmpeg -i dual.wav -map_channel 0.0.0 left.wav
ffmpeg -i dual.wav -map_channel 0.0.1 right.wav
```

### 50. Generate waveform image
**Use case:** Podcast show notes, audiogram preview  
**Command:**
```
conv --waveform episode.mp3 waveform.png
```

---

## Channel & Sample Rate

### 51. Stereo to mono
**Use case:** Voice recording, halve file size  
**Command:**
```
ffmpeg -i stereo.mp3 -ac 1 mono.mp3
```

### 52. Mono to stereo (duplicate channel)
**Use case:** Some players require stereo track  
**Command:**
```
ffmpeg -i mono.wav -ac 2 stereo.wav
```

### 53. Resample to 44.1kHz (CD standard)
**Use case:** 48kHz recording → CD mastering  
**Command:**
```
ffmpeg -i 48khz.wav -ar 44100 44khz.wav
```

### 54. Resample to 48kHz (video standard)
**Use case:** Audio for video — must match 48kHz  
**Command:**
```
ffmpeg -i 44khz.wav -ar 48000 48khz.wav
```

### 55. Downsample hi-res to CD quality
**Use case:** 192kHz/32bit archive → consumer output  
**Command:**
```
ffmpeg -i 192khz_32bit.wav -ar 44100 -sample_fmt s16 cd_quality.wav
```

### 56. Upmix stereo to 5.1 (basic)
**Use case:** Stereo master → home theater distribution  
**Command:**
```
ffmpeg -i stereo.wav -af "surround" 5point1.wav
```

### 57. Mix 5.1 surround to stereo
**Use case:** Blu-ray audio track → headphone listening  
**Command:**
```
ffmpeg -i surround.ac3 -ac 2 stereo_mix.mp3
```

### 58. Convert DTS to AAC stereo
**Use case:** MKV with DTS → MP4 compatibility  
**Command:**
```
ffmpeg -i film.mkv -vn -c:a aac -b:a 192k -ac 2 audio_aac.m4a
```

---

## ID3 Tagging

### 59. Set basic ID3 tags
**Use case:** Tag untagged MP3 from download  
**Command:**
```
conv --id3 track.mp3 --artist "Supersynergy" --title "Episode 42" --album "Podcast 2026" --year 2026
```

### 60. Set track number and genre
**Use case:** Complete album tagging  
**Command:**
```
conv --id3 track01.mp3 --track 1 --artist "Artist Name" --album "Album Title"
```

### 61. Embed album cover art
**Use case:** Add artwork to MP3 for phone display  
**Command:**
```
conv --id3 track.mp3 --cover cover.jpg
```

### 62. Remove all ID3 tags
**Use case:** Strip metadata before redistribution  
**Command:**
```
ffmpeg -i tagged.mp3 -map_metadata -1 -c:a copy stripped.mp3
```

### 63. Copy tags from one file to another
**Use case:** Re-encoded file lost its tags  
**Command:**
```
conv --meta-copy source.mp3 destination.mp3
```

### 64. Batch tag album from directory
**Use case:** Tag 12 tracks with same artist/album  
**Command:**
```
for f in *.mp3; do conv --id3 "$f" --artist "Band Name" --album "Album 2026" --year 2026; done
```

### 65. Set BPM tag for DJ software
**Use case:** Export from DAW with BPM metadata  
**Command:**
```
ffmpeg -i track.mp3 -metadata BPM=128 -c:a copy tagged_bpm.mp3
```

### 66. Read all tags
**Use case:** Inspect metadata before editing  
**Command:**
```
conv --meta-read track.mp3
```

### 67. Write custom metadata field
**Use case:** Add label/catalog number to release  
**Command:**
```
conv --meta-write track.mp3 LABEL="Supersynergy Records" CATALOG="SSR-001"
```

### 68. Extract cover art from MP3
**Use case:** Recover album art as image file  
**Command:**
```
ffmpeg -i track.mp3 -an -c:v copy cover_extracted.jpg
```

### 69. Add lyrics to MP3
**Use case:** Embed synchronized or unsynchronized lyrics  
**Command:**
```
ffmpeg -i track.mp3 -metadata lyrics="$(cat lyrics.txt)" -c:a copy track_with_lyrics.mp3
```

### 70. Batch set year tag on album
**Use case:** Fix wrong year on ripped album  
**Command:**
```
for f in *.flac; do ffmpeg -i "$f" -metadata date=2026 -c:a copy "fixed/${f}"; done
```

### 71. Convert ID3v1 tags to ID3v2.3
**Use case:** Old MP3 with ID3v1 — modern players show garbage  
**Command:**
```
mid3iconv -e latin-1 *.mp3
```

### 72. Strip comment/lyrics tags (privacy)
**Use case:** Remove recording location/comments before sharing  
**Command:**
```
ffmpeg -i personal.mp3 -metadata comment="" -metadata lyrics="" -c:a copy clean.mp3
```

---

## Splitting & Chapters

### 73. Split on silence (podcast into segments)
**Use case:** Interview recording → individual questions  
**Command:**
```
conv --split-silence interview.wav --min-silence 1.5 --threshold -40dB
```

### 74. Split audiobook by chapter (CUE sheet)
**Use case:** Single-file audiobook with CUE metadata  
**Command:**
```
ffmpeg -i audiobook.flac -f cue audiobook.cue
mp3splt -c audiobook.cue audiobook.flac
```

### 75. Split MP3 at timestamps from list
**Use case:** DJ set → individual tracks  
**Command:**
```
mp3splt djset.mp3 -s 0.0 5.30 11.22 18.45 25.00 eof
```

### 76. Extract chapter from M4B audiobook
**Use case:** Apple audiobook format chapter extraction  
**Command:**
```
ffmpeg -i audiobook.m4b -ss 01:20:00 -to 01:55:00 -c copy chapter_5.m4a
```

### 77. Split stereo file into two mono files
**Use case:** Dual-track interview → separate speaker files  
**Command:**
```
ffmpeg -i interview.wav -map_channel 0.0.0 sprecher1.wav -map_channel 0.0.1 sprecher2.wav
```

### 78. Merge multiple MP3 chapters into M4B
**Use case:** Individual chapters → audiobook  
**Command:**
```
ffmpeg -i chapter1.mp3 -i chapter2.mp3 -i chapter3.mp3 -filter_complex concat=n=3:v=0:a=1 -c:a aac audiobook.m4b
```

### 79. Split long recording by file size (100MB)
**Use case:** Upload limit on submission portal  
**Command:**
```
conv --split-file lecture.mp3 --size 100M lecture_part_%02d.mp3
```

### 80. Auto-split podcast on applause/music break
**Use case:** Comedy recording with musical breaks as chapter markers  
**Command:**
```
conv --split-silence comedy.wav --min-silence 3.0 --threshold -35dB
```

---

## Podcast Production

### 81. Record → Normalize → Compress → MP3
**Use case:** Standard solo podcast production  
**Command:**
```
conv --normalize raw_recording.wav normalized.wav --target -16
ffmpeg -i normalized.wav -af "compand=0.3|0.3:1|1:-90/-60|-60/-40|-40/-30|-20/-20:6:0:-90:0.2" compressed.wav
conv compressed.wav episode.mp3
```

### 82. Add intro/outro music
**Use case:** Brand podcast with consistent music  
**Command:**
```
ffmpeg -i intro.mp3 -i episode_content.wav -i outro.mp3 -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1" full_episode.mp3
```

### 83. Reduce noise floor (interview in noisy room)
**Use case:** Interview with HVAC/street noise  
**Command:**
```
ffmpeg -i noisy_interview.wav -af "highpass=f=100,lowpass=f=12000,volume=2" cleaned.wav
```

### 84. Mix host + guest tracks (Zoom recording cleanup)
**Use case:** Two separate WAV files from call recording  
**Command:**
```
ffmpeg -i host.wav -i guest.wav -filter_complex "amix=inputs=2:duration=longest:weights=1 1" mixed.wav
```

### 85. Encode for Spotify podcasts (192kbps AAC)
**Use case:** Spotify Podcasts upload requirement  
**Command:**
```
ffmpeg -i episode.wav -c:a aac -b:a 192k -ar 44100 -ac 2 spotify_episode.m4a
```

### 86. Add chapter markers to M4A podcast
**Use case:** Apple Podcasts chapter navigation  
**Command:**
```
ffmpeg -i episode.m4a -metadata chapter_0_start=0 -metadata chapter_0_title="Intro" -metadata chapter_1_start=180000 -metadata chapter_1_title="Interview" chapters.m4a
```

### 87. Trim silence from both ends automatically
**Use case:** Studio recording with pre/post silence  
**Command:**
```
ffmpeg -i recording.wav -af "silenceremove=start_periods=1:start_threshold=-50dB:stop_periods=1:stop_threshold=-50dB" trimmed.wav
```

### 88. Export podcast RSS audio (128kbps MP3 mono)
**Use case:** Minimal bandwidth for RSS feed subscribers  
**Command:**
```
ffmpeg -i episode.wav -c:a libmp3lame -b:a 128k -ac 1 episode_rss.mp3
conv --id3 episode_rss.mp3 --title "Episode 42" --artist "Podcast Name" --album "Season 3" --year 2026
```

---

## Transcription Prep

### 89. Convert to 16kHz mono WAV for Whisper
**Use case:** Optimal Whisper transcription input  
**Command:**
```
ffmpeg -i input.mp4 -vn -ar 16000 -ac 1 -c:a pcm_s16le whisper_input.wav
```

### 90. Split long audio for API transcription (25MB limit)
**Use case:** OpenAI Whisper API file size limit  
**Command:**
```
conv --split-file long_recording.wav --size 24M chunk_%02d.wav
```

### 91. Boost speech clarity before transcription
**Use case:** Mumbled or far-mic recording  
**Command:**
```
ffmpeg -i quiet_speech.wav -af "highpass=f=200,speechnorm=e=12.5:r=0.0001:l=1" boosted.wav
```

### 92. Strip music sections before transcription
**Use case:** Song intros causing wrong transcription  
**Command:**
```
conv --split-silence podcast_with_music.wav --min-silence 2.0 --threshold -30dB
```

### 93. Multi-speaker separation prep
**Use case:** Diarization — separate tracks per speaker  
**Command:**
```
ffmpeg -i interview.wav -map_channel 0.0.0 -ar 16000 -ac 1 speaker1.wav
ffmpeg -i interview.wav -map_channel 0.0.1 -ar 16000 -ac 1 speaker2.wav
```

---

## Troubleshooting

### 94. Fix corrupted MP3 (re-encode)
**Use case:** MP3 with clicking/glitches  
**Command:**
```
ffmpeg -i corrupt.mp3 -c:a libmp3lame -q:a 2 fixed.mp3
```

### 95. Recover audio from unfinished recording
**Use case:** DAW crashed, partial file  
**Command:**
```
ffmpeg -i partial_recording.wav -c:a copy -t 00:45:00 recovered.wav
```

### 96. Fix wrong duration metadata
**Use case:** Player shows wrong length  
**Command:**
```
ffmpeg -i wrong_duration.mp3 -c:a copy fixed_duration.mp3
```

---

## Combo Workflows

### 97. Interview Recording → Podcast Episode → Upload-Ready
**Use case:** Full interview-to-publish pipeline  
**Command:**
```
# Step 1: Clean and normalize
ffmpeg -i interview_raw.wav -af "highpass=f=100,silenceremove=start_periods=1:start_threshold=-50dB" clean.wav
conv --normalize clean.wav normalized.wav --target -16
# Step 2: Add intro/outro
ffmpeg -i Intro_Musik.mp3 -i normalized.wav -i Outro_Musik.mp3 -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1" with_music.mp3
# Step 3: Tag and export
conv --id3 with_music.mp3 --title "Folge 42: Gast Interview" --artist "SuperPodcast" --year 2026
ffmpeg -i with_music.mp3 -c:a libmp3lame -b:a 128k -ac 1 episode_42.mp3
```

### 98. Music Album Batch Convert + Tag
**Use case:** Convert WAV masters → tagged MP3s  
**Command:**
```
convall wav mp3 ~/Album_Master/ --output-dir ~/Album_MP3/
for f in ~/Album_MP3/*.mp3; do
  track=$(echo "$f" | grep -o '[0-9]\{2\}')
  conv --id3 "$f" --artist "Supersynergy" --album "Debut 2026" --year 2026 --track "$track"
done
```

### 99. Phone Voice Memo → Transcription → Text File
**Use case:** Dictated notes → readable text  
**Command:**
```
ffmpeg -i Sprachmemo.m4a -ar 16000 -ac 1 whisper_input.wav
whisper whisper_input.wav --language de --output_format txt -o ./
```

### 100. DJ Set → Split Tracks → Tag → FLAC Archive
**Use case:** DJ set recording → individual track library  
**Command:**
```
conv --split-silence djset.wav --min-silence 2.0
for i in $(seq -w 1 20); do
  conv "djset_${i}.wav" "tracks/track_${i}.flac"
  conv --id3 "tracks/track_${i}.flac" --album "DJ Set Live 2026" --track "$i"
done
```
