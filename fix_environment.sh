#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
MYFILE="$DIR/apps/sysui/tools/environment.sh"
sed -i 's/out\/debug-x86-64\/host_x64/lib\/flutter\/bin\/cache/' "$MYFILE"
echo 'export PATH="$HOME/.pub-cache/bin:$PATH"' >> $MYFILE
echo 'export PATH="$FUCHSIA_ROOT/lib/flutter/bin:$PATH"' >> $MYFILE
echo "Successfully fixed $MYFILE"
exit 0
