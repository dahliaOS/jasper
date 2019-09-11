#!/usr/bin/env bash
set -o xtrace

pub get

# TODO: Remove once https://github.com/drone/drone/issues/821 is fixed.
export PATH="$PATH":"~/.pub-cache/bin"

# Run tests.
pub global activate test_runner
test_runner -v

# TODO: dartanalyzer on all libraries

# Install dart_coveralls; gather and send coverage data.
if [ "$REPO_TOKEN" ]; then
  pub global activate dart_coveralls
  dart_coveralls report --token $REPO_TOKEN --retry 3 test/test.dart
fi
