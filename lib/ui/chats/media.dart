import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'voice_player.dart';

String _clock(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Photo, video, GIF, round video, sticker or voice inside a message.
class MessageMedia extends StatelessWidget {
  const MessageMedia({super.key, required this.message, required this.state, required this.maxWidth});

  final Message message;
  final AppState state;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final info = message.info!;
    return switch (info.kind) {
      MediaKind.photo => _PhotoTile(message: message, state: state, maxWidth: maxWidth),
      MediaKind.video ||
      MediaKind.gif ||
      MediaKind.videoNote =>
        _VideoTile(message: message, state: state, maxWidth: maxWidth),
      MediaKind.sticker => _StickerTile(info: info, state: state),
      MediaKind.voice => _VoiceTile(message: message, state: state),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Size of a picture in the chat.
///
/// Without a caption the bubble takes the picture's shape: as wide as the
/// picture allows, at most 360 px high. With a caption ([fill]) the picture
/// spans the bubble like in Telegram Desktop, so a portrait photo under a
/// long text is not left as a narrow strip: full width, at most 480 px high,
/// cropped by `BoxFit.cover` when taller (the viewer shows it whole).
@visibleForTesting
Size fitMedia(MediaInfo info, double maxWidth, {bool fill = false, double minWidth = 140}) {
  if (fill) return Size(maxWidth, math.min(maxWidth / info.aspect, 480));
  const maxHeight = 360.0;
  var w = math.min(maxWidth, info.width > 0 ? info.width.toDouble() : maxWidth);
  w = math.max(w, math.min(minWidth, maxWidth));
  var h = w / info.aspect;
  if (h > maxHeight) {
    h = maxHeight;
    w = math.max(math.min(h * info.aspect, maxWidth), math.min(minWidth, maxWidth));
  }
  return Size(w, h);
}

/// The preview image, or the blurred mini thumbnail until it is downloaded.
class _Preview extends StatelessWidget {
  const _Preview({required this.info, required this.state, required this.size});

  final MediaInfo info;
  final AppState state;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final path = info.previewPath;
    final id = info.previewFileId;
    if (path == null && id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => state.download(id));
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget placeholder() => info.mini != null
        ? ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Image.memory(info.mini!,
                width: size.width, height: size.height, fit: BoxFit.cover, gaplessPlayback: true),
          )
        : ColoredBox(color: c.qaBg);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: path == null
          ? placeholder()
          : Image.file(
              File(path),
              width: size.width,
              height: size.height,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: (size.width * dpr).round(),
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.message, required this.state, required this.maxWidth});

  final Message message;
  final AppState state;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final info = message.info!;
    final size = fitMedia(info, maxWidth, fill: message.text.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showPhotoViewer(context, state, message.id),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _Preview(info: info, state: state, size: size),
          ),
        ),
      ),
    );
  }
}

class _VideoTile extends StatefulWidget {
  const _VideoTile({required this.message, required this.state, required this.maxWidth});

  final Message message;
  final AppState state;
  final double maxWidth;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  /// Tapped before the file was downloaded: open it once it is.
  bool _openWhenReady = false;

  MediaInfo get info => widget.message.info!;

  void _tap() {
    final path = info.filePath;
    if (path != null) {
      _open(path);
    } else if (info.fileId != null) {
      setState(() => _openWhenReady = true);
      widget.state.download(info.fileId!, priority: 32);
    }
  }

  void _open(String path) =>
      showVideoViewer(context, path, loop: info.kind == MediaKind.gif, muted: info.kind == MediaKind.gif);

  @override
  void didUpdateWidget(_VideoTile old) {
    super.didUpdateWidget(old);
    final path = info.filePath;
    if (_openWhenReady && path != null) {
      _openWhenReady = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = info.kind == MediaKind.videoNote;
    final size = round ? const Size(220, 220) : fitMedia(info, widget.maxWidth, fill: widget.message.text.isNotEmpty);
    final loading = info.filePath == null && (_openWhenReady || info.downloading);
    final badge = info.kind == MediaKind.gif ? 'GIF' : _clock(info.duration);
    final preview = _Preview(info: info, state: widget.state, size: size);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _tap,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                round ? ClipOval(child: preview) : ClipRRect(borderRadius: BorderRadius.circular(10), child: preview),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Color(0x8C000000), shape: BoxShape.circle),
                  child: loading
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            value: info.progress > 0 ? info.progress : null,
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
                Positioned(
                  left: round ? null : 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      loading && info.progress > 0 ? '${(info.progress * 100).round()}%' : badge,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
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

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.info, required this.state});

  final MediaInfo info;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final side = 160.0;
    final size = info.aspect >= 1 ? Size(side, side / info.aspect) : Size(side * info.aspect, side);
    final path = info.previewPath;
    final id = info.previewFileId;
    if (path == null && id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => state.download(id));
    }
    return SizedBox(
      width: size.width,
      height: size.height,
      child: path == null
          ? (info.mini != null ? Image.memory(info.mini!, fit: BoxFit.contain) : const SizedBox.shrink())
          : Image.file(File(path),
              fit: BoxFit.contain, gaplessPlayback: true, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    );
  }
}

class _VoiceTile extends StatefulWidget {
  const _VoiceTile({required this.message, required this.state});

  final Message message;
  final AppState state;

  @override
  State<_VoiceTile> createState() => _VoiceTileState();
}

class _VoiceTileState extends State<_VoiceTile> {
  bool _playWhenReady = false;

  MediaInfo get info => widget.message.info!;

