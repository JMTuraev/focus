import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';

/// Extensions that run code when opened; Focus asks before opening them.
const _risky = {
  'exe', 'msi', 'bat', 'cmd', 'com', 'scr', 'pif', 'ps1', 'psm1', 'vbs', 'vbe', 'js', 'jse', 'wsf', 'wsh',
  'hta', 'jar', 'lnk', 'reg', 'cpl', 'msc', 'dll', 'appx', 'msix', 'appinstaller', 'url', 'iso', 'img', 'vhd',
};

bool isRiskyFile(String name) => _risky.contains(name.contains('.') ? name.split('.').last.toLowerCase() : '');

/// Opens a downloaded file with its Windows app. Programs and scripts need
/// a confirmation first, like in Telegram Desktop.
Future<void> openDownloadedFile(BuildContext context, String path, String name) async {
  if (isRiskyFile(name)) {
    final c = context.fc;
    final t = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(t.chats.openFileTitle, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          t.chats.riskyFile(name),
          style: TextStyle(color: c.textSoft, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: c.text2),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
            child: Text(t.chats.openAnyway),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  final opened = await launchUrl(Uri.file(path)).catchError((Object _) => false);
  if (!opened && context.mounted) {
    showToast(context, (w) => SnackBar(width: w, content: Text(context.s.chats.cantOpenFile)));
  }
}

/// Opens Explorer with the file selected.
Future<void> showInFolder(String path) => Process.start('explorer.exe', ['/select,', path]);

/// "Boshqa joyga saqlash…": copies a downloaded file where the user picks.
Future<void> saveFileAs(BuildContext context, String path, String name) async {
  final target = await getSaveLocation(suggestedName: name);
  if (target == null) return;
  try {
    await File(path).copy(target.path);
    if (context.mounted) {
      showToast(context, (w) => SnackBar(width: w, content: Text(context.s.chats.savedAs(target.path.split(RegExp(r'[\\/]')).last))));
    }
  } catch (_) {
    if (context.mounted) {
      showToast(context, (w) => SnackBar(width: w, content: Text(context.s.chats.cantSaveFile)));
    }
  }
}

/// Click on a file: opens it when downloaded, else starts the download.
Future<void> openOrDownload(BuildContext context, AppState state, Message message) async {
  final f = message.file;
  if (f == null || f.uploadProgress != null) return;
  final path = f.path;
  if (path != null) {
    await openDownloadedFile(context, path, message.fileName ?? context.s.common.file);
  } else if (!f.downloading && f.fileId >= 0) {
    state.download(f.fileId, priority: 32);
  }
}

/// Right click on a file: open, show in folder, save elsewhere, and
/// [extra] entries (label → action) such as "go to chat".
Future<void> showFileMenu(
  BuildContext context,
  Message message,
  Offset pos, {
  Map<String, VoidCallback> extra = const {},
}) async {
  final c = context.fc;
  final path = message.file?.path;
  if (path == null && extra.isEmpty) return;
  final name = message.fileName ?? context.s.common.file;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  TextStyle style() => TextStyle(color: c.text, fontSize: 14);
  final choice = await showMenu<String>(
    context: context,
    color: c.panel,
    position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
    items: [
      if (path != null) ...[
        PopupMenuItem(value: 'open', height: 38, child: Text(context.s.common.open, style: style())),
        PopupMenuItem(value: 'folder', height: 38, child: Text(context.s.chats.showInFolder, style: style())),
        PopupMenuItem(value: 'save', height: 38, child: Text(context.s.chats.saveAs, style: style())),
      ],
      if (path != null && extra.isNotEmpty) const PopupMenuDivider(),
      for (final e in extra.keys) PopupMenuItem(value: 'x:$e', height: 38, child: Text(e, style: style())),
    ],
  );
  if (choice == null || !context.mounted) return;
  if (choice.startsWith('x:')) {
    extra[choice.substring(2)]?.call();
    return;
  }
  switch (choice) {
    case 'open':
      await openDownloadedFile(context, path!, name);
    case 'folder':
      await showInFolder(path!);
    case 'save':
      await saveFileAs(context, path!, name);
  }
}

/// Document or audio row in a message: click downloads, then opens.
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.message, required this.state});

  final Message message;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chatId = state.activeChatId;
    final name = (chatId == null ? message.fileName : state.fileNameOf(chatId, message)) ?? context.s.common.file;
    final f = message.file;
    final uploading = f?.uploadProgress != null;
    final downloading = f != null && !f.downloaded && f.downloading;
    final progress = uploading ? f!.uploadProgress! : (downloading ? f.progress : null);

    final meta = uploading
        ? '${Fmt.size((f!.size * f.uploadProgress!).round())} / ${Fmt.size(f.size)}'
        : downloading
            ? '${Fmt.size((f.size * f.progress).round())} / ${Fmt.size(f.size)}'
            : (message.fileMeta ?? '');

    final icon = uploading
        ? Icons.arrow_upward
        : (f == null || f.downloaded ? Icons.insert_drive_file_outlined : Icons.arrow_downward);

    Future<void> onTap() async {
      if (f == null || uploading) return;
      final path = f.path;
      if (path != null) {
        await openDownloadedFile(context, path, name);
      } else if (!f.downloading && f.fileId >= 0) {
        state.download(f.fileId, priority: 32);
      }
    }

    // Right click: open, show in folder, save elsewhere (once downloaded)
    // and "Fayllarga saqlash" for the open chat.
    Future<void> onMenu(Offset pos) => showFileMenu(
          context,
          message,
          pos,
          extra: {
            if (chatId != null && f?.uploadProgress == null)
              context.s.chats.saveToFiles: () {
                final t = context.s.chats;
                final added = state.saveToFiles(message);
                showToast(
                  context,
                  (w) => SnackBar(
                    width: w < 480 ? w : 480,
                    persist: false,
                    content: Text(added ? t.savedToFiles(name) : t.alreadyInFiles),
                    action: SnackBarAction(label: t.openFiles, onPressed: () => state.openModule(Module.files)),
                  ),
                );
              },
          },
        );

    return GestureDetector(
      onSecondaryTapDown: (d) => onMenu(d.globalPosition),
      child: MouseRegion(
        cursor: f == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                      if (progress != null)
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        ),
                      Icon(icon, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.text)),
                      Text(meta, style: TextStyle(fontSize: 12.5, color: c.text2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
