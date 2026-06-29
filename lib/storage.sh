#!/usr/bin/env bash
#
# storage.sh — Google Drive storage quota display
#
# Displays current storage usage from Google Drive using decimal units (GB, MB, KB).
# Matches Google Drive's display convention.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

#=============================================================================
# Formatting Helpers (decimal units)
#=============================================================================

_format_size_decimal() {
    local bytes="$1"
    local unit="B"
    local value="$bytes"

    if [[ $bytes -ge 1000000000 ]]; then
        value=$(echo "scale=2; $bytes / 1000000000" | bc 2>/dev/null || echo "$((bytes / 1000000000))")
        unit="GB"
    elif [[ $bytes -ge 1000000 ]]; then
        value=$(echo "scale=2; $bytes / 1000000" | bc 2>/dev/null || echo "$((bytes / 1000000))")
        unit="MB"
    elif [[ $bytes -ge 1000 ]]; then
        value=$(echo "scale=2; $bytes / 1000" | bc 2>/dev/null || echo "$((bytes / 1000))")
        unit="KB"
    fi

    # Remove trailing zeros
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

    local quota_info
    if quota_info=$(rclone about "$remote_name" --json 2>/dev/null); then
        if command -v jq &> /dev/null; then
            local used total
            used=$(echo "$quota_info" | jq -r '.used // 0' 2>/dev/null)
            total=$(echo "$quota_info" | jq -r '.total // 0' 2>/dev/null)

            if [[ $total -gt 0 ]]; then
                local used_human total_human
                used_human=$(_format_size_decimal "$used")
                total_human=$(_format_size_decimal "$total")

                local percent
                if command -v bc &> /dev/null; then
                    percent=$(echo "scale=1; $used * 100 / $total" | bc)
                else
                    percent=$(( (used * 100) / total ))
                fi

                log_info "$log_file" "Storage: ${percent}% used (${used_human} / ${total_human})"
            fi
        fi
    else
        log_warning "$log_file" "Could not retrieve storage information"
    fi
}
