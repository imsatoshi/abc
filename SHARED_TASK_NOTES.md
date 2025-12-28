# Shared Task Notes - Unit Test Coverage

## Current Status
Tests passing: 75/75

## Coverage Summary
All functions in the extracted scripts now have test coverage:
- `find_recent_commits.sh`: validate_env, calculate_hours_diff (success + error), should_notify, output_result, main
- `get_commits.sh`: validate_env, output_result, parse_commits, get_commits (mocked curl), main
- `send_bark_notification.sh`: validate_env, build_title, build_body, url_encode, build_bark_url, send_notification (mocked curl), main (success + failure)

## Remaining Coverage Gaps
1. **GitHub workflow inline bash** - The workflow `.github/workflows/bark_notify_external_repo.yml` still has inline bash that cannot be unit tested. Consider extracting to scripts for full coverage.

2. **Edge cases for get_commits()** - The `get_commits` function's error path when `since_time` calculation fails is not tested (difficult to mock reliably).

## Running Tests
```bash
./scripts/run_tests.sh
```

Requires: `bats-core` and `jq`
- macOS: `brew install bats-core jq`
- Linux: `apt-get install bats jq`
