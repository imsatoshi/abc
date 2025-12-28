#!/bin/bash
#
# Get commits from target repository within the last 24 hours
# This script is extracted from the GitHub Actions workflow for testability
#
# Required environment variables:
#   GH_TOKEN - GitHub API token
#   TARGET_REPO_OWNER - Repository owner
#   TARGET_REPO_NAME - Repository name
#   TARGET_BRANCH - Branch to check
#
# Outputs (written to GITHUB_OUTPUT if set, otherwise stdout):
#   has_new_commits - true/false
#   latest_sha - SHA of the latest commit
#   commit_msg - Commit message (first line)
#   author_name - Author name
#   commit_url - URL to the commit
#   commit_time - Commit timestamp

set -e

# Validate required environment variables
validate_env() {
    local missing=()

    [ -z "$GH_TOKEN" ] && missing+=("GH_TOKEN")
    [ -z "$TARGET_REPO_OWNER" ] && missing+=("TARGET_REPO_OWNER")
    [ -z "$TARGET_REPO_NAME" ] && missing+=("TARGET_REPO_NAME")
    [ -z "$TARGET_BRANCH" ] && missing+=("TARGET_BRANCH")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        return 1
    fi
    return 0
}

# Get commits from the last 24 hours
get_commits() {
    local since_time
    since_time=$(date -u -d "24 hours ago" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                 date -u -v-24H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

    if [ -z "$since_time" ]; then
        echo "Error: Failed to calculate since_time" >&2
        return 1
    fi

    local api_url="https://api.github.com/repos/${TARGET_REPO_OWNER}/${TARGET_REPO_NAME}/commits?sha=${TARGET_BRANCH}&since=${since_time}"

    local commits
    commits=$(curl -s -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "$api_url")

    echo "$commits"
}

# Parse commits JSON and extract information
parse_commits() {
    local commits="$1"

    # Check if response is a valid array
    if ! echo "$commits" | jq -e 'type == "array"' > /dev/null 2>&1; then
        echo "Error: Invalid API response" >&2
        return 1
    fi

    local count
    count=$(echo "$commits" | jq '. | length')

    if [ "$count" -eq 0 ]; then
        output_result "has_new_commits" "false"
        return 0
    fi

    output_result "has_new_commits" "true"
    output_result "latest_sha" "$(echo "$commits" | jq -r '.[0].sha')"
    output_result "commit_msg" "$(echo "$commits" | jq -r '.[0].commit.message' | head -n 1)"
    output_result "author_name" "$(echo "$commits" | jq -r '.[0].commit.author.name')"
    output_result "commit_url" "$(echo "$commits" | jq -r '.[0].html_url')"
    output_result "commit_time" "$(echo "$commits" | jq -r '.[0].commit.author.date')"

    return 0
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

# Main function
main() {
    validate_env || exit 1

    echo "========== 获取目标仓库最近提交 ==========" >&2

    local commits
    commits=$(get_commits) || exit 1

    parse_commits "$commits" || exit 1
}

# Only run main if script is executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
