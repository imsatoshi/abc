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

@test "validate_env fails when COMMIT_MSG is missing" {
    unset COMMIT_MSG
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"COMMIT_MSG"* ]]
}

@test "validate_env fails when COMMIT_URL is missing" {
    unset COMMIT_URL
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"COMMIT_URL"* ]]
}

@test "validate_env fails when TARGET_REPO_OWNER is missing" {
    unset TARGET_REPO_OWNER
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"TARGET_REPO_OWNER"* ]]
}

@test "validate_env fails when TARGET_REPO_NAME is missing" {
    unset TARGET_REPO_NAME
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"TARGET_REPO_NAME"* ]]
}

@test "validate_env fails when TARGET_BRANCH is missing" {
    unset TARGET_BRANCH
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"TARGET_BRANCH"* ]]
}

@test "url_encode encodes unicode characters" {
    run url_encode "测试"
    [ "$status" -eq 0 ]
    # Chinese characters are encoded as %E6%B5%8B%E8%AF%95
    [[ "$output" == *"%"* ]]
}

@test "url_encode encodes quotes" {
    run url_encode "test \"quoted\" text"
    [ "$status" -eq 0 ]
    [ "$output" = "test%20%22quoted%22%20text" ]
}

@test "url_encode encodes question mark and equals" {
    run url_encode "key=value?query"
    [ "$status" -eq 0 ]
    [ "$output" = "key%3Dvalue%3Fquery" ]
}

@test "build_body handles commit message with special characters" {
    export COMMIT_MSG="Fix bug: handle \"quotes\" & special chars"
    run build_body
    [ "$status" -eq 0 ]
    [[ "$output" == *"Fix bug: handle \"quotes\" & special chars"* ]]
}

@test "build_body handles multiline commit message" {
    export COMMIT_MSG="First line
Second line"
    run build_body
    [ "$status" -eq 0 ]
    # Should include the message as-is
    [[ "$output" == *"First line"* ]]
}

@test "build_bark_url encodes special characters in title" {
    run build_bark_url "Title with & special" "Body" "https://example.com"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Title%20with%20%26%20special"* ]]
}

@test "build_bark_url encodes URL in commit_url parameter" {
    run build_bark_url "Title" "Body" "https://github.com/test/repo?query=1"
    [ "$status" -eq 0 ]
    # The URL should be encoded in the url= parameter
    [[ "$output" == *"url=https%3A%2F%2Fgithub.com%2Ftest%2Frepo%3Fquery%3D1"* ]]
}

@test "send_notification returns HTTP status code" {
    # Save original PATH
    local old_path="$PATH"
    local mock_dir
    mock_dir=$(mktemp -d)

    # Create mock curl that returns a specific HTTP code
    cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
# Return 200 status code
echo "200"
EOF
    chmod +x "$mock_dir/curl"

    PATH="$mock_dir:$PATH"
    run send_notification "https://example.com/test"
    PATH="$old_path"
    rm -rf "$mock_dir"

    [ "$status" -eq 0 ]
    [ "$output" = "200" ]
}

@test "send_notification returns error code on failure" {
    local old_path="$PATH"
    local mock_dir
    mock_dir=$(mktemp -d)

    # Create mock curl that returns 500 error
    cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
echo "500"
EOF
    chmod +x "$mock_dir/curl"

    PATH="$mock_dir:$PATH"
    run send_notification "https://example.com/test"
    PATH="$old_path"
    rm -rf "$mock_dir"

    [ "$status" -eq 0 ]
    [ "$output" = "500" ]
}

@test "main fails when validate_env fails" {
    unset BARK_SERVER_URL
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"BARK_SERVER_URL"* ]]
}

@test "main succeeds with mocked successful curl" {
    local old_path="$PATH"
    local mock_dir
    mock_dir=$(mktemp -d)

    # Create mock curl that returns 200
    cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
echo "200"
EOF
    chmod +x "$mock_dir/curl"

    PATH="$mock_dir:$PATH"
    run main
    PATH="$old_path"
    rm -rf "$mock_dir"

    [ "$status" -eq 0 ]
    [[ "$output" == *"successfully"* ]]
}

@test "main fails when curl returns non-200" {
    local old_path="$PATH"
    local mock_dir
    mock_dir=$(mktemp -d)

    # Create mock curl that returns 500
    cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
echo "500"
EOF
    chmod +x "$mock_dir/curl"

    PATH="$mock_dir:$PATH"
    run main
    PATH="$old_path"
    rm -rf "$mock_dir"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Error"* ]]
    [[ "$output" == *"500"* ]]
}

@test "build_body handles empty SHA gracefully" {
    export LATEST_SHA=""
    run build_body
    [ "$status" -eq 0 ]
    [[ "$output" == *"Commit:"* ]]
}

@test "build_title handles special characters in repo name" {
    export TARGET_REPO_OWNER="owner-with-dashes"
    export TARGET_REPO_NAME="repo.with.dots"
    run build_title
    [ "$status" -eq 0 ]
    [ "$output" = "GitHub: owner-with-dashes/repo.with.dots Updated" ]
}

@test "url_encode handles plus sign" {
    run url_encode "a+b"
    [ "$status" -eq 0 ]
    [ "$output" = "a%2Bb" ]
}

@test "url_encode handles hash symbol" {
    run url_encode "test#anchor"
    [ "$status" -eq 0 ]
    [ "$output" = "test%23anchor" ]
}

@test "build_bark_url includes all required parameters" {
    run build_bark_url "Title" "Body" "https://example.com"
    [ "$status" -eq 0 ]
    # Check all required Bark parameters are present
    [[ "$output" == *"title="* ]]
    [[ "$output" == *"url="* ]]
    [[ "$output" == *"group=GitHubUpdates"* ]]
    [[ "$output" == *"copy=1"* ]]
    [[ "$output" == *"isArchive=1"* ]]
}

@test "validate_env fails when AUTHOR_NAME is missing" {
    unset AUTHOR_NAME
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"AUTHOR_NAME"* ]]
}