  void _tap() {
    final path = info.filePath;
    if (path != null) {
      VoicePlayer.instance.toggle(widget.message.id, path);
    } else if (info.fileId != null) {
      setState(() => _playWhenReady = true);
      widget.state.download(info.fileId!, priority: 32);
    }
  }

  @override
  void didUpdateWidget(_VoiceTile old) {
    super.didUpdateWidget(old);
    final path = info.filePath;
    if (_playWhenReady && path != null) {
      _playWhenReady = false;
      VoicePlayer.instance.toggle(widget.message.id, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final player = VoicePlayer.instance;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final id = widget.message.id;
        final playing = player.isPlaying(id);
        final progress = player.progressOf(id);
        final loading = info.filePath == null && (_playWhenReady || info.downloading);
        final shown =
            player.current == id && player.position > Duration.zero ? player.position.inSeconds : info.duration;
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: playing ? context.s.chats.pause : context.s.chats.play,
                child: InkWell(
                  onTap: _tap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: c.accentStrong, shape: BoxShape.circle),
                    child: loading
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              value: info.progress > 0 ? info.progress : null,
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    size: const Size(170, 26),
                    painter: _WaveformPainter(
                      info.waveform,
                      progress: progress,
                      played: c.accent,
                      rest: c.text2.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(_clock(shown), style: TextStyle(fontSize: 12, color: c.text2)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.samples, {required this.progress, required this.played, required this.rest});

  final List<int> samples;
  final double progress;
  final Color played;
  final Color rest;

  @override
  void paint(Canvas canvas, Size size) {
    const bar = 2.0;
    const gap = 1.5;
    final count = (size.width / (bar + gap)).floor();
    final src = samples.isEmpty ? List.filled(count, 6) : samples;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      // Resample the waveform to the number of bars that fit.
      final v = src[(i * src.length / count).floor().clamp(0, src.length - 1)];
      final h = math.max(2.0, size.height * v / 31);
      final x = i * (bar + gap) + bar / 2;
      paint
        ..color = (i + 0.5) / count <= progress ? played : rest
        ..strokeWidth = bar;
      canvas.drawLine(Offset(x, size.height - h), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.samples != samples || old.played != played || old.rest != rest;
}

// ---------------------------------------------------------------- viewers

/// Full-window photo viewer; loads the largest size in the background.
Future<void> showPhotoViewer(BuildContext context, AppState state, String messageId) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xE6000000),
    builder: (context) => ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final id = state.activeChatId;
        Message? m;
        for (final x in id == null ? const <Message>[] : state.messagesOf(id)) {
          if (x.id == messageId) m = x;
        }
        final info = m?.info;
        if (info == null) return const SizedBox.shrink();
        final full = info.filePath;
        if (full == null && info.fileId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => state.download(info.fileId!, priority: 32));
        }
        final path = full ?? info.previewPath;
        return _ViewerFrame(
          child: InteractiveViewer(
            maxScale: 6,
            child: Center(
              child: path == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                      onTap: () {}, // clicks on the photo itself keep the viewer open
                      child: Image.file(File(path), fit: BoxFit.contain, gaplessPlayback: true),
                    ),
            ),
          ),
        );
      },
    ),
  );
}

/// Full-window video player (also used for GIFs, looped and muted).
Future<void> showVideoViewer(BuildContext context, String path, {bool loop = false, bool muted = false}) {
  VoicePlayer.instance.stop();
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xF2000000),
    builder: (context) => _ViewerFrame(child: _VideoPlayerView(path: path, loop: loop, muted: muted)),
  );
}

class _ViewerFrame extends StatelessWidget {
  const _ViewerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    // Own focus + Escape binding: the chat underneath (SelectionArea) can
    // keep keyboard focus otherwise, and Escape would not reach the dialog.
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            // A click on the dark area around the picture closes the viewer;
            // the picture and the video player absorb their own clicks.
            Positioned.fill(
              child: GestureDetector(
                onTap: close,
                behavior: HitTestBehavior.opaque,
                child: Padding(padding: const EdgeInsets.fromLTRB(24, 100, 24, 24), child: child),
              ),
            ),
            // Below the 36 px title bar, so a near miss never hits the window's
            // own close button.
            Positioned(
              top: 48,
              right: 16,
              child: IconButton(
                tooltip: context.s.chats.closeEsc,
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(backgroundColor: const Color(0x66000000)),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  const _VideoPlayerView({required this.path, required this.loop, required this.muted});

  final String path;
  final bool loop;
  final bool muted;

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  @override
  void initState() {
    super.initState();
    if (widget.loop) _player.setPlaylistMode(PlaylistMode.single);
    if (widget.muted) _player.setVolume(0);
    _player.open(Media(widget.path));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void seek(int seconds) => _player.seek(_player.state.position + Duration(seconds: seconds));
    void volume(double delta) => _player.setVolume((_player.state.volume + delta).clamp(0, 100));
    final theme = MaterialDesktopVideoControlsThemeData(
      // Fullscreen fights with the custom title bar, so it is off; Escape
      // closes the viewer instead (media_kit would use it for fullscreen).
      toggleFullscreenOnDoublePress: false,
      keyboardShortcuts: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.space): _player.playOrPause,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => seek(-5),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => seek(5),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => volume(10),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => volume(-10),
      },
      bottomButtonBar: const [
        MaterialDesktopPlayOrPauseButton(),
        MaterialDesktopVolumeButton(),
        MaterialDesktopPositionIndicator(),
        Spacer(),
      ],
    );
    return MaterialDesktopVideoControlsTheme(
      normal: theme,
      fullscreen: theme,
      child: Video(controller: _controller, fill: Colors.transparent),
    );
  }
}
