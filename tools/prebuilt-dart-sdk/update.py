#!/usr/bin/env python
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import os
import platform
import pipes
import subprocess
import sys


SCRIPT_DIR = os.path.dirname(__file__)
FUCHSIA_ROOT = os.path.normpath(os.path.join(
    SCRIPT_DIR, os.path.pardir, os.path.pardir, os.path.pardir))
CIPD = os.path.join(FUCHSIA_ROOT, 'buildtools', 'cipd')

DEFAULT_PACKAGE = 'fuchsia/dart-sdk'
DEFAULT_CHECKOUT = os.path.join(FUCHSIA_ROOT, 'third_party', 'dart')
VERIFIED_PLATFORMS = [
    'linux-amd64',
    #'linux-arm64', TODO(mcgrathr): later
    'mac-amd64',
]

ARCH_MAP = {
    'x86_64': ('amd64', 'x64'),
    'x64': ('amd64', 'x64'),
    'aarch64': ('arm64', 'arm64'),
}
OS_MAP = { 'darwin': 'mac' }


def main():
    cipd_arch = platform.machine()
    cipd_arch, gn_arch = ARCH_MAP.get(cipd_arch, (cipd_arch, cipd_arch))
    cipd_os = platform.system().lower()
    cipd_os = OS_MAP.get(cipd_os, cipd_os)
    cipd_platform = '%s-%s' % (cipd_os, cipd_arch)
    gn_platform = '%s-%s' % (cipd_os, gn_arch)

    parser = argparse.ArgumentParser(
        add_help=True,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='''
Front-end to [cipd](https://github.com/luci/luci-go/tree/master/cipd)
for the [Fuchsia dart-sdk prebuilt](https://fuchsia.googlesource.com/infra/recipes/+/master/recipes/dart_toolchain.py).
''',
        epilog='''
Verifies the matching version exists for all platforms (%(platforms)s).
Then downloads and unpacks (if necessary) the package for
the current host platform (%(host_platform)s) into DIRECTORY.

Default for --version is `git_revision:COMMITHASH`.

Default COMMITHASH is the current `HEAD` in the CHECKOUT directory.
''' % {
    'host_platform': cipd_platform,
    'platforms': ', '.join(VERIFIED_PLATFORMS),
})
    parser.add_argument('--cipd',
                        help='CIPD binary to run',
                        metavar='FILE',
                        default=CIPD)
    parser.add_argument('--output',
                        metavar='DIRECTORY',
                        help='Where to unpack the prebuilt',
                        default=os.path.relpath(os.path.join(SCRIPT_DIR,
                                                             gn_platform)))
    parser.add_argument('--package',
                        help='CIPD package name prefix (before `/PLATFORM`)',
                        metavar='PACKAGE',
                        default=DEFAULT_PACKAGE)
    parser.add_argument('--platform',
                        help='CIPD platform name to download',
                        metavar='CIPD_PLATFORM',
                        default='${platform}')
    parser.add_argument('--checkout',
                        metavar='CHECKOUT',
                        help='Directory containing the Dart checkout',
                        default=DEFAULT_CHECKOUT)
    parser.add_argument('--revision',
                        metavar='COMMITHASH',
                        help='dart/sdk git revision of prebuilt to download')
    parser.add_argument('--root',
                        metavar='ROOTDIR',
                        help='CIPD root (parent of `.cipd` subdirectory)',
                        default=FUCHSIA_ROOT)
    parser.add_argument('--verbose',
                        action='store_true',
                        help='Show CIPD commands and use -log-level info')
    parser.add_argument('--version',
                        help='CIPD tag or ref to search for, e.g. "latest"')
    args = parser.parse_args()
    if args.version and args.revision:
        parser.usage('--version supercedes --revision; cannot use both')

    git_cmd = [ 'git', '-C', args.checkout, 'rev-parse', 'HEAD' ]
    version = args.version or ('git_revision:' + (
        args.revision or subprocess.check_output(git_cmd).strip()))

    ensure_file = ('$ParanoidMode CheckPresence\n' +
                   reduce(lambda file, platform:
                          file + ('$VerifiedPlatform %s\n' % platform),
                          VERIFIED_PLATFORMS, '') +
                   ('@Subdir %s\n' % os.path.relpath(args.output, args.root)) +
                   ('%s/%s %s\n' % (args.package, args.platform, version)))

    def cipd(verify):
        command = [args.cipd]
        if verify:
            command.append('ensure-file-verify')
        else:
            command += ['ensure', '-root', args.root]
        command += [
            '-ensure-file',
            '-',
            '-log-level',
            'info' if args.verbose else 'warning',
        ]
        if args.verbose:
            print '+ %s <<\\EOF' % ' '.join(map(pipes.quote, command))
            print ensure_file + 'EOF'
        proc = subprocess.Popen(command, stdin=subprocess.PIPE)
        proc.communicate(ensure_file)
        return proc.returncode

    return cipd(True) or cipd(False)


if __name__ == "__main__":
    sys.exit(main())
