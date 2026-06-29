#!/usr/bin/env bash
#
# utils.sh — Utility functions
#
# Helpers for path validation, percentage calculation, and file size detection.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

#=============================================================================
# Path Validation
#=============================================================================

validate_path() {
    local path="$1"
    shift
    local -a allowed_paths=("$@")
    local resolved_path
    local allowed=false

    if ! resolved_path=$(readlink -f "$path" 2>/dev/null); then
        echo "[ERROR] Failed to resolve path: $path" >&2
        return 1
    fi

    for allowed_path in "${allowed_paths[@]}"; do
        if [[ "$resolved_path" == "$allowed_path"* ]]; then
            allowed=true
            break
        fi
    done

    if [[ "$allowed" != "true" ]]; then
        echo "[ERROR] Path not allowed: $resolved_path" >&2
        return 1
    fi

    echo "$resolved_path"
    return 0
}

#=============================================================================
# Math Utilities
#=============================================================================

calculate_percentage() {
    local original="$1"
    local new="$2"

    [[ $original -eq 0 ]] && { echo "0"; return; }

    if command -v bc &> /dev/null; then
        echo "scale=2; 100 * ($original - $new) / $original" | bc
    else
        echo $(( (100 * (original - new)) / original ))
    fi
}

calculate_quota_percentage() {
    local used="$1"
    local total="$2"

    [[ $total -eq 0 ]] && { echo "0"; return; }

    if command -v bc &> /dev/null; then
        echo "scale=2; $used * 100 / $total" | bc
    else
        echo $(( (used * 100) / total ))
    fi
}

#=============================================================================
# File Utilities
#=============================================================================

get_file_size() {
    local file="$1"
    local size

    if size=$(stat -c%s "$file" 2>/dev/null); then
        echo "$size"; return 0
    elif size=$(stat -f%z "$file" 2>/dev/null); then
        echo "$size"; return 0
    else
        echo "0"; return 1
    fi
}
