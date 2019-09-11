Documentation
=============

*Document all the things!*

We try to document our work as much as possible, from public APIs to private
classes. This is to ensure all developers have an easier ramp-up with the
codebase.


## Official docs

* [How to write Dart docs](https://www.dartlang.org/effective-dart/documentation/)
* [Dart SDK](https://api.dartlang.org/)
* [Flutter API](http://docs.flutter.io/flutter/)


## Local docs

In order to locally generate and consult the documentation for our own Dart
packages, run the following commands:
```
pub global activate dhttpd  # Only needs to be run once.
make docs
dhttpd --path out/Docs/dart
```
and then navigate to [localhost:8080](http://localhost:8080).
