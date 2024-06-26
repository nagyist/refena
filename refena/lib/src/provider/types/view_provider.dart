import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/view_family_provider.dart';
import 'package:refena/src/ref.dart';

/// The [ViewProvider] is the only provider that can watch other providers.
/// Its builder is similar to a normal [Provider].
/// A common use case is to define a view model that depends on many providers.
/// Don't worry about the [ref], you can use it freely inside any function.
/// The [ref] will never become invalid.
///
/// Set [describeState] to customize the description of the state.
/// See [BaseNotifier.describeState].
///
/// Set [debugLabel] to customize the debug label of the provider.
class ViewProvider<T>
    extends BaseWatchableProvider<ViewProvider<T>, ViewProviderNotifier<T>, T>
    with ProviderSelectMixin<ViewProvider<T>, ViewProviderNotifier<T>, T>
    implements RebuildableProvider<ViewProviderNotifier<T>, T, T> {
  final T Function(WatchableRef ref) _builder;
  final String Function(T state)? _describeState;

  ViewProvider(
    this._builder, {
    super.onChanged,
    String Function(T state)? describeState,
    String? debugLabel,
    super.debugVisibleInGraph = true,
  })  : _describeState = describeState,
        super(debugLabel: debugLabel ?? 'ViewProvider<$T>');

  @override
  ViewProviderNotifier<T> createState(Ref ref) {
    final notifier = ViewProviderNotifier<T>(
      _builder,
      describeState: _describeState,
    );
    notifier.setCustomDebugLabel(customDebugLabel ?? runtimeType.toString());
    return notifier;
  }

  /// Overrides with a predefined value.
  ///
  /// {@category Initialization}
  ProviderOverride<ViewProviderNotifier<T>, T> overrideWithBuilder(
    T Function(WatchableRef) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (_) {
        final notifier = ViewProviderNotifier(
          builder,
          describeState: _describeState,
        );
        notifier
            .setCustomDebugLabel(customDebugLabel ?? runtimeType.toString());
        return notifier;
      },
    );
  }

  /// A shorthand for [ViewFamilyProvider].
  static ViewFamilyProvider<T, P> family<T, P>(
    ViewFamilyBuilder<T, P> builder, {
    String Function(T state)? describeState,
    String? debugLabel,
    bool debugVisibleInGraph = true,
  }) {
    return ViewFamilyProvider(
      builder,
      describeState: describeState,
      debugLabel: debugLabel ?? 'ViewFamilyProvider<$T, $P>',
      debugVisibleInGraph: debugVisibleInGraph,
    );
  }
}
