// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/base_provider.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/watchable.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Similar to [ViewModelBuilder], but designed for family providers.
///
/// When this widget is disposed, only the parameter will be disposed instead
/// of the whole family (which is what [ViewModelBuilder] does).
class FamilyViewModelBuilder<P extends BaseProvider<N, T>,
    N extends BaseNotifier<T>, T, F, R, B> extends StatefulWidget {
  /// The provider to use.
  /// The [builder] will be called whenever this provider changes.
  final FamilySelectedWatchable<P, N, T, F, R, B> provider;

  /// This function is called **BEFORE** the widget is built for the first time.
  /// It should not return a [Future].
  final void Function(BuildContext context)? onFirstLoadingFrame;

  /// This function is called **BEFORE** the widget is built for the first time.
  /// The view model is available at this point.
  final void Function(BuildContext context, R vm)? onFirstFrame;

  /// This function is called **AFTER** the widget is built for the first time.
  /// It can return a [Future].
  /// In this case, the widget will show the [loadingBuilder] if provided.
  final FutureOr<void> Function(BuildContext context)? init;

  /// This function is called when the widget is removed from the tree.
  final void Function(Ref ref)? dispose;

  /// Whether to dispose the provider when the widget is removed from the tree.
  final bool disposeProvider;

  /// The widget to show while the provider is initializing.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// The widget to show if the initialization fails.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )? errorBuilder;

  /// A debug label for better logging.
  final String debugLabel;

  /// The builder to build the widget tree.
  final Widget Function(BuildContext context, R vm) builder;

  FamilyViewModelBuilder({
    super.key,
    required this.provider,
    this.onFirstLoadingFrame,
    this.onFirstFrame,
    this.init,
    this.dispose,
    bool? disposeProvider,
    this.loadingBuilder,
    this.errorBuilder,
    String? debugLabel,
    Widget? debugParent,
    required this.builder,
  })  : disposeProvider = disposeProvider ?? true,
        debugLabel = debugLabel ??
            debugParent?.runtimeType.toString() ??
            'ViewModelBuilder<$T>';

  @override
  State<FamilyViewModelBuilder<P, N, T, F, R, B>> createState() =>
      _FamilyViewModelBuilderState<P, N, T, F, R, B>();
}

class _FamilyViewModelBuilderState<
    P2 extends BaseProvider<N2, T>,
    N2 extends BaseNotifier<T>,
    T,
    F,
    R,
    B> extends State<FamilyViewModelBuilder<P2, N2, T, F, R, B>> with Refena {
  bool _initialized = false;
  bool _firstFrameCalled = false;
  (Object, StackTrace)? _error; // use record for null-safety

  @override
  void initState() {
    super.initState();

    if (widget.init == null) {
      _initialized = true;
      return;
    }

    ensureRef((ref) async {
      try {
        final result = widget.init!(context);
        if (result is Future) {
          await result;
        }
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      } catch (error, stackTrace) {
        if (mounted) {
          setState(() {
            _error = (error, stackTrace);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose!(ref);
    }
    if (widget.disposeProvider) {
      ref.disposeFamilyParam(widget.provider.provider, widget.provider.param);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.init != null && widget.onFirstLoadingFrame != null) {
      initialBuild((ref) => widget.onFirstLoadingFrame!(context));
    }

    final error = _error;
    if (error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error.$1, error.$2);
    }
    if (!_initialized && widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }

    final vm = ref.watch(widget.provider);

    if (!_firstFrameCalled && widget.onFirstFrame != null) {
      widget.onFirstFrame!(context, vm);
      _firstFrameCalled = true;
    }

    return widget.builder(context, vm);
  }
}
