#!/usr/bin/env bash
#
# logging.sh — Structured logging with automatic rotation
#
# This module provides leveled logging (INFO, WARNING, ERROR, SUCCESS) with
# automatic file rotation at 10 MB. All logs include ISO 8601 timestamps.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

init_logging() {
    local log_file="$1"
    local log_dir
    log_dir=$(dirname "$log_file")

    mkdir -p "$log_dir"

    if [[ -f "$log_file" ]]; then
        local size
        size=$(wc -c < "$log_file" 2>/dev/null || echo 0)

        if [[ $size -gt 10485760 ]]; then
            for i in 4 3 2 1; do
                [[ -f "${log_file}.${i}" ]] && mv "${log_file}.${i}" "${log_file}.$((i + 1))"
            done
            mv "$log_file" "${log_file}.1"
            touch "$log_file"
        fi
    fi
}

_log_write() {
    local log_file="$1"
    local level="$2"
    shift 2
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "$log_file"
}

log_error() {
    local f="$1"
    shift
    _log_write "$f" "ERROR" "$@"
}

log_warning() {
    local f="$1"
    shift
    _log_write "$f" "WARNING" "$@"
}

log_info() {
    local f="$1"
    shift
    _log_write "$f" "INFO" "$@"
}

log_success() {
    local f="$1"
    shift
    _log_write "$f" "SUCCESS" "$@"
}
