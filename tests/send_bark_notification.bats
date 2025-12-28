#!/usr/bin/env bats
#
# Unit tests for send_bark_notification.sh
#

setup() {
    # Load the script to test
    source "$BATS_TEST_DIRNAME/../scripts/send_bark_notification.sh"

    # Set up mock environment
    export BARK_SERVER_URL="https://bark.example.com"
    export BARK_DEVICE_KEY="test-device-key"
    export LATEST_SHA="abc123def456789"
    export COMMIT_MSG="Test commit message"
    export AUTHOR_NAME="Test Author"
    export COMMIT_URL="https://github.com/test/repo/commit/abc123"
    export TARGET_REPO_OWNER="test-owner"
    export TARGET_REPO_NAME="test-repo"
    export TARGET_BRANCH="main"
}

teardown() {
    unset BARK_SERVER_URL BARK_DEVICE_KEY LATEST_SHA COMMIT_MSG AUTHOR_NAME
    unset COMMIT_URL TARGET_REPO_OWNER TARGET_REPO_NAME TARGET_BRANCH GITHUB_OUTPUT
}

@test "validate_env succeeds with all required variables set" {
    run validate_env
    [ "$status" -eq 0 ]
}

@test "validate_env fails when BARK_SERVER_URL is missing" {
    unset BARK_SERVER_URL
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"BARK_SERVER_URL"* ]]
}

@test "validate_env fails when BARK_DEVICE_KEY is missing" {
    unset BARK_DEVICE_KEY
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"BARK_DEVICE_KEY"* ]]
}

@test "validate_env fails when LATEST_SHA is missing" {
    unset LATEST_SHA
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"LATEST_SHA"* ]]
}

@test "validate_env fails when multiple variables are missing" {
    unset BARK_SERVER_URL BARK_DEVICE_KEY AUTHOR_NAME
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"BARK_SERVER_URL"* ]]
    [[ "$output" == *"BARK_DEVICE_KEY"* ]]
    [[ "$output" == *"AUTHOR_NAME"* ]]
}

@test "build_title creates correct title format" {
    run build_title
    [ "$status" -eq 0 ]
    [ "$output" = "GitHub: test-owner/test-repo Updated" ]
}

@test "build_title uses environment variables" {
    export TARGET_REPO_OWNER="another-owner"
    export TARGET_REPO_NAME="another-repo"
    run build_title
    [ "$status" -eq 0 ]
    [ "$output" = "GitHub: another-owner/another-repo Updated" ]
}

@test "build_body creates correct body format" {
    run build_body
    [ "$status" -eq 0 ]
    [[ "$output" == *"Branch: main by Test Author"* ]]
    [[ "$output" == *"Commit: abc123d"* ]]
    [[ "$output" == *"Message: Test commit message"* ]]
}

@test "build_body truncates SHA to 7 characters" {
    export LATEST_SHA="1234567890abcdef"
    run build_body
    [ "$status" -eq 0 ]
    [[ "$output" == *"Commit: 1234567"* ]]
}

@test "url_encode encodes special characters" {
    run url_encode "Hello World!"
    [ "$status" -eq 0 ]
    [ "$output" = "Hello%20World%21" ]
}

@test "url_encode handles empty string" {
    run url_encode ""
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "url_encode encodes ampersand" {
    run url_encode "test&value"
    [ "$status" -eq 0 ]
    [ "$output" = "test%26value" ]
}

@test "url_encode encodes newlines" {
    run url_encode "line1
line2"
    [ "$status" -eq 0 ]
    [ "$output" = "line1%0Aline2" ]
}

@test "build_bark_url creates valid URL structure" {
    run build_bark_url "Test Title" "Test Body" "https://example.com"
    [ "$status" -eq 0 ]
    [[ "$output" == "https://bark.example.com/test-device-key/"* ]]
    [[ "$output" == *"?title="* ]]
    [[ "$output" == *"&url="* ]]
    [[ "$output" == *"&group=GitHubUpdates"* ]]
    [[ "$output" == *"&copy=1"* ]]
    [[ "$output" == *"&isArchive=1"* ]]
}

@test "build_bark_url encodes body in path" {
    run build_bark_url "Title" "Body with spaces" "https://example.com"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Body%20with%20spaces"* ]]
}
