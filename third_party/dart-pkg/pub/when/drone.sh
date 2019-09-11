#!/usr/bin/env bash
set -o xtrace

pub get
dart test/test_when.dart

# TODO: dartanalyzer on all libraries

# Install dart_coveralls; gather and send coverage data.
if [ "$REPO_TOKEN" ]; then
  export PATH="$PATH":"~/.pub-cache/bin"

  echo
  echo "Installing dart_coveralls"
  pub global activate dart_coveralls

  echo
  echo "Running code coverage report"
  # --debug for verbose logging
  pub global run dart_coveralls report --token $REPO_TOKEN --retry 3 test/test_when.dart
fi