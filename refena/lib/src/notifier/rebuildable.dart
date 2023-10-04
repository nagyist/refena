import 'package:meta/meta.dart';
import 'package:refena/src/labeled_reference.dart';
import 'package:refena/src/observer/event.dart';

/// Something that can be rebuilt.
@internal
abstract class Rebuildable with LabeledReference {
  /// Schedule a rebuild (in the next frame).
  /// Optionally pass the [changeEvent], or [rebuildEvent]
  /// that triggered the rebuild.
  /// The event is consumed by the [ViewProviderNotifier] that
  /// fires the [RebuildEvent].
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent);

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// A debug label for this [Rebuildable].
  @override
  String get debugLabel;

  /// Whether this [Rebuildable] is a [ElementRebuildable].
  /// A flag for refena_inspector_client because it does not depend
  /// on refena_flutter.
  bool get isWidget;
}