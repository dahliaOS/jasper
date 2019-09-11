#!/bin/bash
# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# TODO(youngseokyoon): Make this script into the infra repo.

# Get the source file path as an argument.
if [ $# -eq 0 ] || [ ! -f "$1" ]; then
  exit 1
fi

# Update this year as needed.
YEAR="201[6-7]"

# Determine the file type.
FILETYPE=$(basename ${1##*.})
case "${FILETYPE}" in
	dart|fidl|js|mojom)
		COMMENT_PREFIX="// "
		;;
	gn|py|sh|yaml)
		COMMENT_PREFIX="# "
		;;
	*)
		echo "Filetype '${FILETYPE}' is not supported."
		exit 1
esac

LINE1="${COMMENT_PREFIX}Copyright ${YEAR} The Fuchsia Authors. All rights reserved."
LINE2="${COMMENT_PREFIX}Use of this source code is governed by a BSD-style license that can be"
LINE3="${COMMENT_PREFIX}found in the LICENSE file."

# If the first line starts with shebang, skip that line.
OFFSET=0
if [[ $(head -n 1 $1) = \#!* ]] ; then
	OFFSET=1
fi

tail -n +$(($OFFSET + 1)) $1 | head -n 1 | grep -q "^${LINE1}$" || exit 1;
tail -n +$(($OFFSET + 2)) $1 | head -n 1 | grep -q "^${LINE2}$" || exit 1;
tail -n +$(($OFFSET + 3)) $1 | head -n 1 | grep -q "^${LINE3}$" || exit 1;
