#!/usr/bin/env bats
#
# Unit tests for find_recent_commits.sh
#

setup() {
    # Load the script to test
    source "$BATS_TEST_DIRNAME/../scripts/find_recent_commits.sh"
}

teardown() {
    unset COMMIT_TIME HOURS_THRESHOLD GITHUB_OUTPUT
}

@test "validate_env succeeds with all required variables set" {
    export COMMIT_TIME="2024-01-15T10:00:00Z"
    export HOURS_THRESHOLD="6"
    run validate_env
    [ "$status" -eq 0 ]
}

@test "validate_env fails when COMMIT_TIME is missing" {
    export HOURS_THRESHOLD="6"
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"COMMIT_TIME"* ]]
}

@test "validate_env fails when HOURS_THRESHOLD is missing" {
    export COMMIT_TIME="2024-01-15T10:00:00Z"
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"HOURS_THRESHOLD"* ]]
}

@test "should_notify returns true when within threshold" {
    run should_notify 3 6
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "should_notify returns true when exactly at threshold" {
    run should_notify 6 6
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "should_notify returns false when exceeding threshold" {
    run should_notify 7 6
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "should_notify returns true when hours_diff is 0" {
    run should_notify 0 6
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "should_notify returns false with large difference" {
    run should_notify 100 6
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "output_result writes to stdout when GITHUB_OUTPUT is not set" {
    unset GITHUB_OUTPUT
    run output_result "should_notify" "true"
    [ "$status" -eq 0 ]
    [ "$output" = "should_notify=true" ]
}

@test "output_result writes to file when GITHUB_OUTPUT is set" {
    export GITHUB_OUTPUT=$(mktemp)
    output_result "hours_diff" "5"
    [ "$(cat $GITHUB_OUTPUT)" = "hours_diff=5" ]
    rm -f "$GITHUB_OUTPUT"
}

@test "calculate_hours_diff returns small value for very recent timestamp" {
    # Skip this test on systems without GNU date or BSD date
    if ! date -d "2024-01-15T10:00:00Z" +%s >/dev/null 2>&1 && \
       ! date -j -f "%Y-%m-%dT%H:%M:%SZ" "2024-01-15T10:00:00Z" +%s >/dev/null 2>&1; then
        skip "System doesn't support required date format parsing"
    fi

    # Get current time in ISO format
    local now
    now=$(date -u "+%Y-%m-%dT%H:%M:%SZ")

    run calculate_hours_diff "$now"
    [ "$status" -eq 0 ]
    # Verify output is a small number (0 or 1 due to rounding)
    [[ "$output" =~ ^[0-9]+$ ]]
    [ "$output" -le 1 ]
}

@test "calculate_hours_diff handles various timestamp formats" {
    # Skip this test on systems without GNU date or BSD date
    if ! date -d "2024-01-15T10:00:00Z" +%s >/dev/null 2>&1 && \
       ! date -j -f "%Y-%m-%dT%H:%M:%SZ" "2024-01-15T10:00:00Z" +%s >/dev/null 2>&1; then
        skip "System doesn't support required date format parsing"
    fi

    local past_time="2024-01-15T10:00:00Z"
    run calculate_hours_diff "$past_time"
    [ "$status" -eq 0 ]
    # Just verify it returns a number
    [[ "$output" =~ ^[0-9]+$ ]]
}
