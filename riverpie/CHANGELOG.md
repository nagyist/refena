## 0.11.0

- feat: add `toString` implementations to `AsyncValue`

## 0.10.0

- **BREAKING**: use `riverpie_flutter` for Flutter projects
- **BREAKING**: change `AsyncSnapshot` to `AsyncValue` to decouple from Flutter

## 0.9.0

- feat: add `AsyncNotifierProvider` and the corresponding `AsyncNotifier`
- feat: add `ref.future` to access the `Future` of an `AsyncNotifierProvider` or a `FutureProvider`
- feat: add `ref.watchWithPrev` to access the previous value of an `AsyncNotifierProvider`

## 0.8.0

- feat: add `context.ref` to also access `ref` inside `StatelessWidget`
- feat: add `RiverpieMultiObserver` to use multiple observers at once

## 0.7.0

- feat: add `ViewProvider`, the only provider that can watch other providers
- feat: add `initialProviders` parameter for `RiverpieScope`
- feat: add `exclude` parameter for `RiverpieDebugObserver`
- **BREAKING**: `setState` of `StateProvider` accepts a builder instead of a value

## 0.6.0

- feat: add `RiverpieObserver` and `RiverpieDebugObserver`
- feat: add `StateProvider` for simple use cases
- **BREAKING**: add `ref` parameter for `ensureRef` callback

## 0.5.1

- fix: lint fixes

## 0.5.0

- feat: `RiverpieScope.defaultRef` for global access to `ref`
- feat: `ref.stream` for manual stream access
- feat: `ref.watch(myProvider, rebuildWhen: (prev, next) => ...)` for more control over when to rebuild
- feat: use `ensureRef` within `initState` for `ref` access within initialization logic
- **BREAKING**: removed `ref.listen`, use `ref.watch(myProvider, listener: (prev, next) => ...)` instead

## 0.4.0

- **BREAKING**: `Consumer` does not have a `child` anymore, use `ExpensiveConsumer` instead

## 0.3.0

- feat: add `FutureProvider`

## 0.2.0

- feat: introduction of `PureNotifier`, a `Notifier` without access to `ref`
- **BREAKING**: add `ref` as parameter to every provider
- **BREAKING**: change `ref.notify` to `ref.notifier`

## 0.1.1

- docs: update README.md

## 0.1.0

- Initial release