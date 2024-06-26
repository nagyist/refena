import 'dart:async';

import 'package:meta/meta.dart';
import 'package:refena/src/accessor.dart';
import 'package:refena/src/action/dispatcher.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/listener.dart';
import 'package:refena/src/notifier/notifier_event.dart';
import 'package:refena/src/notifier/rebuildable.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/provider_accessor.dart';
import 'package:refena/src/provider/types/async_notifier_provider.dart';
import 'package:refena/src/provider/types/future_provider.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/provider/types/stream_provider.dart';
import 'package:refena/src/provider/types/view_provider.dart';
import 'package:refena/src/provider/watchable.dart';

/// A [Ref] is used to access the state of providers.
/// It lives as long as the [RefenaContainer] lives since it is
/// just a proxy to access the state.
///
/// To access low-level methods, you can use [Ref.container].
///
/// {@category Introduction}
abstract interface class Ref {
  /// Get the current value of a provider without listening to changes.
  R read<N extends BaseNotifier<T>, T, R>(BaseWatchable<N, T, R> watchable);

  /// Similar to [Ref.read], but instead of returning the state right away,
  /// it returns a [StateAccessor] to get the state later.
  ///
  /// This is useful if you need to use the latest state of a provider,
  /// but you can't use [Ref.watch] when building a notifier.
  StateAccessor<R> accessor<R>(
    BaseWatchable<BaseNotifier, dynamic, R> provider,
  );

  /// Get the notifier of a provider.
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider);

  /// Get a proxy class to dispatch actions to a [ReduxNotifier].
  Dispatcher<N, T> redux<N extends ReduxNotifier<T>, T>(
    ReduxProvider<N, T> provider,
  );

  /// Listen for changes to a provider.
  ///
  /// Do not call this method during build as you
  /// will create a new listener every time.
  ///
  /// You need to dispose the subscription manually.
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    ProviderAccessor<BaseProvider<N, T>, N, T> provider,
  );

  /// Get the [Future] of an [AsyncNotifierProvider], [FutureProvider] or
  /// [StreamProvider].
  Future<T> future<N extends GetFutureNotifier<T>, T>(
    ProviderAccessor<BaseProvider<N, AsyncValue<T>>, N, AsyncValue<T>> provider,
  );

  /// Rebuilds a rebuildable provider (e.g. [ViewProvider], [FutureProvider])
  /// and returns the result of the builder function.
  ///
  /// Remember:
  /// Rebuildable providers allow you to watch other providers
  /// within the builder function.
  ///
  /// This is **NOT** the same as calling [Ref.dispose] and then [Ref.read].
  /// In this case the notifier is disposed and listeners won't be notified.
  R rebuild<N extends RebuildableNotifier<T, R>, T, R>(
    RebuildableProvider<N, T, R> provider,
  );

  /// Disposes a [provider].
  /// Be aware that streams (ref.stream) are closed also.
  /// You may call this method in the dispose method of a stateful widget.
  /// Calling this method multiple times has no effect.
  /// Note: The [provider] will be initialized again on next access.
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider);

  /// Disposes the [param] of a family [provider].
  /// While the ordinary [dispose] method disposes the whole provider,
  /// this method only disposes the [param].
  /// Calling this method multiple times has no effect.
  void disposeFamilyParam<N extends FamilyNotifier<dynamic, P, dynamic>, P>(
    BaseProvider<N, dynamic> provider,
    P param,
  );

  /// Emits a message to the observer.
  /// This might be handy if you use [RefenaTracingPage].
  void message(String message);

  /// Returns the backing container.
  /// The container exposes more advanced methods for edge cases.
  RefenaContainer get container;

  /// Returns the owner of this [Ref].
  /// Usually, this is a notifier or a widget.
  /// Used by [Ref.redux] to log the origin of the action.
  String get debugOwnerLabel;
}

