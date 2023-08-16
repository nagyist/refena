import 'package:flutter/material.dart';
import 'package:riverpie/src/notifier/types/future_provider_notifier.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/ref.dart';

/// A [FutureProvider] is a custom implementation of a [AsyncNotifierProvider]
/// that allows you to watch a [Future].
///
/// The advantage over using a [FutureBuilder] is that the
/// value is cached and only the first call to the [Future] is executed.
///
/// Usage:
/// final myProvider = FutureProvider((ref) async {
///   return await fetchApi();
/// }
///
/// Example use cases:
/// - fetch static data from an API (that does not change)
/// - fetch device information (that does not change)
class FutureProvider<T>
    extends AsyncNotifierProvider<FutureProviderNotifier<T>, T> {
  FutureProvider(Future<T> Function(Ref ref) builder, {super.debugLabel})
      : super((ref) => FutureProviderNotifier<T>(
              builder(ref),
              debugLabel: debugLabel ?? 'FutureProvider<$T>',
            ));

  ProviderOverride<FutureProviderNotifier<T>, AsyncSnapshot<T>>
      overrideWithFuture(Future<T> value) {
    return ProviderOverride<FutureProviderNotifier<T>, AsyncSnapshot<T>>(
      provider: this,
      state: FutureProviderNotifier<T>(
        value,
        debugLabel: debugLabel ?? runtimeType.toString(),
      ),
    );
  }

  @override
  String toString() {
    return debugLabel ?? 'FutureProvider<$T>';
  }
}