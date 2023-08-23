import 'package:meta/meta.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';

/// A notifier holds a state and notifies its listeners when the state changes.
/// The listeners are added automatically when calling [ref.watch].
///
/// Be aware that notifiers are never disposed.
/// If you hold a lot of data in the state,
/// you should consider implement a "reset" logic.
///
/// This [Notifier] has access to [ref] for fast development.
abstract class Notifier<T> extends BaseSyncNotifier<T> {
  late Ref _ref;

  @protected
  Ref get ref => _ref;

  Notifier({super.debugLabel});

  @internal
  @override
  void internalSetup(RiverpieContainer container, RiverpieObserver? observer) {
    _ref = container;
    super.internalSetup(container, observer);
  }

  /// Returns a debug version of the [notifier] where
  /// you can set the state directly.
  static TestableNotifier<N, T> test<N extends BaseSyncNotifier<T>, T>({
    required N notifier,
    T? initialState,
  }) {
    return TestableNotifier(
      notifier: notifier,
      initialState: initialState,
    );
  }
}
