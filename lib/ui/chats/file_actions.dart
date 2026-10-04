import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/format.dart';
import '../../data/models.dart';
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text('Faylni ochasizmi?', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          '“$name” dastur yoki skript bo‘lishi mumkin. Unga ishonchingiz komil bo‘lmasa, ochmang: '
          'u kompyuteringizga zarar yetkazishi mumkin.',
          style: TextStyle(color: c.textSoft, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: c.text2),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
            child: const Text('Baribir ochish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  final opened = await launchUrl(Uri.file(path)).catchError((Object _) => false);
  if (!opened && context.mounted) {
    showToast(context, (w) => SnackBar(width: w, content: const Text('Faylni ochib bo‘lmadi')));
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
      showToast(context, (w) => SnackBar(width: w, content: Text('Saqlandi: ${target.path.split(RegExp(r'[\\/]')).last}')));
    }
  } catch (_) {
    if (context.mounted) {
      showToast(context, (w) => SnackBar(width: w, content: const Text('Faylni saqlab bo‘lmadi')));
    }
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
    final name = message.fileName ?? 'Fayl';
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

    Future<void> onMenu(Offset pos) async {
      final path = f?.path;
      if (path == null) return;
      final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
      final choice = await showMenu<String>(
        context: context,
        color: c.panel,
        position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
        items: [
          PopupMenuItem(value: 'open', height: 38, child: Text('Ochish', style: TextStyle(color: c.text, fontSize: 14))),
          PopupMenuItem(
              value: 'folder', height: 38, child: Text('Papkada ko‘rsatish', style: TextStyle(color: c.text, fontSize: 14))),
          PopupMenuItem(
              value: 'save', height: 38, child: Text('Boshqa joyga saqlash…', style: TextStyle(color: c.text, fontSize: 14))),
        ],
      );
      if (!context.mounted) return;
      switch (choice) {
        case 'open':
          await openDownloadedFile(context, path, name);
        case 'folder':
          await showInFolder(path);
        case 'save':
          await saveFileAs(context, path, name);
      }
    }

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
