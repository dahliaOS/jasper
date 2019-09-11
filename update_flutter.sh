#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"
rm -rf lib/flutter
./install_flutter.sh
#cd apps/sysui
#source tools/environment.sh
#../../fix_flutter.sh
#../../fix_environment.sh
#cd armadillo
#flutter doctor
echo -ne '\007'
#flutter run
