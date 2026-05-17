# Real-World Integrations — Nahtlos in den Alltag

Weg vom Terminal. Der Converter läuft im Hintergrund, per Hotkey, per Drag-and-drop, per Mail, per Shortcut.

---

## 1. Watch-Folder (Auto-Process)

**Ziel:** Datei landet im Ordner → wird automatisch verarbeitet.

### Setup (einmalig)
```bash
brew install fswatch
```

### Bäckerei-Beispiel: Insta-Fotos auto-ready
```bash
mkdir -p ~/Dropbox/Auto-Process/{input,output}
cat > ~/bin/auto-insta.sh <<'EOF'
#!/bin/zsh
source ~/projects/universal-media-file-converter/conv.sh
IN=~/Dropbox/Auto-Process/input
OUT=~/Dropbox/Auto-Process/output
fswatch -0 "$IN" | while read -d "" f; do
  [[ ! -f "$f" ]] && continue
  base=$(basename "$f" .heic)
  conv --strip-exif "$f"
  conv --auto-rotate "$f"
  conv --crop "$f" 1080x1350+0+0 "$OUT/${base}_insta.jpg"
  conv "$f" "$OUT/${base}_story.jpg" && resize "$OUT/${base}_story.jpg" 1080
  osascript -e "display notification \"$base bereit\" with title \"Auto-Insta\""
done
EOF
chmod +x ~/bin/auto-insta.sh
```

### Als LaunchAgent (dauerhaft)
```bash
cat > ~/Library/LaunchAgents/com.auto-insta.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
  <key>Label</key><string>com.auto-insta</string>
  <key>ProgramArguments</key>
  <array><string>/Users/master/bin/auto-insta.sh</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/com.auto-insta.plist
```

---

## 2. macOS Shortcuts Integration

**Ziel:** Rechtsklick auf Datei → „In PDF/X-1a konvertieren"

### Shortcut via `shortcuts` CLI
```bash
# In Shortcuts-App: neuer Shortcut „Print-Ready"
# Input: Files
# Action: "Run Shell Script"
cat <<'EOF'
for f in "$@"; do
  zsh -c "source ~/projects/universal-media-file-converter/conv.sh && conv --smart 'flyer wirmachendruck' '$f'"
done
EOF
# → Erscheint als macOS-Service „Print-Ready" im Rechtsklick-Menü
```

### Beispiel-Shortcuts (fertig bauen)
| Name | Input | Aktion |
|------|-------|--------|
| **Print-Ready** | PDF | `conv --print-prep file offset` |
| **Web-Ready** | PDF | `conv --print-prep file web` |
| **Strip EXIF** | Images | `conv --strip-exif *.jpg` |
| **HEIC → JPG** | HEIC | `conv file.heic file.jpg` |
| **Dedupe Folder** | Folder | `conv --dedupe folder --delete` |
| **Business Card** | JPG | `conv --business-card front.jpg card.pdf` |
| **QR from URL** | URL text | `conv --qr-svg "$url" qr.svg` |

---

## 3. Raycast Integration (Script Commands)

**Ziel:** ⌘+Space → „flyer" tippen → Datei drauf → fertig.

```bash
mkdir -p ~/raycast-scripts
cat > ~/raycast-scripts/print-prep.sh <<'EOF'
#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Print-Ready (Offset)
# @raycast.mode compact
# @raycast.argument1 { "type": "text", "placeholder": "PDF path" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "Printer",
#   "data": [
#     {"title":"Wir Machen Druck","value":"wirmachendruck"},
#     {"title":"Flyeralarm","value":"flyeralarm"},
#     {"title":"Saxoprint","value":"saxoprint"}
#   ]}
source ~/projects/universal-media-file-converter/conv.sh
conv --for "$2" flyer_a5 "$1"
EOF
chmod +x ~/raycast-scripts/print-prep.sh
# Raycast Settings → Extensions → Script Commands → ~/raycast-scripts
```

---

## 4. Drag-and-Drop Droplet (.app)

**Ziel:** Icon auf Desktop. Dateien drauf werfen → fertig.

### Automator-Droplet bauen
```bash
# In Automator.app: neues Dokument → „Programm"
# Action: "Run Shell Script"  —  Input: "as arguments"
cat <<'EOF'
for f in "$@"; do
  /bin/zsh -c "source ~/projects/universal-media-file-converter/conv.sh && conv --smart 'flyer wirmachendruck' '$f'"
done
EOF
# Speichern als ~/Desktop/PrintReady.app
```

Desktop-Icon: Dateien drauf werfen → Print-Ready. Zero Terminal.

---

## 5. Mail-Integration (Anhänge auto-processen)

**Ziel:** Mandant mailt 50 Belege → auto in DATEV-ready PDF.

