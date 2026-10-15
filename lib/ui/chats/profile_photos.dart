import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/chat_source.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';
import '../common.dart';

/// Owns the route so changing chat or account also closes its profile photos.
class ProfilePhotoButton extends StatefulWidget {
  const ProfilePhotoButton(
      {super.key,
      required this.chat,
      required this.source,
      required this.size});
  final Chat chat;
  final ChatSource source;
  final double size;

  @override
  State<ProfilePhotoButton> createState() => _ProfilePhotoButtonState();
}

class _ProfilePhotoButtonState extends State<ProfilePhotoButton> {
  DialogRoute<void>? _route;

  void _closeRoute() {
    final route = _route;
    _route = null;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = route.navigator;
      if (route.isActive && navigator != null && navigator.mounted) {
        navigator.removeRoute(route);
      }
    });
  }

  @override
  void didUpdateWidget(ProfilePhotoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id ||
        !identical(oldWidget.source, widget.source)) {
      _closeRoute();
    }
  }

  @override
  void dispose() {
    _closeRoute();
    super.dispose();
  }

  Future<void> _open() async {
    if (_route != null) return;
    final source = widget.source;
    final chat = widget.chat;
    final route = DialogRoute<void>(
        context: context,
        builder: (_) => ProfilePhotoViewer(source: source, chat: chat));
    _route = route;
    await Navigator.of(context).push(route);
    if (identical(_route, route)) _route = null;
  }

  @override
  Widget build(BuildContext context) => Tooltip(
        message: context.s.chats.profilePhotos,
        child: InkWell(
            onTap: widget.chat.kind == ChatKind.saved ? null : _open,
            customBorder: const CircleBorder(),
            child:
                ChatAvatar(widget.chat, size: widget.size, showOnline: false)),
      );
}

class ProfilePhotoViewer extends StatefulWidget {
  const ProfilePhotoViewer(
      {super.key, required this.source, required this.chat});
  final ChatSource source;
  final Chat chat;

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer> {
  final _photos = <ProfilePhoto>[];
  final _requested = <int>{};
  int _index = 0;
  int _total = 0;
  String _cursor = '';
  bool _loading = false;
  bool _pageFailed = false;
  bool _fileFailed = false;
  bool _advanceAfterLoad = false;

  @override
  void initState() {
    super.initState();
    final photo = widget.source.currentProfilePhoto(widget.chat.id);
    if (photo != null) _photos.add(photo);
    _download();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _pageFailed = false;
    });
    try {
      final page =
          await widget.source.profilePhotos(widget.chat.id, cursor: _cursor);
      if (!mounted) return;
      setState(() {
        // The first page contains the authoritative current photo and history.
        if (_cursor.isEmpty) {
          _photos.clear();
          _index = 0;
          _fileFailed = false;
        }
        for (final photo in page.photos) {
          if (!_photos.any((p) =>
              p.id == photo.id ||
              (p.media.fileId != null &&
                  p.media.fileId == photo.media.fileId))) {
            _photos.add(photo);
          }
        }
        _total = page.total > _total ? page.total : _total;
        _cursor = page.nextCursor;
        if (_cursor.isEmpty) _total = _photos.length;
        if (_advanceAfterLoad && _index + 1 < _photos.length) _index++;
        _advanceAfterLoad = false;
      });
      _download();
    } catch (_) {
      if (mounted) {
        setState(() {
          _pageFailed = true;
          _advanceAfterLoad = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    if (_photos.isEmpty) return;
    final photo = widget.source.refreshProfilePhoto(_photos[_index]);
    final id = photo.media.fileId;
    if (id == null || photo.media.filePath != null || !_requested.add(id)) {
      return;
    }
    try {
      await widget.source.downloadProfilePhoto(id);
      if (mounted && _photos.isNotEmpty && _photos[_index].media.fileId == id) {
        setState(() => _fileFailed = false);
      }
    } catch (_) {
      _requested.remove(id);
      if (mounted && _photos.isNotEmpty && _photos[_index].media.fileId == id) {
        setState(() => _fileFailed = true);
      }
    }
  }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || _loading && next >= _photos.length) return;
    if (next >= _photos.length) {
      if (_cursor.isNotEmpty) {
        _advanceAfterLoad = true;
        _load();
      }
      return;
    }
    setState(() {
      _index = next;
      _fileFailed = false;
    });
    _download();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.chats;
    final c = context.fc;
    return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.pop(context),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(1),
        },
        child: Focus(
            autofocus: true,
            child: Dialog(
              insetPadding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
              backgroundColor: c.panel,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                  width: 1000,
                  height: 800,
                  child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 4, top: 4, bottom: 4),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  '${widget.chat.name} · ${t.profilePhotos}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: c.text,
                                      fontWeight: FontWeight.w600))),
                          if (_photos.isNotEmpty)
                            Text(
                                '${_index + 1}/${_total > _photos.length ? _total : _photos.length}',
                                style: TextStyle(color: c.text2)),
                          IconButton(
                              tooltip: t.closeEsc,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close)),
                        ])),
                    if (_loading) const LinearProgressIndicator(),
                    if (_pageFailed || _fileFailed)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.center,
                              children: [
                                Text(t.profilePhotosFailed,
                                    style: TextStyle(color: c.danger)),
                                TextButton(
                                    onPressed: () {
                                      if (_pageFailed) _load();
                                      if (_fileFailed) {
                                        setState(() => _fileFailed = false);
                                        _download();
                                      }
                                    },
                                    child: Text(context.s.common.retry)),
                              ])),
                    Expanded(
                        child: Row(children: [
                      IconButton(
                          tooltip: t.previousPhoto,
                          onPressed: _index > 0 ? () => _move(-1) : null,
                          icon: const Icon(Icons.chevron_left)),
                      Expanded(
                          child: _photos.isEmpty
                              ? Center(
                                  child: _loading
                                      ? const CircularProgressIndicator()
                                      : _pageFailed
                                          ? const Icon(Icons.broken_image_outlined)
                                          : Text(t.noProfilePhotos,
                                              textAlign: TextAlign.center))
                              : ListenableBuilder(
                                  listenable: widget.source,
                                  builder: (context, _) {
                                    final photo = widget.source
                                        .refreshProfilePhoto(_photos[_index]);
                                    final media = photo.media;
                                    final path =
                                        media.filePath ?? media.previewPath;
                                    final image = path != null
                                        ? Image.file(File(path),
                                            fit: BoxFit.contain,
                                            gaplessPlayback: true,
                                            errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                    t.profilePhotoUnavailable,
                                                    textAlign:
                                                        TextAlign.center)))
                                        : media.mini != null
                                            ? Image.memory(media.mini!,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const SizedBox.shrink())
                                            : null;
                                    return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (image != null)
                                            Positioned.fill(
                                                child: InteractiveViewer(
                                                    key: ValueKey(photo.id),
                                                    minScale: 1,
                                                    maxScale: 6,
                                                    child:
                                                        Center(child: image))),
                                          if (media.fileId != null &&
                                              media.filePath == null &&
                                              !_fileFailed)
                                            CircularProgressIndicator(
                                                value: media.progress > 0
                                                    ? media.progress
                                                    : null),
                                        ]);
                                  })),
                      IconButton(
                          tooltip: t.nextPhoto,
                          onPressed: _index + 1 < _photos.length ||
                                  !_loading && _cursor.isNotEmpty
                              ? () => _move(1)
                              : null,
                          icon: const Icon(Icons.chevron_right)),
                    ])),
                  ])),
            )));
  }
}
