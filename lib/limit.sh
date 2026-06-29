#!/usr/bin/env bash
#
# limit.sh — Google Drive API rate limit detection and recovery
#
# Handles recovery from Google Drive API rate limiting (HTTP 429).
# When rclone exits with code 7 or 9, we wait for the rate limit
# to expire and then resume operations.

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

#=============================================================================
# Rate Limit Detection
#=============================================================================

is_rate_limit_error() {
    local exit_code="$1"
    [[ $exit_code -eq 7 ]] || [[ $exit_code -eq 9 ]]
}

#=============================================================================
# Rate Limit Recovery
#=============================================================================

recover_from_rate_limit() {
    local log_file="$1"
    local remote_name="$2"
    local state_file="$3"
    local lock_file="$4"
    local backoff_seconds="$5"

    log_warning "$log_file" "API rate limit detected, attempting recovery..."

    # Clean up rclone's cache files
    rclone cleanup "$remote_name" 2>/dev/null || true
    rclone cache clear "$remote_name" 2>/dev/null || true

    log_info "$log_file" "Waiting ${backoff_seconds}s for rate limit to reset..."
    sleep "$backoff_seconds"

    # Test connection with minimal API usage
    if rclone about "$remote_name" --tpslimit 1 &>/dev/null; then
        local recovery_count
        recovery_count=$(get_state_value "$state_file" "rate_limit_recoveries")
        recovery_count=${recovery_count:-0}
        recovery_count=$((recovery_count + 1))
        update_state "$state_file" "$lock_file" "rate_limit_recoveries" "$recovery_count"
        update_state "$state_file" "$lock_file" "last_rate_limit" "$(date -Iseconds)"

        log_success "$log_file" "Rate limit recovery successful (count: $recovery_count)"
        return 0
    else
        log_error "$log_file" "Rate limit recovery failed — connection still limited"
        return 1
    fi
}
