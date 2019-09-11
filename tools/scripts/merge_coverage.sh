#!/bin/bash
# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

TARGET_FILE="coverage/lcov.info"
rm -f ${TARGET_FILE}

# These files are assumed to be under coverage/ dir of each package.
LCOV_FILES=$(find * -name "lcov.info")

mkdir -p $(dirname ${TARGET_FILE})
touch ${TARGET_FILE}

# Read each "lcov.info" file, prepend the correct relative paths to all the
# source file names that appears in it, and then add the whole file to the
# target file.
for LCOV_FILE in ${LCOV_FILES}; do
	prefix=$(dirname $(dirname ${LCOV_FILE}) | sed 's/\//\\\//g')
	sed "s/SF:/SF:${prefix}\\//g" ${LCOV_FILE} >> ${TARGET_FILE}
done
