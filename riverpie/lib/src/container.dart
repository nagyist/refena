import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/ref.dart';

/// The [RiverpieContainer] holds the state of all providers.
/// Every provider state is initialized lazily and only once.
///
/// The [RiverpieContainer] is used as [ref]
/// - within provider builders and
/// - within notifiers.
///
/// You can override a provider by passing [overrides] to the constructor.
/// In this case, the state of the provider is initialized right away.
class RiverpieContainer extends Ref {
  /// Holds all provider states
  final _state = <BaseProvider, BaseNotifier>{};

  /// The provided observer (e.g. for logging)
  final RiverpieObserver? observer;

  final Map<BaseProvider, BaseNotifier Function(Ref ref)>? _overrides;

  /// Creates a [RiverpieContainer].
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [observer] is used to observe events.
  RiverpieContainer({
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    this.observer,
  }) : _overrides = _overridesToMap(overrides) {
    for (final override in overrides) {
      if (_state.containsKey(override.provider)) {
        // Already initialized
        // This may happen when a provider depends on another provider and
        // both are overridden.
        continue;
      }

      final notifier = override.createState(this);
      notifier.setup(this, observer);
      _state[override.provider] = notifier;

      observer?.handleEvent(
        ProviderInitEvent(
          provider: override.provider,
          notifier: notifier,
          value: notifier.state, // ignore: invalid_use_of_protected_member
          cause: ProviderInitCause.override,
        ),
      );
    }

    // initialize all specified providers right away
    for (final provider in initialProviders) {
      _getState(provider, ProviderInitCause.initial);
    }
  }

  /// Returns the state of the provider.
  ///
  /// If the provider is accessed the first time,
  /// it will be initialized.
  N _getState<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider, [
    ProviderInitCause cause = ProviderInitCause.access,
  ]) {
    N? notifier = _state[provider] as N?;
    if (notifier == null) {
      final overridden = _overrides?.createState(provider, this);
      notifier = overridden ?? provider.createState(this);
      notifier.setup(this, observer);
      _state[provider] = notifier;

      observer?.handleEvent(
        ProviderInitEvent(
          provider: provider,
          notifier: notifier,
          value: notifier.state, // ignore: invalid_use_of_protected_member
          cause: overridden != null ? ProviderInitCause.override : cause,
        ),
      );
    }
    return notifier;
  }

  /// Returns the actual value of a [Provider].
  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    // ignore: invalid_use_of_protected_member
    return _getState(provider).state;
  }

  /// Returns the notifier of a [NotifierProvider].
  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _getState(provider as BaseProvider<N, T>);
  }

  /// Returns the notifier of a [NotifierProvider].
  /// This method can be used to avoid the constraint of [NotifyableProvider].
  /// Useful for testing.
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _getState(provider);
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _getState(provider).getStream();
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    // ignore: invalid_use_of_protected_member
    return _getState(provider).future;
  }
}

Map<BaseProvider, BaseNotifier Function(Ref ref)>? _overridesToMap(
    List<ProviderOverride> overrides) {
  return overrides.isEmpty
      ? null
      : Map.fromEntries(
          overrides.map(
            (override) => MapEntry(override.provider, override.createState),
          ),
        );
}

extension on Map<BaseProvider, BaseNotifier Function(Ref ref)> {
  /// Returns the overridden notifier for the provider.
  N? createState<N extends BaseNotifier<T>, T>(
      BaseProvider<N, T> provider, Ref ref) {
    return this[provider]?.call(ref) as N;
  }
}
