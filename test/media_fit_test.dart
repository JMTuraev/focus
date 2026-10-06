// Picture size inside a message bubble (media.dart: fitMedia).

import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/ui/chats/media.dart';

void main() {
  const portrait = MediaInfo(kind: MediaKind.photo, width: 960, height: 1280);
  const landscape = MediaInfo(kind: MediaKind.photo, width: 1280, height: 720);

  test('without a caption the picture keeps its shape, at most 360 px high', () {
    final s = fitMedia(portrait, 438);
    expect(s.height, 360);
    expect(s.width, closeTo(270, 0.5));
    final l = fitMedia(landscape, 438);
    expect(l.width, 438);
    expect(l.height, closeTo(246.4, 0.5));
  });

  test('with a caption the picture spans the bubble and is cropped at 480 px', () {
    final s = fitMedia(portrait, 438, fill: true);
    expect(s.width, 438);
    expect(s.height, 480, reason: '438 / 0.75 = 584 is capped; BoxFit.cover crops the rest');
    final l = fitMedia(landscape, 438, fill: true);
    expect(l.width, 438);
    expect(l.height, closeTo(246.4, 0.5));
  });
}
