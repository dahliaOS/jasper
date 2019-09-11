#!/usr/bin/env bash
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

readonly SCRIPT_ROOT="$(cd $(dirname ${BASH_SOURCE[0]} ) && pwd)"
readonly FUCHSIA_ROOT="${SCRIPT_ROOT}/../.."
readonly TOPAZ_ROOT="${FUCHSIA_ROOT}/topaz"
readonly BUILDTOOLS_DIR="${FUCHSIA_ROOT}/buildtools"

${BUILDTOOLS_DIR}/cipd ensure -ensure-file "${SCRIPT_ROOT}/cipd.ensure" -root ${TOPAZ_ROOT} -log-level warning