/// This type of [Ref] available in the build method of rebuildable providers.
/// In Flutter, it is available as [BuildContext.ref]
/// or with the [Refena] mixin.
///
/// Similarly to the original [Ref],
/// a [WatchableRef] lives as long as the [RefenaContainer] lives.
/// If the [Rebuildable] (e.g. Widget) is disposed,
/// then [WatchableRef.watch] has no effect except returning the current state.
abstract interface class WatchableRef implements Ref {
  /// Get the current value of a provider and listen to changes.
  /// The listener will be disposed automatically when the widget is disposed.
  ///
  /// Optionally, you can pass a [rebuildWhen] function to control when the
  /// widget should rebuild.
  ///
  /// Instead of `ref.watch(provider)`, you can also
  /// use `ref.watch(provider.select((state) => state.attribute))` to
  /// select a part of the state and only rebuild when this part changes.
  ///
  /// Do NOT execute this method multiple times as only the last one
  /// will be used for the rebuild condition.
  /// Instead, you should use *Records* to combine multiple values:
  /// final (a, b) = ref.watch(provider.select((state) => (state.a, state.b)));
  ///
  /// Only call this method during build or inside a [ViewProvider].
  R watch<N extends BaseNotifier<T>, T, R>(
    BaseWatchable<N, T, R> watchable, {
    ListenerCallback<T>? listener,
    bool Function(T prev, T next)? rebuildWhen,
  });
}

/// The actual implementation of [WatchableRef].
/// This decoupling is used to discourage access to [rebuildable]
/// and [trackNotifier].
@internal
class WatchableRefImpl implements WatchableRef {
  WatchableRefImpl({
    required RefenaContainer container,
    required this.rebuildable,
  }) : _ref = container;

  /// The backing container.
  final RefenaContainer _ref;

  /// The owner of this [Ref].
  /// It will be rebuilt when a watched provider changes.
  final Rebuildable rebuildable;

  /// Used by ViewModelBuilder to initialize the BuildContext.
  void Function(BaseProvider, BaseNotifier)? onInitNotifier;

  @override
  R read<N extends BaseNotifier<T>, T, R>(BaseWatchable<N, T, R> watchable) {
    if (_onAccessNotifier == null) {
      return _ref.read<N, T, R>(watchable, onInitNotifier);
    }

    final notifier = _ref.anyNotifier<N, T>(watchable.provider, onInitNotifier);
    _onAccessNotifier!(notifier);
    return _ref.read<N, T, R>(watchable, onInitNotifier);
  }

  @override
  StateAccessor<R> accessor<R>(
    BaseWatchable<BaseNotifier, dynamic, R> provider,
  ) {
    final notifier = _ref.anyNotifier(provider.provider, onInitNotifier);
    _onAccessNotifier?.call(notifier);
    return StateAccessor<R>(
      ref: this,
      provider: provider,
    );
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    final notifier =
        _ref.anyNotifier<N, T>(provider as BaseProvider<N, T>, onInitNotifier);
    _onAccessNotifier?.call(notifier);
    return notifier;
  }

