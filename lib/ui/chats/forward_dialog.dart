import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/chat_source.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';
import '../common.dart';

Future<String?> showForwardDialog(BuildContext context, ChatSource source, Message message) => showDialog<String>(
      context: context,
      builder: (_) => _ForwardDialog(source: source, message: message),
    );

class _ForwardDialog extends StatefulWidget {
  const _ForwardDialog({required this.source, required this.message});
  final ChatSource source;
  final Message message;
  @override
  State<_ForwardDialog> createState() => _ForwardDialogState();
}

class _ForwardDialogState extends State<_ForwardDialog> {
  String _query = '';
  String? _selected;
  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.chats;
    return Dialog(
      backgroundColor: c.panel,
      child: SizedBox(
        width: math.min(420, MediaQuery.sizeOf(context).width - 48),
        height: math.min(540, MediaQuery.sizeOf(context).height - 80),
        child: ListenableBuilder(
            listenable: widget.source,
            builder: (context, _) {
              final chats =
                  widget.source.chats.where((chat) => chat.canSend && chat.name.toLowerCase().contains(_query.toLowerCase())).toList();
              final selected = _selected == null ? null : widget.source.chatById(_selected!);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(t.forwardMessage, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                      widget.message.text.isNotEmpty
                          ? widget.message.text
                          : widget.message.fileName ?? widget.message.mediaLabel ?? t.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.text2)),
                  TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(hintText: context.s.common.search, prefixIcon: const Icon(Icons.search))),
                  Expanded(
                      child: chats.isEmpty
                          ? Center(child: Text(t.noChatsInFilter))
                          : ListView.builder(
                              itemCount: chats.length,
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                return ListTile(
                                    leading: ChatAvatar(chat, size: 36),
                                    title: Text(chat.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    selected: _selected == chat.id,
                                    selectedTileColor: c.accentSoft,
                                    trailing: _selected == chat.id ? Icon(Icons.check_circle, color: c.accent) : null,
                                    onTap: () => setState(() => _selected = chat.id));
                              },
                            )),
                  if (selected != null)
                    Text(selected.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.accentText)),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(context.s.common.cancel)),
                    FilledButton(
                        onPressed: selected?.canSend == true ? () => Navigator.pop(context, selected!.id) : null,
                        child: Text(context.s.common.send)),
                  ]),
                ]),
              );
            }),
      ),
    );
  }
}
