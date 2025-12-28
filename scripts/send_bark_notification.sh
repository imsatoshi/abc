#!/bin/bash
#
# Send notification via Bark push service
# This script is extracted from the GitHub Actions workflow for testability
#
# Required environment variables:
#   BARK_SERVER_URL - Bark server URL
#   BARK_DEVICE_KEY - Bark device key
#   LATEST_SHA - Commit SHA
#   COMMIT_MSG - Commit message
#   AUTHOR_NAME - Author name
#   COMMIT_URL - URL to the commit
#   TARGET_REPO_OWNER - Repository owner
#   TARGET_REPO_NAME - Repository name
#   TARGET_BRANCH - Branch name

set -e

# Validate required environment variables
validate_env() {
    local missing=()

    [ -z "$BARK_SERVER_URL" ] && missing+=("BARK_SERVER_URL")
    [ -z "$BARK_DEVICE_KEY" ] && missing+=("BARK_DEVICE_KEY")
    [ -z "$LATEST_SHA" ] && missing+=("LATEST_SHA")
    [ -z "$COMMIT_MSG" ] && missing+=("COMMIT_MSG")
    [ -z "$AUTHOR_NAME" ] && missing+=("AUTHOR_NAME")
    [ -z "$COMMIT_URL" ] && missing+=("COMMIT_URL")
    [ -z "$TARGET_REPO_OWNER" ] && missing+=("TARGET_REPO_OWNER")
    [ -z "$TARGET_REPO_NAME" ] && missing+=("TARGET_REPO_NAME")
    [ -z "$TARGET_BRANCH" ] && missing+=("TARGET_BRANCH")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        return 1
    fi
    return 0
}

# Build notification title
build_title() {
    echo "GitHub: ${TARGET_REPO_OWNER}/${TARGET_REPO_NAME} Updated"
}

# Build notification body
build_body() {
    local short_sha
    short_sha=$(echo "$LATEST_SHA" | cut -c1-7)

    echo "Branch: ${TARGET_BRANCH} by ${AUTHOR_NAME}
Commit: ${short_sha}
Message: ${COMMIT_MSG}"
}

# URL encode a string
url_encode() {
    local string="$1"
    printf %s "$string" | jq -sRr @uri
}

# Build the Bark request URL
build_bark_url() {
    local title="$1"
    local body="$2"
    local commit_url="$3"

    local title_encoded
    title_encoded=$(url_encode "$title")

    local body_encoded
    body_encoded=$(url_encode "$body")

    local url_encoded
    url_encoded=$(url_encode "$commit_url")

    local bark_url="${BARK_SERVER_URL}/${BARK_DEVICE_KEY}/${body_encoded}"
    bark_url="${bark_url}?title=${title_encoded}"
    bark_url="${bark_url}&url=${url_encoded}"
    bark_url="${bark_url}&group=GitHubUpdates"
    bark_url="${bark_url}&copy=1"
    bark_url="${bark_url}&isArchive=1"

    echo "$bark_url"
}

# Send the notification
send_notification() {
    local url="$1"

    local http_code
    http_code=$(curl -X GET "$url" -o /dev/null -s -w "%{http_code}")

    echo "$http_code"
}

# Main function
main() {
    validate_env || exit 1

    echo "发现最近更新，发送通知..." >&2

    local title
    title=$(build_title)

    local body
    body=$(build_body)

    local bark_url
    bark_url=$(build_bark_url "$title" "$body" "$COMMIT_URL")

    echo "Bark Request URL (DEBUG): ${bark_url}" >&2

    local http_code
    http_code=$(send_notification "$bark_url")

    if [ "$http_code" -eq 200 ]; then
        echo "Bark notification sent successfully (HTTP $http_code)." >&2
        return 0
    else
        echo "Error sending Bark notification (HTTP $http_code)." >&2
        return 1
    fi
}

# Only run main if script is executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
