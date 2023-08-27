// ignore_for_file: invalid_use_of_internal_member, invalid_use_of_protected_member

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:riverpie/src/observer/tracing_observer.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

class RiverpieTracingPage extends StatefulWidget {
  const RiverpieTracingPage({super.key});

  @override
  State<RiverpieTracingPage> createState() => _RiverpieTracingPageState();
}

class _RiverpieTracingPageState extends State<RiverpieTracingPage>
    with Riverpie {
  final _scrollController = ScrollController();
  List<_TracingEntry> _entries = [];
  List<_TracingEntry> _filteredEntries = [];
  bool _show = false;
  bool _notInitializedError = false;
  String _query = '';

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load({
    Duration loadDelay = const Duration(milliseconds: 300),
    Duration showDelay = const Duration(milliseconds: 500),
  }) async {
    ensureRef((ref) async {
      setState(() {
        _show = false;
      });
      await Future.delayed(loadDelay);
      if (!ref.notifier(tracingProvider).initialized) {
        setState(() {
          _notInitializedError = true;
        });
        return;
      }

      _entries = _buildEntries(ref.notifier(tracingProvider).events);
      _filter();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _scrollController.jumpTo(
          100 + 20 + (_entries.length * 120).toDouble(),
        );

        await Future.delayed(showDelay);

        setState(() {
          _show = true;
        });
      });
    });
  }

  void _filter() {
    final queryLower = _query.toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((e) {
        return _contains(e, queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpie Tracing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _show
                ? () {
                    ref.notifier(tracingProvider).clear();
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      _load(
                        loadDelay: Duration.zero,
                        showDelay: Duration.zero,
                      );
                    });
                  }
                : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100, top: 20),
            itemCount: _filteredEntries.length,
            itemBuilder: (context, index) {
              final entry = _filteredEntries[index];
              return _EntryTile(
                entry: entry,
                depth: 0,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Filter',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                    _filter();
                  });
                },
              ),
            ),
          ),
          if (!_show)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_notInitializedError)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Tracing is not initialized. Make sure you have added the RiverpieTracingObserver to your RiverpieScope.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatefulWidget {
  final _TracingEntry entry;
  final int depth;

  const _EntryTile({
    required this.entry,
    required this.depth,
  });

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = switch (widget.entry.event.event) {
      ChangeEvent() => true,
      ActionDispatchedEvent() => true,
      ProviderInitEvent() => true,
      ListenerAddedEvent() => false,
      ListenerRemovedEvent() => false,
    };
    return Column(
      children: [
        Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(_formatTimestamp(widget.entry.event.timestamp),
                      style: TextStyle(color: Colors.grey)),
                ),
                if (widget.depth != 0)
                  Padding(
                    padding: EdgeInsets.only(left: (widget.depth - 1) * 40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 40,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.subdirectory_arrow_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: canExpand
                      ? () {
                          setState(() => _expanded = !_expanded);
                        }
                      : null,
                  child: Container(
                    color: _getColor(widget.entry.event.event).withOpacity(0.3),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                    ),
                    child: Text(
                      switch (widget.entry.event.event) {
                        ChangeEvent() => 'S',
                        ActionDispatchedEvent() => 'A',
                        ProviderInitEvent() => 'I',
                        ListenerAddedEvent() => 'LA',
                        ListenerRemovedEvent() => 'LR',
                      },
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: canExpand
                        ? () {
                            setState(() => _expanded = !_expanded);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getColor(widget.entry.event.event)
                            .withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              switch (widget.entry.event.event) {
                                ChangeEvent event =>
                                  event.prev.runtimeType.toString(),
                                ActionDispatchedEvent event =>
                                  '${event.action.debugLabel}${widget.depth == 0 ? ' (${event.debugOrigin})' : ''}',
                                ProviderInitEvent event =>
                                  event.provider.toString(),
                                ListenerAddedEvent event =>
                                  '${event.rebuildable.debugLabel} on ${event.notifier.debugLabel ?? event.notifier.runtimeType.toString()}',
                                ListenerRemovedEvent event =>
                                  '${event.rebuildable.debugLabel} on ${event.notifier.debugLabel ?? event.notifier.runtimeType.toString()}',
                              },
                            ),
                          ),
                          if (canExpand)
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (canExpand)
              AnimatedCrossFade(
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                firstChild: const SizedBox(),
                secondChild: Row(
                  children: [
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                            _formatTimestamp(widget.entry.event.timestamp),
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    SizedBox(width: (widget.depth + 1) * 40),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColor(widget.entry.event.event)
                              .withOpacity(0.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: switch (widget.entry.event.event) {
                            ChangeEvent event => [
                                _AttributeRow(
                                    label: 'Prev',
                                    value: event.prev.toString()),
                                _AttributeRow(
                                    label: 'Next',
                                    value: event.next.toString()),
                                _AttributeRow(
                                  label: 'Rebuild',
                                  value: event.rebuild
                                      .map((r) => r.debugLabel)
                                      .join(', '),
                                ),
                              ],
                            ActionDispatchedEvent event => [
                                _AttributeRow(
                                    label: 'Origin', value: event.debugOrigin),
                                _AttributeRow(
                                  label: 'Action Group',
                                  value: event.notifier.debugLabel ??
                                      event.notifier.runtimeType.toString(),
                                ),
                                _AttributeRow(
                                  label: 'Action',
                                  value: event.action.toString(),
                                ),
                              ],
                            ProviderInitEvent event => [
                                _AttributeRow(
                                  label: 'Initial',
                                  value: event.value.toString(),
                                ),
                              ],
                            ListenerAddedEvent _ => [],
                            ListenerRemovedEvent _ => [],
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        ...widget.entry.children.map((e) => _EntryTile(
              entry: e,
              depth: widget.depth + 1,
            )),
      ],
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final String value;

  const _AttributeRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('[ $label ]', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

List<_TracingEntry> _buildEntries(Iterable<TimedRiverpieEvent> events) {
  final result = <_TracingEntry>[];
  for (final event in events) {
    switch (event.event) {
      case ChangeEvent e:
        if (e.action != null) {
          final existing = _findEventWithAction(result, e.action!);

          if (existing != null) {
            existing.children.add(_TracingEntry(event, []));
            continue;
          }
        }
        result.add(_TracingEntry(event, []));
        break;
      case ActionDispatchedEvent e:
        if (e.debugOriginRef != null) {
          final existing = _findEventWithAction(result, e.debugOriginRef!);

          if (existing != null) {
            existing.children.add(_TracingEntry(event, []));
            continue;
          }
        }
        result.add(_TracingEntry(event, []));
        break;
      case ProviderInitEvent _:
        result.add(_TracingEntry(event, []));
        break;
      case ListenerAddedEvent _:
        result.add(_TracingEntry(event, []));
        break;
      case ListenerRemovedEvent _:
        result.add(_TracingEntry(event, []));
        break;
    }
  }
  return result;
}

// recursively find the action in the result list
_TracingEntry? _findEventWithAction(List<_TracingEntry> result, Object action) {
  for (final entry in result) {
    if (entry.event.event is ActionDispatchedEvent) {
      if (identical(
          (entry.event.event as ActionDispatchedEvent).action, action)) {
        return entry;
      }
    }
    final found = _findEventWithAction(entry.children, action);
    if (found != null) {
      return found;
    }
  }
  return null;
}

class _TracingEntry {
  final TimedRiverpieEvent event;
  final List<_TracingEntry> children;

  _TracingEntry(this.event, this.children);
}

Color _getColor(RiverpieEvent event) {
  return switch (event) {
    ChangeEvent() => Colors.orange,
    ActionDispatchedEvent() => Colors.blue,
    ProviderInitEvent() => Colors.green,
    ListenerAddedEvent() => Colors.grey,
    ListenerRemovedEvent() => Colors.grey,
  };
}

String _formatTimestamp(DateTime timestamp) {
  return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

// query is already lower case
bool _contains(_TracingEntry entry, String query) {
  final contains = switch (entry.event.event) {
    ChangeEvent event =>
      event.prev.runtimeType.toString().toLowerCase().contains(query) ||
          event.rebuild.any((r) => r.debugLabel.contains(query)),
    ActionDispatchedEvent event =>
      event.action.debugLabel.toLowerCase().contains(query) ||
          event.debugOrigin.toLowerCase().contains(query),
    ProviderInitEvent event =>
      event.provider.toString().toLowerCase().contains(query),
    ListenerAddedEvent event =>
      event.rebuildable.debugLabel.toLowerCase().contains(query) ||
          (event.notifier.debugLabel?.toLowerCase().contains(query) ?? false) ==
              true,
    ListenerRemovedEvent event =>
      event.rebuildable.debugLabel.toLowerCase().contains(query) ||
          (event.notifier.debugLabel?.toLowerCase().contains(query) ?? false) ==
              true,
  };

  if (contains) {
    return true;
  }

  // Recursively check children
  for (final child in entry.children) {
    if (_contains(child, query)) {
      return true;
    }
  }

  return false;
}
