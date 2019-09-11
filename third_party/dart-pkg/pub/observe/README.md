# observe

Support for marking objects as observable, and getting notifications when those
objects are mutated.

This library is used to observe changes to [AutoObservable][] types. It also
has helpers to make implementing and using [Observable][] objects easy.

You can provide an observable object in two ways. The simplest way is to
use dirty checking to discover changes automatically:

```dart
import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // for smaller code

class Monster extends Unit with AutoObservable {
  @observable int health = 100;

  void damage(int amount) {
    print('$this takes $amount damage!');
    health -= amount;
  }

  toString() => 'Monster with $health hit points';
}

main() {
  var obj = new Monster();
  obj.changes.listen((records) {
    print('Changes to $obj were: $records');
  });
  // No changes are delivered until we check for them
  obj.damage(10);
  obj.damage(20);
  print('dirty checking!');
  Observable.dirtyCheck();
  print('done!');
}
```

**Note**: by default this package uses mirrors to access getters and setters
marked with `@reflectable`. Dart2js disables tree-shaking if there are any
uses of mirrors, unless you declare how mirrors are used (via the
[MirrorsUsed](https://api.dartlang.org/apidocs/channels/stable/#dart-mirrors.MirrorsUsed)
annotation).

As of version 0.10.0, this package doesn't declare `@MirrorsUsed`. This is
because we intend to use mirrors for development time, but assume that
frameworks and apps that use this pacakge will either generate code that
replaces the use of mirrors, or add the `@MirrorsUsed` declaration
themselves.  For convenience, you can import
`package:observe/mirrors_used.dart` as shown on the first example above.
That will add a `@MirrorsUsed` annotation that preserves properties and
classes labeled with `@reflectable` and properties labeled with
`@observable`.

If you are using the `package:observe/mirrors_used.dart` import, you can
also make use of `@reflectable` on your own classes and dart2js will
preserve all of its members for reflection.

[Tools](https://www.dartlang.org/polymer-dart/) exist to convert the first
form into the second form automatically, to get the best of both worlds.

[AutoObservable]: http://www.dartdocs.org/documentation/observe/latest/index.html#observe/observe.AutoObservable
[AutoObservable.dirtyCheck]: http://www.dartdocs.org/documentation/observe/latest/index.html#observe/observe.AutoObservable@id_dirtyCheck
