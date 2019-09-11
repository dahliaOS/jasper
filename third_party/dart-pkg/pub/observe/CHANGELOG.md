#### 0.15.1

* Update to use new analyzer API

#### 0.14.0

* Update to be built on top of `package:observable`. Contains the following
  breaking changes:
  - `Observable` now lives in `package:observable` and behaves like the old
    `ChangeNotifier` did (except that it's now the base class) - with subclasses
    manually notifying listeners of changes via `notifyPropertyChange()`.
  - `ChangeNotifier` has been removed.
  - `ObservableList` has been moved to `package:observable`.
  - `ObservableMap` has been moved to `package:observable`.
  - `toObservable()` has been moved to `package:observable`.
  - `Observable` (the one with dirty checking) in `package:observe` has been
    renamed `AutoObservable`

#### 0.13.5

* Fixed strong mode errors and warnings

#### 0.13.4

* Fixed strong mode errors and warnings

#### 0.13.3+1

* Add support for code_transformers `0.4.x`.

#### 0.13.3

* Update to the `test` package.

#### 0.13.2

* Update to analyzer '^0.27.0'.

#### 0.13.1+3

 * Sorting an already sorted list will no longer yield new change notifications.

#### 0.13.1+2

 * Update to analyzer '<0.27.0'

#### 0.13.1+1

 * Update to logging `<0.12.0`.

#### 0.13.1

 * Update to analyzer `<0.26.0`.

#### 0.13.0+2
  * Fixed `close` in `PathObserver` so it doesn't leak observers.
  * Ported the benchmarks from
    [observe-js](https://github.com/Polymer/observe-js/tree/master/benchmark).

#### 0.13.0+1
  * Widen the constraint on analyzer.

#### 0.13.0
  * Don't output log files by default in release mode, and provide option to
    turn them off entirely.
  * Changed the api for the ObserveTransformer to use named arguments.

#### 0.12.2+1
  * Cleanup some method signatures.

#### 0.12.2
  * Updated to match release 0.5.1
    [observe-js#d530515](https://github.com/Polymer/observe-js/commit/d530515).

#### 0.12.1+1
  * Expand stack_trace version constraint.

#### 0.12.1
  * Upgraded error messages to have a unique and stable identifier.

#### 0.12.0
  * Old transform.dart file removed. If you weren't use it it, this change is
    backwards compatible with version 0.11.0.

#### 0.11.0+5
  * Widen the constraint on analyzer.

#### 0.11.0+4
  * Raise the lower bound on the source_maps constraint to exclude incompatible
    versions.

#### 0.11.0+3
  * Widen the constraint on source_maps.

#### 0.11.0+2
  * Widen the constraint on barback.

#### 0.11.0+1
  * Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan`
    class.

#### 0.11.0
  * Updated to match [observe-js#e212e74][e212e74] (release 0.3.4), which also
    matches [observe-js#fa70c37][fa70c37] (release 0.4.2).
  * ListPathObserver has been deprecated  (it was deleted a while ago in
    observe-js). We plan to delete it in a future release. You may copy the code
    if you still need it.
  * PropertyPath now uses an expression syntax including indexers. For example,
    you can write `a.b["m"]` instead of `a.b.m`.
  * **breaking change**: PropertyPath no longer allows numbers as fields, you
    need to use indexers instead. For example, you now need to write `a[3].d`
    instead of `a.3.d`.
  * **breaking change**: PathObserver.value= no longer discards changes (this is
    in combination with a change in template_binding and polymer to improve
    interop with JS custom elements).

#### 0.10.0+3
  * minor changes to documentation, deprecated `discardListChages` in favor of
    `discardListChanges` (the former had a typo).

#### 0.10.0
  * package:observe no longer declares @MirrorsUsed. The package uses mirrors
    for development time, but assumes frameworks (like polymer) and apps that
    use it directly will either generate code that replaces the use of mirrors,
    or add the @MirrorsUsed declaration themselves. For convinience, you can
    import 'package:observe/mirrors_used.dart', and that will add a @MirrorsUsed
    annotation that preserves properties and classes labeled with @reflectable
    and properties labeled with @observable.
  * Updated to match [observe-js#0152d54][0152d54]

[fa70c37]: https://github.com/Polymer/observe-js/blob/fa70c37099026225876f7c7a26bdee7c48129f1c/src/observe.js
[0152d54]: https://github.com/Polymer/observe-js/blob/0152d542350239563d0f2cad39d22d3254bd6c2a/src/observe.js
[e212e74]: https://github.com/Polymer/observe-js/blob/e212e7473962067c099a3d1859595c2f8baa36d7/src/observe.js
