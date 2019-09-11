#!/bin/bash
./update_flutter.sh
./fix_environment.sh
cd apps/sysui
source tools/environment.sh
cd armadillo
flutter run
exit 0
