# Shared Task Notes - Unit Test Coverage

## Current Status
Tests passing: 98/98

## Coverage Summary
All functions in the extracted scripts now have test coverage:
- `find_recent_commits.sh`: validate_env, calculate_hours_diff (success + error), should_notify, output_result, main
- `get_commits.sh`: validate_env, output_result, parse_commits, get_commits (mocked curl), main
- `send_bark_notification.sh`: validate_env, build_title, build_body, url_encode, build_bark_url, send_notification (mocked curl), main (success + failure)
- `print_summary.sh`: validate_env, build_header, build_repo_info, build_commit_info, build_notification_status, build_no_commits_message, print_summary, main

## Remaining Coverage Gaps
1. **Workflow doesn't call extracted scripts** - The workflow `.github/workflows/bark_notify_external_repo.yml` still has inline bash that duplicates the extracted scripts. To complete coverage, update the workflow to call the scripts.

2. **Edge case for get_commits()** - The `since_time` calculation failure path when both GNU and BSD date fail is not tested (requires mocking all date commands).

## Running Tests
```bash
./scripts/run_tests.sh
```

Requires: `bats-core` and `jq`
- macOS: `brew install bats-core jq`
- Linux: `apt-get install bats jq`
