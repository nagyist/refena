part of 'tracing_page.dart';

final _jsonEncoder = JsonEncoder.withIndent('  ');

final Map<_EventType, Color> _baseColors = {
  _EventType.change: Colors.orange,
  _EventType.rebuild: Colors.purple,
  _EventType.action: Colors.blue,
  _EventType.providerInit: Colors.green,
  _EventType.providerDispose: Colors.grey,
  _EventType.message: Colors.yellow,
};

final Map<_EventType, Color> _headerColor = _baseColors.map((key, value) {
  return MapEntry(key, value.withOpacity(0.3));
});

final Map<_EventType, Color> _backgroundColor = _baseColors.map((key, value) {
  return MapEntry(key, value.withOpacity(0.1));
});

String _formatTimestamp(DateTime timestamp) {
  return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

extension on int {
  String formatMillis() {
    return '${this}ms';
  }
}

String _formatResult(Object result) {
  try {
    if (result is Map<String, dynamic>) {
      return _jsonEncoder.convert(result);
    }

    final parsed = jsonDecode(result.toString());
    return _jsonEncoder.convert(parsed);
  } catch (e) {
    return result.toString();
  }
}
