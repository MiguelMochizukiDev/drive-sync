#!/usr/bin/env bash
#
# storage.sh — Google Drive storage quota display
#
# Displays current storage usage from Google Drive.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

#=============================================================================
# Formatting Helpers
#=============================================================================

format_size() {
    local bytes="$1"
    local unit="B"
    local value="$bytes"

    if [[ $bytes -ge 1073741824 ]]; then
        if command -v bc &> /dev/null; then
            value=$(echo "scale=2; $bytes / 1073741824" | bc)
            unit="GiB"
        else
            value=$((bytes / 1073741824))
            unit="GiB"
        fi
    elif [[ $bytes -ge 1048576 ]]; then
        if command -v bc &> /dev/null; then
            value=$(echo "scale=2; $bytes / 1048576" | bc)
            unit="MiB"
        else
            value=$((bytes / 1048576))
            unit="MiB"
        fi
    elif [[ $bytes -ge 1024 ]]; then
        if command -v bc &> /dev/null; then
            value=$(echo "scale=2; $bytes / 1024" | bc)
            unit="KiB"
        else
            value=$((bytes / 1024))
            unit="KiB"
        fi
    fi

    if [[ "$value" =~ ^([0-9]+)\.([0-9]{1,2})?0*$ ]]; then
        value="${BASH_REMATCH[1]}"
        if [[ -n "${BASH_REMATCH[2]}" ]]; then
            value="${value}.${BASH_REMATCH[2]}"
        fi
    fi

    echo "${value} ${unit}"
}

#=============================================================================
# Storage Quota Display
#=============================================================================

show_storage_usage() {
    local log_file="$1"
    local remote_name="$2"

    log_info "$log_file" "Checking Google Drive storage usage..."

    local quota_json
    if quota_json=$(rclone about "$remote_name" --json 2>/dev/null); then
        if command -v jq &> /dev/null; then
            local used total
            used=$(echo "$quota_json" | jq -r '.used // 0' 2>/dev/null)
            total=$(echo "$quota_json" | jq -r '.total // 0' 2>/dev/null)

            if [[ $total -gt 0 ]]; then
                local used_human total_human
                used_human=$(format_size "$used")
                total_human=$(format_size "$total")

                local percent
                if command -v bc &> /dev/null; then
                    percent=$(echo "scale=1; $used * 100 / $total" | bc)
                else
                    percent=$(( (used * 100) / total ))
                fi

                log_info "$log_file" "Storage: ${used_human} / ${total_human} (${percent}%)"
                echo "💾 Drive: ${used_human} / ${total_human} (${percent}%)"
            fi
        fi
    else
        log_warning "$log_file" "Could not retrieve storage information"
    fi
}
