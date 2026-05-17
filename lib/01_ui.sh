#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail

CONV_QUIET=0
CONV_JSON=0
CONV_TIMER_START=0

RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" RESET=""

_conv_color_init() {
  if [[ -t 1 ]] && command -v tput &>/dev/null; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
  else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
  fi
}

_info() {
  [[ "$CONV_QUIET" == "1" ]] && return 0
  printf "${BLUE}ℹ %s${RESET}\n" "$*"
}

_ok() {
  [[ "$CONV_QUIET" == "1" ]] && return 0
  printf "${GREEN}✓ %s${RESET}\n" "$*"
}

_warn() {
  [[ "$CONV_QUIET" == "1" ]] && return 0
  printf "${YELLOW}⚠ %s${RESET}\n" "$*"
}

_err() {
  printf "${RED}✗ %s${RESET}\n" "$*" >&2
}

_conv_bar() {
  [[ "$CONV_QUIET" == "1" ]] && return 0
  local current=$1
  local total=$2
  local width=12
  local pct=$(( current * 100 / total ))
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done
  printf "\r[%s] %d%%" "$bar" "$pct"
}

_conv_size_fmt() {
  local bytes=$1
  if (( bytes >= 1073741824 )); then
    awk "BEGIN { printf \"%.1f GB\", $bytes/1073741824 }"
  elif (( bytes >= 1048576 )); then
    awk "BEGIN { printf \"%.1f MB\", $bytes/1048576 }"
  elif (( bytes >= 1024 )); then
    awk "BEGIN { printf \"%.1f KB\", $bytes/1024 }"
  else
    echo "${bytes} B"
  fi
}

_conv_done() {
  local infile=$1
  local outfile=$2
  local in_bytes out_bytes elapsed ratio in_fmt out_fmt elapsed_fmt
  in_bytes=$(stat -f%z "$infile" 2>/dev/null || echo 0)
  out_bytes=$(stat -f%z "$outfile" 2>/dev/null || echo 0)
  elapsed=$(_conv_elapsed)
  in_fmt=$(_conv_size_fmt "$in_bytes")
  out_fmt=$(_conv_size_fmt "$out_bytes")

  if (( out_bytes > 0 && in_bytes > out_bytes )); then
    ratio=$(awk "BEGIN { printf \"%.1fx\", $in_bytes/$out_bytes }")
    local ratio_str="$ratio smaller"
  else
    ratio_str="larger"
  fi

  local mins=$(( elapsed / 60 ))
  local secs=$(( elapsed % 60 ))
  if (( mins > 0 )); then
    elapsed_fmt="${mins}m ${secs}s"
  else
    elapsed_fmt="${secs}s"
  fi

  if [[ "$CONV_JSON" == "1" ]]; then
    printf '{"in":"%s","out":"%s","in_bytes":%d,"out_bytes":%d,"elapsed":%d}\n' \
      "$(basename "$infile")" "$(basename "$outfile")" "$in_bytes" "$out_bytes" "$elapsed"
    return 0
  fi

  [[ "$CONV_QUIET" == "1" ]] && return 0
  printf "\n${GREEN}✅ %s → %s | %s → %s (%s) | %s${RESET}\n" \
    "$(basename "$infile")" "$(basename "$outfile")" \
    "$in_fmt" "$out_fmt" "$ratio_str" "$elapsed_fmt"
}

_conv_start_timer() {
  CONV_TIMER_START=$SECONDS
}

_conv_elapsed() {
  echo $(( SECONDS - CONV_TIMER_START ))
}

_conv_color_init
