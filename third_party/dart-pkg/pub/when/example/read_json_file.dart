library when.example.read_json_file;

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
readJsonFileSync(String path, {onAbsent()}) => _readJsonFile(path, onAbsent,
    (file) => file.existsSync(), (file) => file.readAsStringSync());

_readJsonFile(String path, onAbsent(), exists(File file), read(File file)) {
  var file = new File(path);
  return when(() => exists(file),
      onSuccess: (doesExist) => doesExist
          ? when(() => read(file), onSuccess: json.decode)
          : onAbsent());
}

main() {
  var syncJson = readJsonFileSync('foo.json', onAbsent: () => {'foo': 'bar'});
  print('Sync json: $syncJson');
  readJsonFile('foo.json', onAbsent: () => {'foo': 'bar'}).then((asyncJson) {
    print('Async json: $asyncJson');
  });
}
