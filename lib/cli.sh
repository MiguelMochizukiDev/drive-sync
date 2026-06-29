#!/usr/bin/env bash
#
# cli.sh — Command-line interface
#
# Provides help text, status display, and user-facing reset logic.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

#=============================================================================
# Help
#=============================================================================

show_help() {
    cat << 'EOF'
drive_sync v1.0.0 — Simple Google Drive sync with PDF compression

USAGE:
  drive_sync.sh [COMMAND] [OPTIONS]

COMMANDS:
  push      Upload local changes (compresses PDFs)
  pull      Download remote changes
  sync      Full sync (pull then push)
  status    Show sync status
  ratelimit Recover from rate limiting

OPTIONS:
  -n, --dry-run  Preview changes
  -f, --force    Skip confirmations
  -h, --help     Show this help
  -v, --version  Show version

EXAMPLES:
  drive_sync.sh status
  drive_sync.sh push
  drive_sync.sh sync -n
EOF
}

#=============================================================================
# Formatting Helpers
#=============================================================================

format_size_decimal() {
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

    # Remove trailing zeros if present
    if [[ "$value" =~ ^([0-9]+)\.([0-9]{1,2})?0*$ ]]; then
        value="${BASH_REMATCH[1]}"
        if [[ -n "${BASH_REMATCH[2]}" ]]; then
            value="${value}.${BASH_REMATCH[2]}"
        fi
    fi

    echo "${value} ${unit}"
}

#=============================================================================
# Status Display
#=============================================================================

show_status() {
    local log_file="$1"
    local state_file="$2"
    local remote_name="$3"
    local local_path="$4"
    local optimized_marker="$5"

    echo ""
    echo "📁 drive_sync v1.0.0"
    echo "─────────────────────────"

    echo "📂 Local: $local_path"
    echo "☁️  Remote: $remote_name"

    if [[ -f "$state_file" ]]; then
        local last_sync sync_status
        last_sync=$(get_state_value "$state_file" "last_sync" | sed 's/null/Never/')
        sync_status=$(get_state_value "$state_file" "sync_status" | sed 's/null/idle/')

        local status_icon="🟢"
        [[ "$sync_status" == "failed" ]] && status_icon="🔴"
        [[ "$sync_status" == "idle" ]] && status_icon="⏸️"

        echo "🔄 Last sync: $last_sync"
        echo "$status_icon Status: $sync_status"
    fi

    if [[ -d "$local_path" ]]; then
        local total_pdfs optimized_pdfs unoptimized_pdfs total_size
        total_pdfs=$(find "$local_path" -type f -iname "*.pdf" 2>/dev/null | wc -l)
        optimized_pdfs=$(find "$local_path" -type f -iname "*${optimized_marker}" 2>/dev/null | wc -l)
        unoptimized_pdfs=$((total_pdfs - optimized_pdfs))

        # Get total size in bytes and convert to decimal GB
        local total_bytes
        total_bytes=$(du -sb "$local_path" 2>/dev/null | cut -f1 || echo 0)
        local total_size_display
        total_size_display=$(format_size_decimal "$total_bytes")

        echo ""
        echo "📄 PDFs: $total_pdfs total"
        echo "   ✅ Optimized: $optimized_pdfs"
        echo "   ⏳ Pending: $unoptimized_pdfs"
        echo "   💾 Size: $total_size_display"

        if [[ $unoptimized_pdfs -gt 0 ]]; then
            echo ""
            echo "💡 Run: drive_sync.sh push"
        fi
    fi

    # Storage usage from Drive (in decimal units)
    local quota_info
    if quota_info=$(rclone about "$remote_name" --json 2>/dev/null); then
        if command -v jq &> /dev/null; then
            local used total
            used=$(echo "$quota_info" | jq -r '.used // 0' 2>/dev/null)
            total=$(echo "$quota_info" | jq -r '.total // 0' 2>/dev/null)

            if [[ $total -gt 0 ]]; then
                local used_display total_display
                used_display=$(format_size_decimal "$used")
                total_display=$(format_size_decimal "$total")

                local percent
                if command -v bc &> /dev/null; then
                    percent=$(echo "scale=1; $used * 100 / $total" | bc)
                else
                    percent=$(( (used * 100) / total ))
                fi

                echo ""
                echo "💾 Drive: $used_display / $total_display (${percent}%)"
            fi
        fi
    fi

    echo ""
    echo "─────────────────────────"
    echo ""
}
