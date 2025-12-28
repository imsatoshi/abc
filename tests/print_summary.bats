#!/usr/bin/env bats
#
# Unit tests for print_summary.sh
#

setup() {
    # Load the script to test
    source "$BATS_TEST_DIRNAME/../scripts/print_summary.sh"

    # Set up mock environment
    export TARGET_REPO_OWNER="test-owner"
    export TARGET_REPO_NAME="test-repo"
    export TARGET_BRANCH="main"
}

teardown() {
    unset TARGET_REPO_OWNER TARGET_REPO_NAME TARGET_BRANCH
    unset HAS_NEW_COMMITS LATEST_SHA COMMIT_MSG AUTHOR_NAME HOURS_DIFF SHOULD_NOTIFY
}

@test "validate_env succeeds with all required variables set" {
    run validate_env
    [ "$status" -eq 0 ]
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
    unset TARGET_REPO_OWNER TARGET_REPO_NAME TARGET_BRANCH
    run validate_env
    [ "$status" -eq 1 ]
    [[ "$output" == *"TARGET_REPO_OWNER"* ]]
    [[ "$output" == *"TARGET_REPO_NAME"* ]]
    [[ "$output" == *"TARGET_BRANCH"* ]]
}

@test "build_header outputs correct header" {
    run build_header
    [ "$status" -eq 0 ]
    [ "$output" = "========== 执行摘要 ==========" ]
}

@test "build_repo_info outputs repository and branch info" {
    run build_repo_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"检查的仓库: test-owner/test-repo"* ]]
    [[ "$output" == *"分支: main"* ]]
}

@test "build_repo_info handles special characters in repo name" {
    export TARGET_REPO_OWNER="owner-with-dash"
    export TARGET_REPO_NAME="repo.with.dot"
    run build_repo_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"owner-with-dash/repo.with.dot"* ]]
}

@test "build_commit_info outputs all commit details" {
    export LATEST_SHA="abc123def456"
    export COMMIT_MSG="Test commit message"
    export AUTHOR_NAME="Test Author"
    export HOURS_DIFF="2"
    export SHOULD_NOTIFY="true"

    run build_commit_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"最新提交SHA: abc123def456"* ]]
    [[ "$output" == *"提交信息: Test commit message"* ]]
    [[ "$output" == *"作者: Test Author"* ]]
    [[ "$output" == *"距离现在 2 小时"* ]]
    [[ "$output" == *"是否发送通知: true"* ]]
}

@test "build_commit_info uses default values for missing optional vars" {
    export LATEST_SHA="abc123"
    export COMMIT_MSG="Test"
    export AUTHOR_NAME="Author"
    unset HOURS_DIFF SHOULD_NOTIFY

    run build_commit_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"距离现在 0 小时"* ]]
    [[ "$output" == *"是否发送通知: false"* ]]
}

@test "build_notification_status returns sent message when SHOULD_NOTIFY is true" {
    export SHOULD_NOTIFY="true"
    run build_notification_status
    [ "$status" -eq 0 ]
    [ "$output" = "通知已发送" ]
}

@test "build_notification_status returns not sent message when SHOULD_NOTIFY is false" {
    export SHOULD_NOTIFY="false"
    run build_notification_status
    [ "$status" -eq 0 ]
    [ "$output" = "未发送通知 (提交时间超过阈值)" ]
}

@test "build_notification_status returns not sent message when SHOULD_NOTIFY is unset" {
    unset SHOULD_NOTIFY
    run build_notification_status
    [ "$status" -eq 0 ]
    [ "$output" = "未发送通知 (提交时间超过阈值)" ]
}

@test "build_no_commits_message outputs correct message" {
    run build_no_commits_message
    [ "$status" -eq 0 ]
    [ "$output" = "过去24小时内没有新提交" ]
}

@test "print_summary shows full summary with new commits" {
    export HAS_NEW_COMMITS="true"
    export LATEST_SHA="abc123"
    export COMMIT_MSG="Test commit"
    export AUTHOR_NAME="Author"
    export HOURS_DIFF="1"
    export SHOULD_NOTIFY="true"

    run print_summary
    [ "$status" -eq 0 ]
    [[ "$output" == *"执行摘要"* ]]
    [[ "$output" == *"test-owner/test-repo"* ]]
    [[ "$output" == *"abc123"* ]]
    [[ "$output" == *"Test commit"* ]]
    [[ "$output" == *"通知已发送"* ]]
}

@test "print_summary shows no commits message when HAS_NEW_COMMITS is false" {
    export HAS_NEW_COMMITS="false"

    run print_summary
    [ "$status" -eq 0 ]
    [[ "$output" == *"执行摘要"* ]]
    [[ "$output" == *"test-owner/test-repo"* ]]
    [[ "$output" == *"过去24小时内没有新提交"* ]]
}

@test "print_summary shows no commits when HAS_NEW_COMMITS is unset" {
    unset HAS_NEW_COMMITS

    run print_summary
    [ "$status" -eq 0 ]
    [[ "$output" == *"过去24小时内没有新提交"* ]]
}

@test "main fails when validate_env fails" {
    unset TARGET_REPO_OWNER
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"TARGET_REPO_OWNER"* ]]
}

@test "main succeeds with valid environment" {
    export HAS_NEW_COMMITS="false"
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"执行摘要"* ]]
}

@test "build_commit_info handles empty commit message" {
    export LATEST_SHA="abc123"
    export COMMIT_MSG=""
    export AUTHOR_NAME="Author"

    run build_commit_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"提交信息:"* ]]
}

@test "build_commit_info handles commit message with special characters" {
    export LATEST_SHA="abc123"
    export COMMIT_MSG="Fix: handle \"quotes\" & special chars"
    export AUTHOR_NAME="Author"

    run build_commit_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"Fix: handle \"quotes\" & special chars"* ]]
}

@test "build_repo_info handles different branch names" {
    export TARGET_BRANCH="feature/new-feature"
    run build_repo_info
    [ "$status" -eq 0 ]
    [[ "$output" == *"分支: feature/new-feature"* ]]
}

@test "print_summary with notification not sent" {
    export HAS_NEW_COMMITS="true"
    export LATEST_SHA="abc123"
    export COMMIT_MSG="Old commit"
    export AUTHOR_NAME="Author"
    export HOURS_DIFF="10"
    export SHOULD_NOTIFY="false"

    run print_summary
    [ "$status" -eq 0 ]
    [[ "$output" == *"未发送通知"* ]]
}
