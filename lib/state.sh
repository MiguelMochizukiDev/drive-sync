#!/usr/bin/env bash
#
# state.sh — Persistent state with file locking
#
# Manages drive_sync state stored as JSON. Uses flock for concurrent-run safety.
#
# State schema (state.json):
#   last_sync: ISO 8601 timestamp of last successful sync, or null
#   last_compression: ISO 8601 timestamp of last compression run, or null
#   sync_status: "idle" | "success" | "failed"
#   rate_limit_recoveries: integer, number of rate limit recoveries
#   last_rate_limit: ISO 8601 timestamp of last rate limit, or null
#   total_files_synced: cumulative
#   total_bytes_synced: cumulative

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
    echo "This script should be sourced, not executed directly" >&2
    exit 1
}

acquire_lock() {
    local lock_file="$1"

    touch "$lock_file" 2>/dev/null || {
        echo "[ERROR] Cannot create lock file: $lock_file" >&2
        return 1
    }

    exec 200>"$lock_file"
    if ! flock -w 10 200; then
        echo "[ERROR] Failed to acquire state lock after 10 seconds" >&2
        return 1
    fi
    return 0
}

release_lock() {
    flock -u 200 2>/dev/null || true
    exec 200>&- 2>/dev/null || true
}

init_state() {
    local state_file="$1"
    local lock_file="$2"
    local state_dir
    state_dir=$(dirname "$state_file")

    mkdir -p "$state_dir"

    [[ -f "$state_file" ]] && return 0

    if ! acquire_lock "$lock_file"; then
        echo "[ERROR] Failed to acquire lock for state initialization" >&2
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "[ERROR] jq is required for state management" >&2
        release_lock
        exit 1
    fi

    jq -n '{
        "last_sync": null,
        "last_compression": null,
        "sync_status": "idle",
        "rate_limit_recoveries": 0,
        "last_rate_limit": null,
        "total_files_synced": 0,
        "total_bytes_synced": 0
    }' > "$state_file"

    release_lock
}

update_state() {
    local state_file="$1"
    local lock_file="$2"
    local key="$3"
    local value="$4"

    if ! acquire_lock "$lock_file"; then
        echo "[ERROR] Failed to acquire lock for state update" >&2
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "[ERROR] jq is required for state management" >&2
        release_lock
        return 1
    fi

    local tmp_file="${state_file}.tmp.$$"

    if ! jq --arg key "$key" --arg value "$value" \
           '.[$key] = $value' "$state_file" > "$tmp_file" 2>/dev/null; then
        echo "[ERROR] Failed to update state with jq" >&2
        rm -f "$tmp_file"
        release_lock
        return 1
    fi

    if ! mv "$tmp_file" "$state_file"; then
        echo "[ERROR] Failed to move updated state file" >&2
        rm -f "$tmp_file"
        release_lock
        return 1
    fi

    release_lock
    return 0
}

get_state_value() {
    local state_file="$1"
    local key="$2"

    command -v jq &> /dev/null || { echo "null"; return 1; }

    jq -r --arg key "$key" '.[$key] // "null"' "$state_file" 2>/dev/null
}
