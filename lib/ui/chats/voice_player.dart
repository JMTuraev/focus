import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// Plays one voice message at a time (OGG/Opus via libmpv).
/// The player is created on first use, so tests and startup stay light.
class VoicePlayer extends ChangeNotifier {
  VoicePlayer._();

  static final instance = VoicePlayer._();

  Player? _player;
  final _subs = <StreamSubscription<Object?>>[];

  /// Message id of the voice that is loaded (playing or paused).
  String? current;
  bool playing = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  bool isPlaying(String id) => current == id && playing;

  /// Progress 0..1 of [id] if it is the loaded voice.
  double progressOf(String id) {
    if (current != id || duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }

  Player _ensure() {
    final existing = _player;
    if (existing != null) return existing;
    final p = Player();
    _subs.addAll([
      p.stream.playing.listen((v) {
        playing = v;
        notifyListeners();
      }),
      p.stream.position.listen((v) {
        position = v;
        notifyListeners();
      }),
      p.stream.duration.listen((v) {
        duration = v;
        notifyListeners();
      }),
      p.stream.completed.listen((done) {
        if (!done) return;
        playing = false;
        position = Duration.zero;
        notifyListeners();
      }),
    ]);
    return _player = p;
  }

  /// Play [path] for message [id], or pause/resume if it is already loaded.
  Future<void> toggle(String id, String path) async {
    final p = _ensure();
    if (current == id) {
      if (position == Duration.zero && !playing) {
        await p.open(Media(path));
      } else {
        await p.playOrPause();
      }
      return;
    }
    current = id;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
    await p.open(Media(path));
  }

  Future<void> stop() async {
    await _player?.stop();
    current = null;
    playing = false;
    position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }
}