### AppleScript + Mail Rule
```applescript
-- Mail.app: Settings → Rules
-- If: Subject contains "Belege"
-- Do: Run AppleScript
tell application "Mail"
  repeat with m in selected messages
    set attachList to mail attachments of m
    repeat with a in attachList
      set fname to name of a
      save a in POSIX file ("/Users/master/Belege-Inbox/" & fname)
    end repeat
  end repeat
end tell
-- Watch-Folder picks up + processes
```

### Watch-Folder für Belege
```bash
cat > ~/bin/belege-processor.sh <<'EOF'
#!/bin/zsh
source ~/projects/universal-media-file-converter/conv.sh
IN=~/Belege-Inbox
OUT=~/Belege-Ready
fswatch -0 "$IN" | while read -d "" f; do
  [[ ! -f "$f" ]] && continue
  ext="${f##*.}"
  case "${ext:l}" in
    heic|jpg|png)
      conv --auto-rotate "$f"
      conv "$f" "${f%.*}.pdf"
      conv --pdf-ocr "${f%.*}.pdf" deu "$OUT/$(basename "${f%.*}").pdf"
      ;;
    pdf)
      conv --pdf-ocr "$f" deu "$OUT/$(basename "$f")"
      ;;
  esac
done
EOF
```

---

## 6. Scanner-Integration (ScanSnap, Brother, etc.)

**Ziel:** Scanner-Output landet direkt print-ready.

### ScanSnap-Ordner watchen
```bash
# ScanSnap Home speichert nach ~/Documents/ScanSnap
# Unser Watcher: OCR + komprimieren + umbenennen
cat > ~/bin/scansnap-processor.sh <<'EOF'
#!/bin/zsh
source ~/projects/universal-media-file-converter/conv.sh
fswatch -0 ~/Documents/ScanSnap | while read -d "" f; do
  [[ "${f##*.}" != "pdf" ]] && continue
  conv --auto-rotate "$f" 2>/dev/null
  conv --pdf-ocr "$f" deu "${f%.*}_ocr.pdf"
  conv --pdf-compress "${f%.*}_ocr.pdf" "${f%.*}_final.pdf"
  conv --rename-batch '{year}-{month}-{day}_scan.{ext}' "$(dirname "$f")"
done
EOF
```

---

## 7. iCloud / Dropbox Sync

**Ziel:** iPhone-Foto landet in iCloud → in 5s auf Mac optimiert.

```bash
# ~/Library/Mobile Documents/com~apple~CloudDocs/AutoPhoto
fswatch -0 ~/Library/Mobile\ Documents/com~apple~CloudDocs/AutoPhoto | \
while read -d "" f; do
  conv --strip-exif "$f"
  conv --auto-rotate "$f"
  optimg "$f"
done
```

---

## 8. Alfred Workflow

**Ziel:** `conv flyer file.pdf` in Alfred → Erklärung + Dispatch.

```bash
# Alfred: Workflows → Script Filter
# Keyword: "conv"
# Script:
query="{query}"
source ~/projects/universal-media-file-converter/conv.sh
conv --smart "$query"
```

---

## 9. CLI-Server Mode (HTTP Endpoint)

**Ziel:** Andere Apps können per POST konvertieren.

```bash
# Simple Python wrapper — exposes HTTP endpoint
cat > ~/bin/conv-server.py <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess, json, os
class H(BaseHTTPRequestHandler):
  def do_POST(self):
    n = int(self.headers.get('Content-Length'))
    data = json.loads(self.rfile.read(n))
    cmd = data.get('command', '')
    out = subprocess.run(
      f"source ~/projects/universal-media-file-converter/conv.sh && {cmd}",
      shell=True, executable='/bin/zsh', capture_output=True, text=True)
    self.send_response(200); self.send_header('Content-Type','application/json')
    self.end_headers()
    self.wfile.write(json.dumps({
      'stdout': out.stdout, 'stderr': out.stderr, 'code': out.returncode
    }).encode())
HTTPServer(('127.0.0.1', 9876), H).serve_forever()
EOF
# POST {"command":"conv --smart 'flyer wirmachendruck' /path/file.pdf"}
```

---

## 10. WhatsApp Business API → Auto-Process

**Ziel:** Kunde schickt Bild per WhatsApp → kommt als OCR-PDF zurück.

```bash
# Pseudocode — echter Webhook via WA Business API
# Webhook empfängt Medienlink → lädt runter → processt → antwortet

curl -o /tmp/wa_upload.heic "$MEDIA_URL"
source ~/projects/universal-media-file-converter/conv.sh
conv --strip-exif /tmp/wa_upload.heic
conv /tmp/wa_upload.heic /tmp/wa_upload.pdf
conv --pdf-ocr /tmp/wa_upload.pdf deu /tmp/wa_final.pdf
# Upload back via WA API
curl -X POST -F "file=@/tmp/wa_final.pdf" "$WA_SEND_ENDPOINT"
```

