import 'package:refena/refena.dart';
import 'package:sentry/sentry.dart';

/// An observer that sends breadcrumbs to Sentry.
class RefenaSentryObserver extends RefenaObserver {
  /// If the given function returns `true`, then the event
  /// won't be logged.
  final bool Function(RefenaEvent event)? exclude;

  RefenaSentryObserver({
    this.exclude,
  });

  @override
  void handleEvent(RefenaEvent event) {
    if (exclude != null && exclude!(event)) {
      return;
    }

    switch (event) {
      case ActionDispatchedEvent():
        Sentry.addBreadcrumb(Breadcrumb(
          type: 'transaction',
          category: 'refena.action',
          message: event.action.debugLabel,
        ));
      case ActionErrorEvent():
        Sentry.addBreadcrumb(Breadcrumb(
          type: 'error',
          category: 'refena.action',
          message: event.action.debugLabel,
          data: {
            'error': event.error.toString(),
          },
        ));
        break;
      case MessageEvent():
        Sentry.addBreadcrumb(Breadcrumb(
          type: 'info',
          category: 'refena.message',
          message: event.message,
        ));
        break;
      default:
    }
  }
}
