# Shared Task Notes - Unit Test Coverage

## Current Status
Tests passing: 40/40

## What Was Done This Iteration
- Extracted 3 bash scripts from the GitHub Actions workflow for testability:
  - `scripts/get_commits.sh` - Fetches commits from GitHub API
  - `scripts/find_recent_commits.sh` - Checks if commits are within time threshold
  - `scripts/send_bark_notification.sh` - Sends notifications via Bark
- Created comprehensive bats unit tests for all extracted functions
- Fixed timezone handling issue in date parsing (BSD date requires TZ=UTC)

## Next Steps for Coverage
1. **Update workflow to use extracted scripts** - The workflow still has inline bash. Refactor `.github/workflows/bark_notify_external_repo.yml` to call the extracted scripts instead.

2. **Add integration tests** - Current tests are unit tests. Could add integration tests that mock the curl calls.

3. **Add edge case tests**:
   - `get_commits.sh`: Test API rate limiting handling, network errors
   - `send_bark_notification.sh`: Test with special characters in commit messages

4. **CI/CD setup** - Add a GitHub Actions workflow to run tests on PR/push

## Running Tests
```bash
./scripts/run_tests.sh
```

Requires: `bats-core` and `jq`
- macOS: `brew install bats-core jq`
- Linux: `apt-get install bats jq`
