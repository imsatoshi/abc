#!/usr/bin/env bats
#
# Unit tests for get_commits.sh
#

setup() {
    # Load the script to test
    source "$BATS_TEST_DIRNAME/../scripts/get_commits.sh"

    # Set up mock environment
    export GH_TOKEN="test-token"
    export TARGET_REPO_OWNER="test-owner"
    export TARGET_REPO_NAME="test-repo"
    export TARGET_BRANCH="main"
}

teardown() {
    unset GH_TOKEN TARGET_REPO_OWNER TARGET_REPO_NAME TARGET_BRANCH GITHUB_OUTPUT
}

@test "validate_env succeeds with all required variables set" {
    run validate_env
    [ "$status" -eq 0 ]
}

@test "validate_env fails when GH_TOKEN is missing" {
    unset GH_TOKEN
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"GH_TOKEN"* ]]
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

@test "validate_env lists all missing variables" {
    unset GH_TOKEN TARGET_REPO_OWNER
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"GH_TOKEN"* ]]
    [[ "$output" == *"TARGET_REPO_OWNER"* ]]
}

@test "output_result writes to stdout when GITHUB_OUTPUT is not set" {
    unset GITHUB_OUTPUT
    run output_result "test_key" "test_value"
    [ "$status" -eq 0 ]
    [ "$output" = "test_key=test_value" ]
}

@test "output_result writes to file when GITHUB_OUTPUT is set" {
    export GITHUB_OUTPUT=$(mktemp)
    output_result "test_key" "test_value"
    [ "$(cat $GITHUB_OUTPUT)" = "test_key=test_value" ]
    rm -f "$GITHUB_OUTPUT"
}

@test "parse_commits returns has_new_commits=false for empty array" {
    unset GITHUB_OUTPUT
    run parse_commits "[]"
    [ "$status" -eq 0 ]
    [ "$output" = "has_new_commits=false" ]
}

@test "parse_commits returns error for non-array response" {
    run parse_commits '{"message": "Not Found"}'
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid API response"* ]]
}

@test "parse_commits returns error for invalid JSON" {
    run parse_commits 'not valid json'
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid API response"* ]]
}

@test "parse_commits extracts commit info correctly" {
    local commits='[
        {
            "sha": "abc123def456",
            "commit": {
                "message": "Test commit message\nWith more details",
                "author": {
                    "name": "Test Author",
                    "date": "2024-01-15T10:30:00Z"
                }
            },
            "html_url": "https://github.com/test/repo/commit/abc123"
        }
    ]'

    unset GITHUB_OUTPUT
    run parse_commits "$commits"
    [ "$status" -eq 0 ]
    [[ "$output" == *"has_new_commits=true"* ]]
    [[ "$output" == *"latest_sha=abc123def456"* ]]
    [[ "$output" == *"commit_msg=Test commit message"* ]]
    [[ "$output" == *"author_name=Test Author"* ]]
    [[ "$output" == *"commit_url=https://github.com/test/repo/commit/abc123"* ]]
    [[ "$output" == *"commit_time=2024-01-15T10:30:00Z"* ]]
}

@test "parse_commits handles multiple commits and returns the first" {
    local commits='[
        {
            "sha": "first123",
            "commit": {
                "message": "First commit",
                "author": {"name": "Author1", "date": "2024-01-16T10:00:00Z"}
            },
            "html_url": "https://github.com/test/repo/commit/first"
        },
        {
            "sha": "second456",
            "commit": {
                "message": "Second commit",
                "author": {"name": "Author2", "date": "2024-01-15T10:00:00Z"}
            },
            "html_url": "https://github.com/test/repo/commit/second"
        }
    ]'

    unset GITHUB_OUTPUT
    run parse_commits "$commits"
    [ "$status" -eq 0 ]
    [[ "$output" == *"latest_sha=first123"* ]]
    [[ "$output" == *"commit_msg=First commit"* ]]
}
