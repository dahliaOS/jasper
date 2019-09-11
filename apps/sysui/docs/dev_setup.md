Development environment
=======================

We use [Atom](https://atom.io/) and the excellent [dartlang package](https://dart-atom.github.io/dartlang/).


## Packages

Packages can be installed in the Atom settings UI or with the `apm` command:
```
apm install <package name>
```

Notable packages:
* [linter](https://atom.io/packages/linter) and
[dartlang](https://atom.io/packages/dartlang) are a must for Dart integration.
* [last-cursor-position](https://atom.io/packages/last-cursor-position) is a
nice complement to Atom's source navigation features (e.g. `Ctrl-click` to jump
to definition).


## Gotchas

* Open the settings panel with `Ctrl-,`.
* Use the Dart and Flutter SDK versions in our tree, respectively at
`$FUCHSIA_ROOT/lib/flutter/flutter/bin/cache/dart-sdk` and
`$FUCHSIA_ROOT/lib/flutter`. This ensures you are running the correct
versions.
* Atom and the various packages are having trouble with symlinks, so make sure
you start Atom from a path containing no symlink and don't include any
symlink when setting the Dart and Flutter SDK roots.
* The Dart analysis panel sometimes goes bananas when switching to a different
branch. To help it make sense of the changes in its world, restart the analysis
with `Packages > Dart > Re-analyze Sources`.