---

## 11. Hotkey-Trigger (BetterTouchTool / Karabiner)

**Ziel:** ⌃⌥⌘P auf markierte Datei → Print-Ready.

```bash
# BetterTouchTool: neue Keyboard-Shortcut ⌃⌥⌘P
# Action: "Execute Terminal Command (async)"
# Command:
f=$(osascript -e 'tell application "Finder" to get the POSIX path of (the selection as alias)')
zsh -c "source ~/projects/universal-media-file-converter/conv.sh && conv --smart 'flyer wirmachendruck' '$f'"
```

---

## 12. CRM-Integration (Pipedrive, HubSpot)

**Ziel:** Deal-Anhang in CRM → auto print-ready speichern.

```bash
# CRM-Webhook (new attachment) → Lokaler Endpoint
# Lädt runter, processt, lädt als zweite Version hoch
# Beispiel Pipedrive: File > Deal > Auto-Version "-print-ready.pdf"
```

---

## 13. Slack-Bot (Team-Integration)

**Ziel:** Datei in #marketing drop → Bot antwortet mit Print-Ready-Version.

```python
# Slack-App mit file_shared event
# Bot downloaded file, runs conv --smart, uploads back
```

---

## 14. DSGVO-Mode (Auto-Anonymisierung)

**Ziel:** Fotos vom iPhone automatisch **ohne GPS + EXIF + Name** für Upload vorbereiten.

```bash
cat > ~/bin/dsgvo-strip.sh <<'EOF'
#!/bin/zsh
source ~/projects/universal-media-file-converter/conv.sh
IN=~/Dropbox/DSGVO-Input
OUT=~/Dropbox/DSGVO-Output
fswatch -0 "$IN" | while read -d "" f; do
  [[ ! -f "$f" ]] && continue
  conv --strip-exif "$f"              # Alle EXIF-Daten weg
  conv --rename-batch '{seq:4}.{ext}' "$(dirname "$f")"  # Anonymer Name
  mv "$f" "$OUT/"
done
EOF
```

---

## 15. Bulk-Intake für Steuerberater

**Ziel:** Mandanten-Dropbox-Ordner → auto-OCR → DATEV-ready.

```bash
cat > ~/bin/tax-intake.sh <<'EOF'
#!/bin/zsh
source ~/projects/universal-media-file-converter/conv.sh
MANDANT_DIR="$1"  # e.g. ~/Dropbox/Mandanten/Huber-Q1-2026
cd "$MANDANT_DIR"
conv --strip-exif *.heic *.jpg 2>/dev/null
conv --auto-rotate *.heic *.jpg 2>/dev/null
convall heic pdf . --parallel 8 2>/dev/null
convall jpg pdf . --parallel 8 2>/dev/null
conv --pdf-merge gesamt.pdf *.pdf
conv --pdf-ocr gesamt.pdf deu searchable.pdf
conv --pdf-text searchable.pdf > belege.txt
# Parser-Script → DATEV-CSV (user-specific)
osascript -e "display notification \"Mandant $MANDANT_DIR bereit\""
EOF
chmod +x ~/bin/tax-intake.sh
```

---

## Empfohlene Starter-Integration

**Für kleine Unternehmen in Bayern:**

1. **Droplet auf Desktop** (30 Min Setup) — keine Terminal-Kenntnisse nötig
2. **Raycast Script Commands** — ⌘+Space → Command tippen
3. **Watch-Folder via launchd** — einmal eingerichtet, läuft für immer
4. **macOS Shortcuts** — Rechtsklick-Menü

**Für Teams:**

1. **HTTP-Server Mode** — zentrale Conversion-Instanz
2. **Slack-Bot** — Team-weit verfügbar
3. **CRM-Webhook** — Deal-Anhänge automatisch

---

## Time-Saving Multiplier

| Integration | Einmal-Setup | Ersparnis pro Nutzung | ROI bei 10×/Tag |
|-------------|-------------|----------------------|-----------------|
| Droplet | 15 Min | 5 Min | Break-even nach Tag 1 |
| Watch-Folder | 30 Min | 8 Min | Break-even nach Tag 1 |
| Shortcuts | 10 Min | 3 Min | Break-even nach Tag 1 |
| HTTP-Server | 2 h | — | ab 20 Users/Tag |
| Slack-Bot | 4 h | — | ab 5 User-Team |
| WhatsApp API | 8 h | — | ab 50 Kunden/Tag |
