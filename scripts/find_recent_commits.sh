#!/bin/bash
#
# Check if the most recent commit is within the time threshold
# This script is extracted from the GitHub Actions workflow for testability
#
# Required environment variables:
#   COMMIT_TIME - ISO 8601 timestamp of the commit
#   HOURS_THRESHOLD - Number of hours to check (e.g., 6)
#
# Outputs (written to GITHUB_OUTPUT if set, otherwise stdout):
#   should_notify - true/false
#   hours_diff - Number of hours since commit

set -e

# Calculate hours difference between commit time and now
calculate_hours_diff() {
    local commit_time="$1"

    # Parse commit timestamp - try GNU date first, then BSD date
    # Timestamps are in UTC, so we need to parse them as UTC
    local commit_timestamp=""

    # Try GNU date (Linux) - the -d option automatically handles 'Z' suffix as UTC
    if command -v gdate &>/dev/null; then
        commit_timestamp=$(gdate -d "$commit_time" +%s 2>/dev/null)
    fi

    # Try GNU date syntax on native date command
    if [ -z "$commit_timestamp" ]; then
        commit_timestamp=$(date -d "$commit_time" +%s 2>/dev/null)
    fi

    # Try BSD date (macOS) - need to set TZ=UTC since -j parses in local time
    if [ -z "$commit_timestamp" ]; then
        commit_timestamp=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$commit_time" +%s 2>/dev/null)
    fi

    if [ -z "$commit_timestamp" ]; then
        echo "Error: Failed to parse commit time: $commit_time" >&2
        return 1
    fi

    local current_timestamp
    current_timestamp=$(date +%s)

    local hours_diff
    hours_diff=$(( (current_timestamp - commit_timestamp) / 3600 ))

    echo "$hours_diff"
}

# Determine if notification should be sent
should_notify() {
    local hours_diff="$1"
    local threshold="$2"

    if [ "$hours_diff" -le "$threshold" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Output result - writes to GITHUB_OUTPUT if set, otherwise stdout
output_result() {
    local key="$1"
    local value="$2"

    if [ -n "$GITHUB_OUTPUT" ]; then
        echo "${key}=${value}" >> "$GITHUB_OUTPUT"
    else
        echo "${key}=${value}"
    fi
}

# Validate required environment variables
validate_env() {
    local missing=()

    [ -z "$COMMIT_TIME" ] && missing+=("COMMIT_TIME")
    [ -z "$HOURS_THRESHOLD" ] && missing+=("HOURS_THRESHOLD")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        return 1
    fi
    return 0
}

# Main function
main() {
    validate_env || exit 1

    echo "========== 检查最近提交 ==========" >&2

    local hours_diff
    hours_diff=$(calculate_hours_diff "$COMMIT_TIME") || exit 1

    echo "最近提交距离现在: $hours_diff 小时" >&2

    local notify
    notify=$(should_notify "$hours_diff" "$HOURS_THRESHOLD")

    output_result "should_notify" "$notify"
    output_result "hours_diff" "$hours_diff"

    if [ "$notify" = "true" ]; then
        echo "发现在阈值内的提交，需要发送通知" >&2
    else
        echo "没有在阈值内的提交，不需要发送通知" >&2
    fi
}

# Only run main if script is executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