  @override
  Dispatcher<N, T> redux<N extends ReduxNotifier<T>, T>(
    ReduxProvider<N, T> provider,
  ) {
    final notifier = _ref.anyNotifier(provider, onInitNotifier);
    _onAccessNotifier?.call(notifier);
    return Dispatcher(
      notifier: notifier,
      debugOrigin: debugOwnerLabel,
      debugOriginRef: rebuildable,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    ProviderAccessor<BaseProvider<N, T>, N, T> provider,
  ) {
    if (_onAccessNotifier == null) {
      return _ref.stream<N, T>(provider, onInitNotifier);
    }

    final notifier = _ref.anyNotifier(provider.provider, onInitNotifier);
    _onAccessNotifier!(notifier);
    if (notifier is N) {
      return notifier.getStream();
    }

    // The given provider was a family provider.
    // Access the child provider and return its future.
    final actualProvider = provider.getActualProvider(notifier);
    return _ref.anyNotifier(actualProvider).getStream();
  }

  @override
  Future<T> future<N extends GetFutureNotifier<T>, T>(
    ProviderAccessor<BaseProvider<N, AsyncValue<T>>, N, AsyncValue<T>> provider,
  ) {
    if (_onAccessNotifier == null) {
      return _ref.future<N, T>(provider, onInitNotifier);
    }

    final notifier = _ref.anyNotifier(provider.provider, onInitNotifier);
    _onAccessNotifier!(notifier);
    if (notifier is N) {
      return notifier.future;
    }

    // The given provider was a family provider.
    // Access the child provider and return its future.
    final actualProvider = provider.getActualProvider(notifier);
    return _ref.anyNotifier(actualProvider).future;
  }

  @override
  R rebuild<N extends RebuildableNotifier<T, R>, T, R>(
    RebuildableProvider<N, T, R> provider,
  ) {
    return _ref.rebuild(provider, rebuildable);
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _ref.internalDispose<N, T>(provider, rebuildable);
  }

  @override
  void disposeFamilyParam<N extends FamilyNotifier<dynamic, P, dynamic>, P>(
    BaseProvider<N, dynamic> provider,
    P param,
  ) {
    final notifier = _ref.anyNotifier<N, dynamic>(provider);
    notifier.disposeParam(param, rebuildable);
  }

  @override
  void message(String message) {
    _ref.observer?.dispatchEvent(MessageEvent(message, rebuildable));
  }

  @override
  RefenaContainer get container => _ref;

  @override
  R watch<N extends BaseNotifier<T>, T, R>(
    BaseWatchable<N, T, R> watchable, {
    ListenerCallback<T>? listener,
    bool Function(T prev, T next)? rebuildWhen,
  }) {
    final notifier = _ref.anyNotifier(watchable.provider, onInitNotifier);

    if (!rebuildable.disposed) {
      // We need to add a listener to the notifier
      // to rebuild the widget when the state changes.
      if (watchable is SelectedWatchable<N, T, R> ||
          watchable is FamilySelectedWatchable) {
        if (watchable is FamilySelectedWatchable) {
          // initialize parameter
          final familyNotifier = notifier as FamilyNotifier;
          final param = (watchable as FamilySelectedWatchable).param;
          if (!familyNotifier.isParamInitialized(param)) {
            familyNotifier.initParam(param);
          }
        }
        notifier.addListener(
          rebuildable,
          ListenerConfig<T>(
            callback: listener,
            rebuildWhen: (prev, next) {
              if (rebuildWhen?.call(prev, next) == false) {
                return false;
              }
              return watchable.getSelectedState(notifier, prev) !=
                  watchable.getSelectedState(notifier, next);
            },
          ),
        );
      } else {
        notifier.addListener(
          rebuildable,
          ListenerConfig<T>(
            callback: listener,
            rebuildWhen: rebuildWhen,
          ),
        );
      }

      rebuildable.notifyListenerTarget(notifier);
    }

    _onAccessNotifier?.call(notifier);

    return watchable.getSelectedState(notifier, notifier.state);
  }

  @override
  String get debugOwnerLabel => rebuildable.debugLabel;

  /// This function is always called when a [BaseNotifier] is accessed.
  /// Used to determine the dependency graph.
  void Function(BaseNotifier)? _onAccessNotifier;

  /// Runs [run] and calls [onAccess] for every [BaseNotifier].
  /// Returns the result of [run].
  R trackNotifier<R>({
    required void Function(BaseNotifier) onAccess,
    required R Function() run,
  }) {
    _onAccessNotifier = onAccess;
    final result = run();
    _onAccessNotifier = null;
    return result;
  }

  void startNotifierTracking({
    required void Function(BaseNotifier) onAccess,
  }) {
    _onAccessNotifier = onAccess;
  }

  void stopNotifierTracking() {
    _onAccessNotifier = null;
  }
}
