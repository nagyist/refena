part of 'redux_action.dart';

/// TLDR:
/// This action reruns the [reduce] method whenever a watched provider changes.
///
/// This action is handy if you want to add additional properties to the state
/// but you don't want to write an extra [ViewProvider] / listener for it.
/// It reruns the [reduce] method and dispatches a [WatchUpdateAction]
/// whenever a watched provider changes.
///
/// Usually, this action is dispatched in the [initialAction]
/// of a [ReduxNotifier].
///
/// All [WatchAction]s are automatically cancelled when the [ReduxNotifier]
/// is disposed, but you can also cancel them manually by saving the result
/// of the [dispatchTakeResult] method in a variable
/// and calling [WatchActionSubscription.cancel] on it.
///
/// Similarly to [GlobalAction], this action also has access to the [Ref] so
/// be careful to not produce any unwanted side effects.
///
/// Example:
/// class MyNotifier extends ReduxNotifier<MyState> {
///   @override
///   MyState init() => MyState();
///
///   @override
///   get initialAction => MyWatchAction();
/// }
///
/// class MyWatchAction extends WatchAction<MyNotifier, MyState> {
///   @override
///   MyState reduce() {
///     final counter = ref.watch(anotherProvider);
///
///     return state.copyWith(
///       counter: counter,
///     );
///   }
/// }
///
/// {@category Redux}
abstract class WatchAction<N extends BaseReduxNotifier<T>, T>
    extends BaseReduxActionWithResult<N, T, WatchActionSubscription>
    implements Rebuildable {
  final _rebuildController = BatchedStreamController<void>();
  bool _disposed = false;

  /// Access the [Ref].
  /// This is a special ref that can watch other providers.
  late final WatchableRef ref = WatchableRefImpl(
    ref: _originalRef!.container,
    rebuildable: this,
  );

  /// The method that returns the new state.
  /// Whenever a watched provider changes, this method is called.
  T reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  T wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  (T, WatchActionSubscription) internalWrapReduce() {
    _rebuildController.stream.listen((event) {
      if (notifier.disposed) {
        _cancel();
        return;
      }

      // rebuild
      notifier.dispatch(
        WatchUpdateAction._(wrapReduce()),
        debugOrigin: debugLabel,
      );
    });
    final subscription = WatchActionSubscription(this);
    notifier.registerWatchAction(subscription);
    return (wrapReduce(), subscription);
  }

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    _rebuildController.schedule(null);
  }

  @override
  @nonVirtual
  bool get isWidget => false;

  @override
  @nonVirtual
  bool get disposed => _disposed;

  void _cancel() {
    _disposed = true;
    _rebuildController.dispose();
  }

  /// Subclasses should not override this method.
  /// It is used internally by [WatchableRef.watch].
  @override
  @nonVirtual
  bool operator ==(Object other) => super == other;

  @override
  @nonVirtual
  int get hashCode => super.hashCode;
}

/// A handle to cancel a [WatchAction].
/// Usually this is not needed as the [WatchAction] is automatically
/// cancelled when the [ReduxNotifier] is disposed.
class WatchActionSubscription {
  final WatchAction _action;

  WatchActionSubscription(this._action);

  /// Cancel the [WatchAction].
  /// It no longer rebuild the state.
  void cancel() {
    _action._cancel();
  }

  /// Whether the [WatchAction] is disposed (cancelled).
  bool get disposed => _action.disposed;
}

/// A simple action that updates the state.
final class WatchUpdateAction<N extends BaseReduxNotifier<T>, T>
    extends ReduxAction<N, T> {
  final T newState;

  WatchUpdateAction._(this.newState);

  @override
  T reduce() {
    return newState;
  }
}