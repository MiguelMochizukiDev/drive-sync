#!/usr/bin/env bash
#
# config.sh — Configuration constants and defaults
#
# Edit this file to customize behavior: directory paths, performance tuning,
# compression profiles, timeouts, and retry logic.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

#=============================================================================
# Directory Paths
#=============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REMOTE_NAME="drive:"
readonly DRIVE_ROOT="${HOME}/drive"
readonly LOCAL_PATH="${DRIVE_ROOT}"
readonly STATE_DIR="${DRIVE_ROOT}/.sync"
readonly LOG_DIR="${DRIVE_ROOT}/.logs"
readonly STATE_FILE="${STATE_DIR}/state.json"
readonly LOCK_FILE="${STATE_DIR}/state.lock"
readonly LOG_FILE="${LOG_DIR}/drive_sync.log"

#=============================================================================
# Rclone Performance Tuning
#=============================================================================

readonly RCLONE_TRANSFERS="2"
readonly RCLONE_CHECKERS="2"
readonly RCLONE_TPSLIMIT="8"
readonly RCLONE_TPSLIMIT_BURST="5"
readonly RCLONE_TIMEOUT="5m"
readonly RCLONE_RETRIES="3"
readonly RCLONE_DRIVE_CHUNK_SIZE="128M"

#=============================================================================
# PDF Compression
#=============================================================================

readonly OPTIMIZED_MARKER=".optimized.pdf"
readonly GHOSTSCRIPT_DEVICE="pdfwrite"
readonly MIN_VALID_COMPRESSED_SIZE=1024

#=============================================================================
# Rate Limiting and Retry
#=============================================================================

readonly RATE_LIMIT_BACKOFF_SECONDS=300
readonly MAX_RETRIES=3
readonly RETRY_DELAY=60

#=============================================================================
# Security
#=============================================================================

readonly ALLOWED_PATHS=("${DRIVE_ROOT}")

#=============================================================================
# Getters
#=============================================================================

get_remote_name()                      { echo "$REMOTE_NAME"; }
get_drive_root()                       { echo "$DRIVE_ROOT"; }
get_local_path()                       { echo "$LOCAL_PATH"; }
get_log_file()                         { echo "$LOG_FILE"; }
get_state_file()                       { echo "$STATE_FILE"; }
get_lock_file()                        { echo "$LOCK_FILE"; }
get_optimized_marker()                 { echo "$OPTIMIZED_MARKER"; }
get_allowed_paths()                    { echo "${ALLOWED_PATHS[@]}"; }
get_max_retries()                      { echo "$MAX_RETRIES"; }
get_retry_delay()                      { echo "$RETRY_DELAY"; }
get_rate_limit_backoff()               { echo "$RATE_LIMIT_BACKOFF_SECONDS"; }
get_min_valid_compressed_size()        { echo "$MIN_VALID_COMPRESSED_SIZE"; }
