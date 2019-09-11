# Running Armadillo Flutter tests in the Fuchsia tree

When switching between running flutter tests and building Fuchsia, you will
likely need to perform the following steps at least the first time you switch
between the two:

To run flutter tests:
1. ``cd <fuchsia_root>/<flutter app directory>``
1. ``<fuchsia_root>/lib/flutter/bin/flutter upgrade``
1. ``<fuchsia_root>/lib/flutter/bin/flutter test``

To build Fuchsia:
1. ``rm -Rf <fuchsia_root>/out/debug-x86-64/gen/``
1. ``fbuild``

This assumes you have the fbuild (which builds a debug version of Fuchsia) script function installed.
