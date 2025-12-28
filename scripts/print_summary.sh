#!/bin/bash
#
# Print execution summary for the GitHub Actions workflow
# This script is extracted from the GitHub Actions workflow for testability
#
# Required environment variables:
#   TARGET_REPO_OWNER - Repository owner
#   TARGET_REPO_NAME - Repository name
#   TARGET_BRANCH - Branch name
#
# Optional environment variables:
#   HAS_NEW_COMMITS - Whether new commits were found (true/false)
#   LATEST_SHA - SHA of the latest commit
#   COMMIT_MSG - Commit message
#   AUTHOR_NAME - Author name
#   HOURS_DIFF - Hours since commit
#   SHOULD_NOTIFY - Whether notification was sent (true/false)

set -e

# Validate required environment variables
validate_env() {
    local missing=()

    [ -z "$TARGET_REPO_OWNER" ] && missing+=("TARGET_REPO_OWNER")
    [ -z "$TARGET_REPO_NAME" ] && missing+=("TARGET_REPO_NAME")
    [ -z "$TARGET_BRANCH" ] && missing+=("TARGET_BRANCH")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        return 1
    fi
    return 0
}

# Build the summary header
build_header() {
    echo "========== 执行摘要 =========="
}

# Build the repo info
build_repo_info() {
    echo "检查的仓库: ${TARGET_REPO_OWNER}/${TARGET_REPO_NAME}"
    echo "分支: ${TARGET_BRANCH}"
}

# Build the commit info (only when there are new commits)
build_commit_info() {
    echo "最新提交SHA: ${LATEST_SHA}"
    echo "提交信息: ${COMMIT_MSG}"
    echo "作者: ${AUTHOR_NAME}"
    echo "提交时间: 距离现在 ${HOURS_DIFF:-0} 小时"
    echo "是否发送通知: ${SHOULD_NOTIFY:-false}"
}

# Build the notification status message
build_notification_status() {
    if [ "$SHOULD_NOTIFY" = "true" ]; then
        echo "通知已发送"
    else
        echo "未发送通知 (提交时间超过阈值)"
    fi
}

# Build the no commits message
build_no_commits_message() {
    echo "过去24小时内没有新提交"
}

# Print the full summary
print_summary() {
    build_header
    build_repo_info

    if [ "$HAS_NEW_COMMITS" = "true" ]; then
        build_commit_info
        build_notification_status
    else
        build_no_commits_message
    fi
}

# Main function
main() {
    validate_env || exit 1
    print_summary
}

# Only run main if script is executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
