# Shared Task Notes - Unit Test Coverage

## Current Status
Tests passing: 52/52

## What Was Done This Iteration
- Added 12 more unit tests for better coverage:
  - Missing validate_env cases: COMMIT_MSG, COMMIT_URL, TARGET_REPO_OWNER, TARGET_REPO_NAME, TARGET_BRANCH
  - Special character encoding: unicode, quotes, question marks, equals
  - Edge cases: multiline commit messages, special chars in title/body
- Added CI workflow `.github/workflows/test.yml` to run tests on PR/push

## Next Steps for Coverage
1. **Refactor workflow to use extracted scripts** - The workflow `.github/workflows/bark_notify_external_repo.yml` still has inline bash. Updating it to call the extracted scripts would:
   - Make the workflow easier to maintain
   - Allow all code paths to be tested

2. **Add integration tests with mocked curl** - Test `send_notification` and `get_commits` functions that make HTTP calls. Could use a mock server or stub curl.

3. **Test main() functions directly** - The main() functions are tested implicitly through the component functions, but could add explicit end-to-end tests.

## Running Tests
```bash
./scripts/run_tests.sh
```

Requires: `bats-core` and `jq`
- macOS: `brew install bats-core jq`
- Linux: `apt-get install bats jq`
