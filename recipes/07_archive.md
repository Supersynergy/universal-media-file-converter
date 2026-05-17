# Archive & Backup Recipes

100 real-world archiving, backup, and file management recipes using `conv`.

## TOC
- [Extract Archives](#extract-archives) — 1–14
- [Compress & Create Archives](#compress--create-archives) — 15–30
- [Split Large Archives](#split-large-archives) — 31–38
- [Verification & Integrity](#verification--integrity) — 39–46
- [Password-Protected Archives](#password-protected-archives) — 47–54
- [Format-Specific Handling](#format-specific-handling) — 55–66
- [Developer & Release Archives](#developer--release-archives) — 67–74
- [Backup Workflows](#backup-workflows) — 75–84
- [Long-Term Storage](#long-term-storage) — 85–92
- [Troubleshooting](#troubleshooting) — 93–96
- [Combo Workflows](#combo-workflows) — 97–100

---

## Extract Archives

### 1. Extract ZIP archive
**Use case:** Standard ZIP from email or download  
**Command:**
```
conv --extract Dateien.zip
```

### 2. Extract to specific directory
**Use case:** Don't clutter current folder  
**Command:**
```
conv --extract Archiv.zip --output-dir ./extracted/
```

### 3. Extract TAR.GZ (tarball)
**Use case:** Linux/macOS source code download  
**Command:**
```
conv --extract projekt.tar.gz
```

### 4. Extract TAR.BZ2
**Use case:** Alternative compression format tarball  
**Command:**
```
conv --extract backup.tar.bz2
```

### 5. Extract TAR.XZ (best compression)
**Use case:** Modern Linux package tarball  
**Command:**
```
conv --extract source.tar.xz
```

### 6. Extract 7z archive
**Use case:** High-compression 7-Zip file  
**Command:**
```
conv --extract Backup.7z
```

### 7. Extract RAR archive
**Use case:** Received RAR from Windows user  
**Command:**
```
conv --extract Dateien.rar
```

### 8. Extract selective files from archive
**Use case:** Only need one file from large archive  
**Command:**
```
unzip Archiv.zip "Dokumente/Rechnung.pdf" -d ./
```

### 9. Extract only specific file type from ZIP
**Use case:** Pull all PDFs from mixed ZIP  
**Command:**
```
unzip Archiv.zip "*.pdf" -d ./PDFs/
```

### 10. List archive contents without extracting
**Use case:** Preview before extracting large archive  
**Command:**
```
unzip -l Archiv.zip
7z l Backup.7z
tar -tzf projekt.tar.gz
```

### 11. Extract all archives in directory
**Use case:** Batch extraction of downloaded ZIPs  
**Command:**
```
conv --extract-all ./Downloads/ --output-dir ./Extracted/
```

### 12. Extract nested archives (ZIP inside ZIP)
**Use case:** Client sent ZIP with ZIPs inside  
**Command:**
```
conv --extract outer.zip --output-dir temp/
for f in temp/*.zip; do conv --extract "$f" --output-dir "extracted/${f%.zip}"; done
```

### 13. Extract split archive (ZIP.001, .002...)
**Use case:** Multi-part ZIP from old file transfer  
**Command:**
```
7z x split_archive.zip.001
```

### 14. Extract macOS .dmg
**Use case:** Inspect DMG contents without mounting  
**Command:**
```
7z x Application.dmg -o extracted_dmg/
```

---

## Compress & Create Archives

### 15. Create ZIP archive
**Use case:** Send files to client in ZIP  
**Command:**
```
conv --compress Projektordner/ Projekt.zip
```

### 16. Create TAR.GZ tarball
**Use case:** Unix-standard file transfer  
**Command:**
```
conv --compress ./source/ source_backup.tar.gz
```

### 17. Create TAR.XZ (maximum compression tarball)
**Use case:** Long-term storage, minimize space  
**Command:**
```
tar -cJf Archiv_max.tar.xz ./Daten/
```

### 18. Create 7z with maximum compression
**Use case:** Best compression ratio, large files  
**Command:**
```
7z a -mx=9 Backup_max.7z ./Daten/
```

### 19. Create 7z ultra compression
**Use case:** Cold storage — size matters most  
**Command:**
```
7z a -m0=lzma2 -mx=9 -mfb=64 -md=32m Ultra.7z ./Data/
```

### 20. Create archive with specific compression level
**Use case:** Balance speed and compression  
**Command:**
```
7z a -mx=5 Backup_balanced.7z ./Data/
```

### 21. Fast compression (ZIP, speed priority)
**Use case:** Quick packaging, size not critical  
**Command:**
```
zip -r -1 Fast.zip ./Daten/
```

### 22. Archive only specific file types
**Use case:** Backup only documents (PDF, DOCX, XLSX)  
**Command:**
```
find ./Dokumente/ \( -name "*.pdf" -o -name "*.docx" -o -name "*.xlsx" \) | zip -@ Dokumente_Backup.zip
```

### 23. Create archive excluding certain patterns
**Use case:** ZIP project without node_modules  
**Command:**
```
zip -r Projekt.zip ./projekt/ -x "*/node_modules/*" -x "*/.git/*" -x "*/dist/*"
```

### 24. Create self-extracting archive
**Use case:** Send to user who can't install 7zip  
**Command:**
```
7z a -sfx Selbstextrahierend.exe ./Daten/
```

### 25. Archive with store (no compression)
**Use case:** Files already compressed (JPG, MP4, PDF)  
**Command:**
```
zip -r -0 Container.zip ./Medien/
```

### 26. Create TAR without compression (fast)
**Use case:** Bundle files for streaming/piping  
**Command:**
```
tar -cf Snapshot.tar ./Projekt/
```

### 27. Create archives with timestamp in filename
**Use case:** Daily backup naming convention  
**Command:**
```
tar -czf "Backup_$(date +%Y-%m-%d).tar.gz" ./Daten/
```

### 28. Archive with exclusion list from file
**Use case:** Complex exclude patterns  
**Command:**
```
rsync -a --exclude-from=.gitignore ./projekt/ ./temp_stage/
tar -czf deploy.tar.gz ./temp_stage/
```

### 29. Create ISO image from folder
**Use case:** Burn-ready disc image from content  
**Command:**
```
mkisofs -o disc.iso -J -R ./disc_content/
```

### 30. Compress multiple directories into one archive
**Use case:** Archive multiple project folders  
**Command:**
```
tar -czf Alle_Projekte.tar.gz ./Projekt_A/ ./Projekt_B/ ./Projekt_C/
```

---

## Split Large Archives

### 31. Split ZIP into 100MB parts
**Use case:** Upload limit on file sharing service  
**Command:**
```
conv --split-file large.zip --size 100M part_%03d.zip
```

### 32. Split into 4GB chunks (FAT32)
**Use case:** Copy archive to FAT32 USB drive  
**Command:**
```
7z a -v4g Backup.7z ./Daten/
```

### 33. Split into 2GB chunks
**Use case:** Old file host limit  
**Command:**
```
split -b 2G large_archive.tar.gz archive_part_
```

### 34. Split with checksum verification
**Use case:** Split + verify each chunk  
**Command:**
```
split -b 1G backup.tar.gz chunk_
for f in chunk_*; do sha256sum "$f" >> checksums.sha256; done
```

### 35. Create multi-volume 7z
**Use case:** Automatic split with 7-Zip  
**Command:**
```
7z a -v1g Backup.7z ./Source/
```

### 36. Split and password protect chunks
**Use case:** Encrypted split for cloud upload  
**Command:**
```
7z a -v500m -p"SecurePass123" -mhe Encrypted_Split.7z ./Sensitive/
```

### 37. Reassemble split files
**Use case:** Download all parts, extract  
**Command:**
```
cat archive_part_* > reassembled.tar.gz
tar -xzf reassembled.tar.gz
```

### 38. Split archive for email (25MB limit)
**Use case:** Send large project via email  
**Command:**
```
7z a -v24m Projekt_email.7z ./Projektordner/
```

---

## Verification & Integrity

### 39. Verify archive integrity
**Use case:** Check archive not corrupt before deleting source  
**Command:**
```
7z t Backup.7z
unzip -t Archive.zip
```

### 40. Generate checksum for archive
**Use case:** Verify download integrity  
**Command:**
```
sha256sum Backup.tar.gz > Backup.tar.gz.sha256
```

### 41. Verify checksum
**Use case:** After download/copy, verify integrity  
**Command:**
```
sha256sum -c Backup.tar.gz.sha256
```

### 42. Generate MD5 checksum (legacy compatibility)
**Use case:** Some platforms require MD5  
**Command:**
```
md5sum Archive.zip > Archive.zip.md5
```

### 43. List files in archive with sizes
**Use case:** Verify contents before extraction  
**Command:**
```
7z l -slt Backup.7z | grep -E "^Path|^Size"
```

### 44. Verify tar archive contents
**Use case:** Check tar without extracting  
**Command:**
```
tar -tzvf backup.tar.gz | head -50
```

### 45. Compare archive to source folder
**Use case:** Verify archive is complete  
**Command:**
```
tar -tzvf backup.tar.gz | awk '{print $NF}' | sort > archived_files.txt
find ./source/ -type f | sort > source_files.txt
diff source_files.txt archived_files.txt
```

### 46. Recursive checksum directory before archiving
**Use case:** Baseline for verification later  
**Command:**
```
find ./Daten/ -type f -exec sha256sum {} \; > pre_archive_checksums.sha256
```

---

## Password-Protected Archives

### 47. Create password-protected ZIP
**Use case:** Send sensitive client data  
**Command:**
```
zip -er Vertraulich.zip ./Sensitive_Daten/
```

### 48. Create encrypted 7z (AES-256)
**Use case:** Strong encryption for archive  
**Command:**
```
7z a -p"StrongPass123!" -mhe=on Encrypted.7z ./Daten/
```

### 49. Create encrypted TAR (via openssl)
**Use case:** Encrypted tarball for transfer  
**Command:**
```
tar -czf - ./Daten/ | openssl enc -aes-256-cbc -salt -out Encrypted.tar.gz.enc
```

### 50. Decrypt and extract
**Use case:** Receive encrypted archive  
**Command:**
```
openssl enc -d -aes-256-cbc -in Encrypted.tar.gz.enc | tar -xzf -
```

### 51. Extract password-protected 7z
**Use case:** Received secured archive  
**Command:**
```
7z x -p"password" Protected.7z
```

### 52. Extract password-protected ZIP
**Use case:** Client sent ZIP with password  
**Command:**
```
unzip -P "password" Protected.zip
```

### 53. Create encrypted archive with different passwords per file
**Use case:** Share archive with different people seeing different parts  
**Command:**
```
7z a -p"RecipientA_Pass" ForA.7z ./ForPersonA/
7z a -p"RecipientB_Pass" ForB.7z ./ForPersonB/
```

### 54. Archive with header encryption (hide filenames)
**Use case:** Even filenames must be hidden  
**Command:**
```
7z a -p"pass" -mhe=on HiddenNames.7z ./Secret/
```

---

## Format-Specific Handling

### 55. Handle macOS .pkg file inspection
**Use case:** Inspect installer package without running  
**Command:**
```
pkgutil --expand Application.pkg extracted_pkg/
```

### 56. Create macOS .dmg from folder
**Use case:** Distribute macOS app in DMG  
**Command:**
```
hdiutil create -volname "App" -srcfolder ./App.app -ov -format UDZO App.dmg
```

### 57. Convert DMG to ISO
**Use case:** Cross-platform disc image  
**Command:**
```
hdiutil convert Application.dmg -format UDTO -o Application.iso
mv Application.iso.cdr Application.iso
```

### 58. Extract from RAR with multiple volumes
**Use case:** Downloaded multi-part RAR  
**Command:**
```
unrar x "download.part1.rar"
```

### 59. Convert ZIP to 7z (recompress)
**Use case:** Replace ZIP with better-compressed 7z  
**Command:**
```
7z x old.zip -o temp/
7z a new.7z ./temp/
rm -rf temp/
```

### 60. Create gzip of single file
**Use case:** Compress log file  
**Command:**
```
gzip -9 -k large.log
```

### 61. Decompress gzip file
**Use case:** Extract .gz compressed file  
**Command:**
```
gunzip file.log.gz
```

### 62. Create bzip2 compressed file
**Use case:** High compression for text files  
**Command:**
```
bzip2 -9 -k Textdaten.sql
```

### 63. Create XZ compressed (best ratio for text)
**Use case:** Database dump, maximum compression  
**Command:**
```
xz -9 -k database_dump.sql
```

### 64. Inspect ZIP without extracting (Python)
**Use case:** Programmatic archive inspection  
**Command:**
```
python3 -c "import zipfile; z=zipfile.ZipFile('archive.zip'); [print(i.filename, i.file_size) for i in z.infolist()]"
```

### 65. Repair corrupted ZIP
**Use case:** Partial download — try to recover  
**Command:**
```
zip -FF corrupt.zip --out repaired.zip
```

### 66. Extract specific file from TAR without full extraction
**Use case:** Large TAR — only need one file  
**Command:**
```
tar -xzf large_archive.tar.gz ./path/to/specific_file.txt
```

---

## Developer & Release Archives

### 67. Create git archive for release
**Use case:** Export clean source without .git  
**Command:**
```
git archive --format=tar.gz --prefix=projekt-v1.0/ HEAD > projekt-v1.0.tar.gz
```

### 68. Create ZIP release from git tag
**Use case:** GitHub-style release download  
**Command:**
```
git archive --format=zip --prefix=projekt-v1.0/ v1.0 > projekt-v1.0.zip
```

### 69. Archive build artifacts
**Use case:** Save build output for deployment  
**Command:**
```
tar -czf "build_$(git rev-parse --short HEAD).tar.gz" ./dist/
```

### 70. Create deployment package (no dev deps)
**Use case:** Node.js production deploy  
**Command:**
```
npm ci --production
tar -czf deploy.tar.gz node_modules/ dist/ package.json
```

### 71. Archive logs with compression
**Use case:** Rotate and compress old logs  
**Command:**
```
for f in /var/log/app/*.log; do gzip -9 "$f"; done
tar -czf "logs_$(date +%Y-%m).tar.gz" /var/log/app/*.gz
```

### 72. Create source distribution tarball
**Use case:** Python package sdist style  
**Command:**
```
tar -czf projekt-1.0.tar.gz --transform 's,^,projekt-1.0/,' src/ README.md setup.py
```

### 73. Find large files in git history for LFS candidates
**Use case:** Repo too large — find binary blobs  
**Command:**
```
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '/^blob/ && $3>1000000 {print $4, $3}' | sort -k2 -rn | head -20
```

### 74. Archive with git-lfs pointer files
**Use case:** LFS-enabled repo archive  
**Command:**
```
git archive --worktree-attributes HEAD | gzip > release_with_lfs.tar.gz
```

---

## Backup Workflows

### 75. Incremental backup with rsync + tar
**Use case:** Daily incremental photo backup  
**Command:**
```
rsync -av --checksum ~/Fotos/ /backup/Fotos_mirror/
tar -czf "/backup/Fotos_$(date +%Y-%m-%d).tar.gz" /backup/Fotos_mirror/
```

### 76. Full backup with verification
**Use case:** Weekly full backup + verify  
**Command:**
```
tar -czf backup.tar.gz ./Data/
sha256sum backup.tar.gz > backup.tar.gz.sha256
7z t backup.tar.gz && echo "Backup OK"
```

### 77. Backup only changed files (newer than date)
**Use case:** Incremental — only today's changes  
**Command:**
```
find ./Daten/ -newer last_backup_marker -type f | tar -czf "incremental_$(date +%Y-%m-%d).tar.gz" -T -
touch last_backup_marker
```

### 78. Cloud-upload-ready: split + checksum
**Use case:** Prepare large backup for cloud upload  
**Command:**
```
tar -czf full_backup.tar.gz ./Wichtige_Daten/
split -b 4G full_backup.tar.gz backup_part_
for f in backup_part_*; do sha256sum "$f" >> upload_checksums.sha256; done
```

### 79. Backup database dump
**Use case:** MySQL/SQLite backup  
**Command:**
```
sqlite3 database.db .dump | gzip -9 > "db_backup_$(date +%Y-%m-%d).sql.gz"
```

### 80. Archive old files (move to archive folder)
**Use case:** Clean up working directory  
**Command:**
```
find ./Projekte/ -mtime +365 -type f | tar -czf "Alte_Projekte_$(date +%Y).tar.gz" -T - --remove-files
```

### 81. Photo archive workflow (RAW + JPEG paired)
**Use case:** Keep RAW masters + developed JPEGs together  
**Command:**
```
find ./Shooting/ \( -name "*.CR2" -o -name "*.jpg" \) | tar -czf Shooting_2026_komplett.tar.gz -T -
sha256sum Shooting_2026_komplett.tar.gz > Shooting_2026_komplett.sha256
```

### 82. System config backup
**Use case:** macOS dotfiles and config  
**Command:**
```
tar -czf "dotfiles_$(date +%Y-%m-%d).tar.gz" ~/.zshrc ~/.gitconfig ~/.ssh/config ~/.claude/
```

### 83. Backup with timestamp rotation (keep 7 days)
**Use case:** Rolling backup window  
**Command:**
```
tar -czf "/backup/daily/backup_$(date +%Y-%m-%d).tar.gz" ./Daten/
find /backup/daily/ -name "backup_*.tar.gz" -mtime +7 -delete
```

### 84. Cross-machine backup via SSH
**Use case:** Local → remote server backup  
**Command:**
```
tar -czf - ./Daten/ | ssh user@backup-server "cat > /backup/Daten_$(date +%Y-%m-%d).tar.gz"
```

---

## Long-Term Storage

### 85. Cold storage archive (maximum compression + verify)
**Use case:** 5-year archive, access unlikely  
**Command:**
```
7z a -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on Cold_2026.7z ./Archiv_2026/
7z t Cold_2026.7z
sha256sum Cold_2026.7z > Cold_2026.7z.sha256
```

### 86. Create PAR2 recovery files
**Use case:** Protect archive against bit rot  
**Command:**
```
par2 create -r10 Backup.7z.par2 Backup.7z
```

### 87. Verify PAR2 and repair if needed
**Use case:** Periodic archive health check  
**Command:**
```
par2 verify Backup.7z.par2
par2 repair Backup.7z.par2
```

### 88. Archive to multiple locations (3-2-1 rule)
**Use case:** 3 copies, 2 media types, 1 offsite  
**Command:**
```
tar -czf backup.tar.gz ./Data/
cp backup.tar.gz /Volumes/External_Drive/Backup/
cp backup.tar.gz /Volumes/NAS/Backup/
# Upload third copy to cloud
rclone copy backup.tar.gz remote:backup-bucket/
```

### 89. Periodic integrity check schedule
**Use case:** Annual archive health check  
**Command:**
```
for f in /backup/*.7z; do
  echo "Checking: $f"
  7z t "$f" && echo "OK" || echo "CORRUPT: $f" >> corrupt_archives.txt
done
```

### 90. Convert old format archives to modern 7z
**Use case:** Migrate ZIP archives to better compression  
**Command:**
```
for f in *.zip; do
  7z x "$f" -o "temp/"
  7z a -mx=9 "${f%.zip}.7z" "./temp/"
  rm -rf "./temp/"
  sha256sum "${f%.zip}.7z" >> new_checksums.sha256
done
```

### 91. Add archive manifest (file list + dates)
**Use case:** Document archive contents in plain text  
**Command:**
```
7z l Archiv.7z > Archiv_manifest.txt
tar -tzvf backup.tar.gz > backup_manifest.txt
```

### 92. Migration between archive formats (7z → tar.xz)
**Use case:** Linux system migration  
**Command:**
```
7z x Windows_Backup.7z -o extracted/
tar -cJf Linux_Archive.tar.xz ./extracted/
sha256sum Linux_Archive.tar.xz > Linux_Archive.sha256
```

---

## Troubleshooting

### 93. Fix truncated ZIP (partial download)
**Use case:** Incomplete download — recover what's there  
**Command:**
```
zip -FF truncated.zip --out recovered.zip -fz
```

### 94. Recover from corrupted 7z
**Use case:** Archive damaged — extract what's possible  
**Command:**
```
7z e -y corrupt.7z
```

### 95. Fix tar: "invalid tar magic"
**Use case:** Wrong compression format or corrupt header  
**Command:**
```
file archive.tar.gz  # identify actual format
gzip -t archive.tar.gz  # test gzip integrity
```

### 96. Extract archive ignoring errors
**Use case:** Best-effort extraction from damaged archive  
**Command:**
```
unzip -o -q -: damaged.zip 2>/dev/null || true
7z e -y -ignoreErrors damaged.7z
```

---

## Combo Workflows

### 97. Project Completion → Clean → Archive → Verify → Cold Store
**Use case:** End-of-project archiving  
**Command:**
```
# Clean up build artifacts
find ./Projekt/ -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
find ./Projekt/ -name "*.log" -delete
# Archive
tar -czf "Projekt_Abschluss_$(date +%Y-%m-%d).tar.gz" ./Projekt/
# Verify
tar -tzf "Projekt_Abschluss_$(date +%Y-%m-%d).tar.gz" > manifest.txt
sha256sum "Projekt_Abschluss_$(date +%Y-%m-%d).tar.gz" > checksum.sha256
# Compress further for cold storage
7z a -mx=9 "Archiv/Projekt_Final.7z" "Projekt_Abschluss_$(date +%Y-%m-%d).tar.gz"
```

### 98. Photo Backup → Dedupe → Archive → Offsite
**Use case:** Monthly photo backup workflow  
**Command:**
```
# Import new photos
rsync -av ~/Pictures/iPhone/ ~/Pictures/Library/
# Remove duplicates
conv --dedupe ~/Pictures/Library/ --delete
# Monthly archive
tar -czf "Fotos_$(date +%Y-%m).tar.gz" ~/Pictures/Library/
# Offsite upload
rclone copy "Fotos_$(date +%Y-%m).tar.gz" remote:photo-backup/
# Verify
sha256sum "Fotos_$(date +%Y-%m).tar.gz" >> ~/backup_checksums.sha256
```

### 99. Development Repo → Clean Build → Package → Release Archive
**Use case:** Software release packaging  
**Command:**
```
git archive --format=tar.gz --prefix="myapp-v$(cat VERSION)/" "v$(cat VERSION)" > "releases/myapp-v$(cat VERSION)-src.tar.gz"
npm ci && npm run build
tar -czf "releases/myapp-v$(cat VERSION)-dist.tar.gz" dist/ package.json
sha256sum releases/*.tar.gz > releases/SHA256SUMS
```

### 100. 3-2-1 Backup Execution
**Use case:** Full 3-2-1 backup implementation  
**Command:**
```
DATE=$(date +%Y-%m-%d)
BACKUP="backup_${DATE}.tar.gz"

# Create
tar -czf "$BACKUP" ~/Wichtige_Daten/ ~/Dokumente/ ~/Projekte/
sha256sum "$BACKUP" > "${BACKUP}.sha256"

# Copy 1: External drive
cp "$BACKUP" /Volumes/Backup_Drive/Daily/
# Copy 2: NAS
cp "$BACKUP" /Volumes/NAS/Backup/
# Copy 3: Cloud offsite
rclone copy "$BACKUP" remote:offsite-backup/$(date +%Y-%m)/

# Verify all three
sha256sum -c "${BACKUP}.sha256"
echo "3-2-1 Backup complete for $DATE"
```
