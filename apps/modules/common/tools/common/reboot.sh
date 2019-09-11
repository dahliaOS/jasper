#!/bin/bash
# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Exit this script if one command fails.
set -e

function main() {
  echo "=== rebooting Fuchsia"

  $FUCHSIA_DIR/out/build-magenta/tools/netruncmd : "dm reboot"
}

main "$@"
