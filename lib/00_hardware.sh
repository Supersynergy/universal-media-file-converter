#!/usr/bin/env bash
# sourced into interactive shell — no set -euo pipefail

CONV_HW_TIER=""
CONV_RAM_TIER=""
CONV_CORES=""
CONV_H264_BITRATE=""
CONV_H265_BITRATE=""
CONV_AV1_SPEED=""

_conv_hw_detect() {
  [[ -n "$CONV_HW_TIER" ]] && return 0

  local cpu
  cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
  CONV_CORES=$(sysctl -n hw.logicalcpu 2>/dev/null || echo "4")

  local mem_bytes
  mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
  local mem_gb=$(( mem_bytes / 1073741824 ))

  if (( mem_gb >= 64 )); then
    CONV_RAM_TIER="high"
  elif (( mem_gb >= 16 )); then
    CONV_RAM_TIER="medium"
  else
    CONV_RAM_TIER="low"
  fi

  if [[ "$cpu" == *"M4 Ultra"* ]]; then
    CONV_HW_TIER="ultra"
  elif [[ "$cpu" == *"M4 Max"* ]]; then
    CONV_HW_TIER="max"
  elif [[ "$cpu" == *"M4 Pro"* ]]; then
    CONV_HW_TIER="pro"
  elif [[ "$cpu" == *"M4"* ]]; then
    CONV_HW_TIER="base"
  elif [[ "$cpu" == *"M3 Ultra"* ]]; then
    CONV_HW_TIER="ultra"
  elif [[ "$cpu" == *"M3 Max"* ]]; then
    CONV_HW_TIER="max"
  elif [[ "$cpu" == *"M3 Pro"* ]]; then
    CONV_HW_TIER="pro"
  elif [[ "$cpu" == *"M3"* ]]; then
    CONV_HW_TIER="base"
  elif [[ "$cpu" == *"M2 Ultra"* ]]; then
    CONV_HW_TIER="ultra"
  elif [[ "$cpu" == *"M2 Max"* ]]; then
    CONV_HW_TIER="max"
  elif [[ "$cpu" == *"M2 Pro"* ]]; then
    CONV_HW_TIER="pro"
  elif [[ "$cpu" == *"M2"* ]]; then
    CONV_HW_TIER="base"
  elif [[ "$cpu" == *"M1 Ultra"* ]]; then
    CONV_HW_TIER="ultra"
  elif [[ "$cpu" == *"M1 Max"* ]]; then
    CONV_HW_TIER="max"
  elif [[ "$cpu" == *"M1 Pro"* ]]; then
    CONV_HW_TIER="pro"
  elif [[ "$cpu" == *"M1"* ]]; then
    CONV_HW_TIER="base"
  else
    CONV_HW_TIER="intel"
  fi

  case "$CONV_HW_TIER" in
    ultra) CONV_H264_BITRATE="20M"; CONV_H265_BITRATE="12M"; CONV_AV1_SPEED="4" ;;
    max)   CONV_H264_BITRATE="15M"; CONV_H265_BITRATE="8M";  CONV_AV1_SPEED="5" ;;
    pro)   CONV_H264_BITRATE="10M"; CONV_H265_BITRATE="6M";  CONV_AV1_SPEED="6" ;;
    base)  CONV_H264_BITRATE="8M";  CONV_H265_BITRATE="4M";  CONV_AV1_SPEED="7" ;;
    intel) CONV_H264_BITRATE="6M";  CONV_H265_BITRATE="3M";  CONV_AV1_SPEED="8" ;;
  esac
}

conv_info() {
  _conv_hw_detect
  local cpu
  cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
  local mem_bytes
  mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
  local mem_gb=$(( mem_bytes / 1073741824 ))

  printf "┌─────────────────────────────────────┐\n"
  printf "│       Hardware Profile               │\n"
  printf "├─────────────────────────────────────┤\n"
  printf "│ CPU   : %-28s │\n" "$cpu"
  printf "│ Tier  : %-28s │\n" "$CONV_HW_TIER"
  printf "│ RAM   : %-25s GB │\n" "$mem_gb"
  printf "│ RAM Tier: %-26s │\n" "$CONV_RAM_TIER"
  printf "│ Cores : %-28s │\n" "$CONV_CORES"
  printf "├─────────────────────────────────────┤\n"
  printf "│ H264 Bitrate : %-21s │\n" "$CONV_H264_BITRATE"
  printf "│ H265 Bitrate : %-21s │\n" "$CONV_H265_BITRATE"
  printf "│ AV1 Speed    : %-21s │\n" "$CONV_AV1_SPEED"
  printf "└─────────────────────────────────────┘\n"
}

_conv_hw_detect
