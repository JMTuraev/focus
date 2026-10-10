import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/chat_source.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';

/// Server-side history search, newest first, with opaque TDLib cursors.
class ChatSearch extends StatefulWidget {
  const ChatSearch({super.key, required this.source, required this.chatId, required this.onSelected, required this.onClose});
  final ChatSource source;
  final String chatId;
  final Future<void> Function(Message message) onSelected;
  final VoidCallback onClose;
  @override
  State<ChatSearch> createState() => _ChatSearchState();
}

class _ChatSearchState extends State<ChatSearch> {
  final _input = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  bool _busy = false;
  bool _failed = false;
  List<Message> _messages = [];
  String _next = '';
  int _total = 0;
  int _selected = -1;

  @override
  void dispose() {
    _request++;
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    _request++; // invalidate a response as soon as the query changes
    setState(() {
      _messages = [];
      _total = 0;
      _selected = -1;
      _next = '';
      _failed = false;
      _busy = false;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () => _search());
  }

  Future<void> _search({bool more = false}) async {
    _debounce?.cancel();
    final query = _input.text.trim();
    if (query.isEmpty || (more && (_busy || _next.isEmpty))) return;
    final request = ++_request;
    final cursor = more ? _next : '';
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final page = await widget.source.searchMessages(widget.chatId, query, fromMessageId: cursor);
      if (!mounted || request != _request) return;
      setState(() {
        final ids = more ? _messages.map((m) => m.id).toSet() : <String>{};
        _messages = [...(more ? _messages : <Message>[]), ...page.messages.where((m) => ids.add(m.id))];
        _total = page.total;
        _next = page.nextFromMessageId == cursor ? '' : page.nextFromMessageId;
        if (!more) _selected = -1;
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Future<void> _select(int index) async {
    if (index < 0) return;
    final query = _input.text;
    if (index >= _messages.length && _next.isNotEmpty) await _search(more: true);
    if (!mounted || query != _input.text || index >= _messages.length) return;
    setState(() => _selected = index);
    await widget.onSelected(_messages[index]);
  }

  Widget _highlight(String text, Color color) {
    final query = _input.text.trim();
    final spans = <TextSpan>[];
    var at = 0;
    if (query.isNotEmpty) {
      for (final match in RegExp(RegExp.escape(query), caseSensitive: false, unicode: true).allMatches(text)) {
        spans.add(TextSpan(text: text.substring(at, match.start)));
        spans.add(TextSpan(text: text.substring(match.start, match.end), style: const TextStyle(fontWeight: FontWeight.w800)));
        at = match.end;
      }
    }
    spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(children: spans), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 13));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.chats;
    return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
        child: Container(
          color: c.panel,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _input,
                      autofocus: true,
                      onChanged: _changed,
                      onSubmitted: (_) => _search(),
                      decoration:
                          InputDecoration(hintText: t.searchInChat, border: InputBorder.none, prefixIcon: const Icon(Icons.search)))),
              if (_busy) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
              Text(_selected < 0 ? '$_total' : '${_selected + 1}/$_total', style: TextStyle(color: c.text2, fontSize: 12)),
              IconButton(
                  tooltip: t.olderResult,
                  onPressed: !_busy && (_selected + 1 < _messages.length || _next.isNotEmpty) ? () => _select(_selected + 1) : null,
                  icon: const Icon(Icons.keyboard_arrow_up)),
              IconButton(
                  tooltip: t.newerResult,
                  onPressed: !_busy && _selected > 0 ? () => _select(_selected - 1) : null,
                  icon: const Icon(Icons.keyboard_arrow_down)),
              IconButton(tooltip: context.s.common.close, onPressed: widget.onClose, icon: const Icon(Icons.close)),
            ]),
            if (_failed)
              Row(children: [
                Expanded(child: Text(t.searchFailed, style: TextStyle(color: c.danger))),
                TextButton(onPressed: () => _search(more: _messages.isNotEmpty && _next.isNotEmpty), child: Text(context.s.common.retry))
              ]),
            if (!_busy && !_failed && _input.text.trim().isNotEmpty && _messages.isEmpty)
              Padding(padding: const EdgeInsets.all(8), child: Text(t.noSearchResults, style: TextStyle(color: c.text2))),
            if (_messages.isNotEmpty)
              SizedBox(
                  height: MediaQuery.sizeOf(context).height < 700 ? 100 : 140,
                  child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        return ListTile(
                            dense: true,
                            selected: index == _selected,
                            selectedTileColor: c.accentSoft,
                            title: _highlight(m.text.isNotEmpty ? m.text : m.fileName ?? m.mediaLabel ?? t.message, c.text),
                            trailing: Text(m.time, style: TextStyle(color: c.text2, fontSize: 11)),
                            onTap: () => _select(index));
                      })),
            if (_next.isNotEmpty) TextButton(onPressed: _busy ? null : () => _search(more: true), child: Text(t.loadMoreResults)),
          ]),
        ));
  }
}
