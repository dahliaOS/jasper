#!/bin/bash
# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Update this year as needed.
readonly YEAR="201[6-7]"

usage() {
  echo "Usage: `basename $0` <files>"
  exit 1
}

check() {
  local file="$1"
  local valid=true

  if [[ ! -f "${file}" ]]; then
    echo "* File not found: ${file}"
    valid=false
  fi

  local filetype=$(basename ${1##*.})
  local prefix
  case "${filetype}" in
    dart|fidl|js|mojom)
      prefix="// "
      ;;
    gn|py|sh|yaml)
      prefix="# "
      ;;
    *)
      echo "* Filetype not supported: ${filetype}"
      error=true
  esac

  local line1="${prefix}Copyright ${YEAR} The Fuchsia Authors. All rights reserved."
  local line2="${prefix}Use of this source code is governed by a BSD-style license that can be"
  local line3="${prefix}found in the LICENSE file."

  # If the first line starts with shebang, skip that line.
  local offset=0
  if [[ $(head -n 1 $1) = \#!* ]] ; then
    offset=1
  fi

  tail -n +$(($offset + 1)) $1 | head -n 1 | grep -q "^${line1}$" || valid=false
  tail -n +$(($offset + 2)) $1 | head -n 1 | grep -q "^${line2}$" || valid=false;
  tail -n +$(($offset + 3)) $1 | head -n 1 | grep -q "^${line3}$" || valid=false;

  if [[ $valid != true ]]; then
    echo "* Invalid copyright header: ${file}"; \
    return 1;
  fi
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
  fi

  local error=false

  for file in $@; do
    check $file
    if [[ $? -ne true ]]; then
      error=true
    fi
  done;

  if [[ $error = true ]]; then
    exit 1;
  fi
}

main "$@"
