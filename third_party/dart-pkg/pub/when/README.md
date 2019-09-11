when [![pub package](http://img.shields.io/pub/v/when.svg)](https://pub.dartlang.org/packages/when) [![Build Status](https://drone.io/github.com/seaneagan/when.dart/status.png)](https://drone.io/github.com/seaneagan/when.dart/latest) [![Coverage Status](https://img.shields.io/coveralls/seaneagan/when.dart.svg)](https://coveralls.io/r/seaneagan/when.dart?branch=master)
====

It's often useful to provide sync (convenient) and async (concurrent) versions 
of the same API.  `dart:io` does this with many APIs including [Process.run][] 
and [Process.runSync][].  Since the sync and async versions do the same thing, 
much of the logic is the same, with just a few small bits differing in their 
sync vs. async implementation.

The `when` function allows for registering `onSuccess`, `onError`, and 
`onComplete` callbacks on another callback which represents that sync/async 
dependent part of the API.  If the callback is sync (returns a non-`Future` or 
throws), then the other callbacks are invoked synchronously, otherwise the 
other callbacks are registered on the returned `Future`.

For example, here's how it can be used to implement sync and async APIs for
reading a JSON data structure from the file system with file absence handling:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:when/when.dart';

/// Reads and decodes JSON from [path] asynchronously.
///
/// If [path] does not exist, returns the result of calling [onAbsent].
Future readJsonFile(String path, {onAbsent()}) => _readJsonFile(
    path, onAbsent, (file) => file.exists(), (file) => file.readAsString());

/// Reads and decodes JSON from [path] synchronously.
///
/// If [path] does not exist, returns the result of calling [onAbsent].
readJsonFileSync(String path, {onAbsent()}) => _readJsonFile(
    path, onAbsent, (file) => file.existsSync(),
    (file) => file.readAsStringSync());

_readJsonFile(String path, onAbsent(), exists(File file), read(File file)) {
  var file = new File(path);
  return when(
      () => exists(file),
      onSuccess: (doesExist) => doesExist ?
          when(() => read(file), onSuccess: json.decode) :
          onAbsent());
}

main() {
  var syncJson = readJsonFileSync('foo.json', onAbsent: () => {'foo': 'bar'});
  print('Sync json: $syncJson');
  readJsonFile('foo.json', onAbsent: () => {'foo': 'bar'}).then((asyncJson) {
    print('Async json: $asyncJson');
  });
}
```

[Process.run]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart:io.Process#id_run
[Process.runSync]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart:io.Process#id_runSync
