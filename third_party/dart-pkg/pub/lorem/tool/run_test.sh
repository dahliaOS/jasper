#!/bin/bash

set -e
echo "Analyzing library for warnings or type errors"

dartanalyzer --show-package-warnings lib/lorem.dart
dart --checked test/lorem_test.dart

echo -e "\n[32m✓ OK[0m"
