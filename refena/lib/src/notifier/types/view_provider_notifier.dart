part of '../base_notifier.dart';

final class ViewProviderNotifier<T> extends BaseSyncNotifier<T>
    with RebuildableNotifier<T, T> {
  ViewProviderNotifier(
    this._builder, {
    String Function(T state)? describeState,
  }) : _describeState = describeState;

  @override
  final T Function(WatchableRef ref) _builder;

  final String Function(T state)? _describeState;

  @override
  T init() {
    _rebuildController.stream.listen((event) {
      // rebuild notifier state
      _setStateAsRebuild(
        this,
        _callAndSetDependencies(),
        event,
        null,
      );
    });
    return _callAndSetDependencies();
  }

  @override
  String describeState(T state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }

  @override
  T rebuildImmediately(LabeledReference debugOrigin) {
    final T nextState = _callAndSetDependencies();
    _setStateAsRebuild(
      this,
      nextState,
      const [],
      debugOrigin,
    );
    return nextState;
  }
}
