This directory contains prebuilt Dart SDK packages downloaded from
[CIPD](https://github.com/luci/luci-go/tree/master/cipd).
These are built by Fuchsia [bots](https://luci-milo.appspot.com/p/fuchsia/g/dart-prebuilt/console)
using a [recipe](https://fuchsia.googlesource.com/infra/recipes/+/master/recipes/dart_toolchain.py).

The prebuilt version must match the sources in //third_party/dart exactly.
The [`update.py` script](update.py) downloads a package for the build host
that matches the current Dart revision according to `jiri project`.  It's
run automatically by the Jiri [manifest](../../manifest/minimal) but can
also be run by hand at any time.  Run it with `--help` for details.

If there is no prebuilt for your build host, then you'll have to supply your
own.  It's a normal `dart-sdk` built for the build host, but it also needs
`bin/gen_shapshot.OS-CPU` and `bin/gen_shapshot_product.OS-CPU`.  These run
on the build host but target a corresponding Dart VM built for `OS-CPU`.
The Fuchsia GN build will run those for both `$host_os-$host_cpu`
(e.g. `linux-x64`) and `$target_os-$target_cpu` (e.g. `fuchsia-arm64`).
This all must be built from Dart sources that exactly match the version in
//third_dart/dart that will be built in the Fuchsia GN build.

The GN build argument `prebuilt_dart_sdk` sets the directory where GN will
look for Dart.  Its default is the `$host_os-$host_cpu` subdirectory here,
where the [`update.py` script](update.py) unpacks it by default.  To use a
different build of Dart, just set that in `args.gn`.
