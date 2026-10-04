import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';

/// What the user chose in the send dialog.
class SendFilesChoice {
  const SendFilesChoice({required this.files, required this.caption, required this.compressImages});

  final List<OutgoingFile> files;
  final String caption;
  final bool compressImages;
}

/// Files from paths (size read from disk; missing files are skipped).
List<OutgoingFile> outgoingFiles(Iterable<String> paths) {
  final out = <OutgoingFile>[];
  for (final path in paths) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final name = path.split(RegExp(r'[\\/]')).last;
    out.add(OutgoingFile(path: path, name: name, size: f.lengthSync()));
  }
  return out;
}

/// Opens the Windows file picker; empty when cancelled.
Future<List<OutgoingFile>> pickFiles() async {
  final picked = await openFiles();
  return outgoingFiles(picked.map((x) => x.path));
}

/// Telegram-like "send files" dialog. Returns null when cancelled.
Future<SendFilesChoice?> showSendFilesDialog(
  BuildContext context,
  List<OutgoingFile> files, {
  String caption = '',
  Future<List<OutgoingFile>> Function() pickMore = pickFiles,
}) {
  return showDialog<SendFilesChoice>(
    context: context,
    builder: (_) => SendFilesDialog(files: files, caption: caption, pickMore: pickMore),
  );
}

class SendFilesDialog extends StatefulWidget {
  const SendFilesDialog({super.key, required this.files, this.caption = '', this.pickMore = pickFiles});

  final List<OutgoingFile> files;
  final String caption;
  final Future<List<OutgoingFile>> Function() pickMore;

  @override
  State<SendFilesDialog> createState() => _SendFilesDialogState();
}

class _SendFilesDialogState extends State<SendFilesDialog> {
  late final List<OutgoingFile> _files = [...widget.files];
  late final _caption = TextEditingController(text: widget.caption);
  bool _compress = true;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() {
    if (_files.isEmpty) return;
    Navigator.pop(context, SendFilesChoice(files: _files, caption: _caption.text, compressImages: _compress));
  }

  Future<void> _addMore() async {
    final more = await widget.pickMore();
    if (!mounted || more.isEmpty) return;
    setState(() {
      final known = _files.map((f) => f.path).toSet();
      _files.addAll(more.where((f) => !known.contains(f.path)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s;
    final images = _files.where((f) => f.isImage).length;
    final total = _files.fold<int>(0, (sum, f) => sum + f.size);
    final title = _files.length == 1
        ? (images == 1 && _compress ? t.chats.sendPhoto : t.chats.sendFile)
        : t.chats.sendFiles(_files.length);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): _send},
      child: AlertDialog(
        backgroundColor: c.panel,
        title: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700))),
            Text(Fmt.size(total), style: TextStyle(color: c.text2, fontSize: 13)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _files.length,
                  itemBuilder: (_, i) => _FileTile(
                    file: _files[i],
                    onRemove: () => setState(() => _files.removeAt(i)),
                  ),
                ),
              ),
              if (_files.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(t.chats.noFileSelected, style: TextStyle(color: c.text2)),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addMore,
                  style: TextButton.styleFrom(foregroundColor: c.accentText),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.chats.addMore),
                ),
              ),
              if (images > 0)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _compress,
                  activeColor: c.accentStrong,
                  onChanged: (v) => setState(() => _compress = v ?? true),
                  title: Text(t.chats.compressImages, style: TextStyle(color: c.text, fontSize: 14)),
                  subtitle: Text(
                    _compress ? t.chats.compressOn : t.chats.compressOff,
                    style: TextStyle(color: c.text2, fontSize: 12.5),
                  ),
                ),
              const SizedBox(height: 4),
              TextField(
                controller: _caption,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                style: TextStyle(color: c.text, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: t.chats.captionHint,
                  hintStyle: TextStyle(color: c.text2),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: c.text2),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: _files.isEmpty ? null : _send,
            style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            child: Text(t.common.send),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.onRemove});

  final OutgoingFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final ext = file.extension.isEmpty ? context.s.common.file : file.extension.toUpperCase();
    Widget icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 22),
    );
    if (file.isImage) {
      icon = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(file.path),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          cacheWidth: 88,
          errorBuilder: (_, __, ___) => icon,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${Fmt.size(file.size)} · $ext', style: TextStyle(color: c.text2, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: context.s.chats.removeFile,
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: c.text2),
          ),
        ],
      ),
    );
  }
}
