import 'dart:math' as math;
import 'dart:ui' as ui;

import 'models.dart';

/// Telegram caption limit; longer text is sent as its own message first.
const kCaptionLimit = 1024;

/// Telegram albums hold at most this many items.
const kAlbumLimit = 10;

/// One file ready to send: as a compressed photo or as a document.
class PlannedFile {
  const PlannedFile(this.file, {this.asPhoto = false, this.width = 0, this.height = 0});

  final OutgoingFile file;
  final bool asPhoto;
  final int width;
  final int height;
}

/// Telegram's limits for photos; anything else goes as a document.
bool photoFits(int size, int width, int height) {
  if (width <= 0 || height <= 0) return false;
  if (size > 10 * 1024 * 1024) return false;
  if (width + height > 10000) return false;
  return math.max(width, height) / math.min(width, height) <= 20;
}

/// Photos first, then documents, each in albums of at most [kAlbumLimit]
/// (Telegram does not mix photos and documents in one album).
List<List<PlannedFile>> groupForSending(List<PlannedFile> files) {
  final out = <List<PlannedFile>>[];
  for (final part in [files.where((f) => f.asPhoto).toList(), files.where((f) => !f.asPhoto).toList()]) {
    for (var i = 0; i < part.length; i += kAlbumLimit) {
      out.add(part.sublist(i, math.min(i + kAlbumLimit, part.length)));
    }
  }
  return out;
}

/// Width and height of an image file without decoding all of it, or null
/// when it is not a readable image.
Future<(int, int)?> imageSize(String path) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromFilePath(path);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    return (descriptor.width, descriptor.height);
  } catch (_) {
    return null;
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// Decides how each file is sent. [measure] is replaceable in tests.
Future<List<PlannedFile>> planFiles(
  List<OutgoingFile> files, {
  required bool compressImages,
  Future<(int, int)?> Function(String path) measure = imageSize,
}) async {
  final out = <PlannedFile>[];
  for (final f in files) {
    if (compressImages && f.isImage) {
      final dim = await measure(f.path);
      if (dim != null && photoFits(f.size, dim.$1, dim.$2)) {
        out.add(PlannedFile(f, asPhoto: true, width: dim.$1, height: dim.$2));
        continue;
      }
    }
    out.add(PlannedFile(f));
  }
  return out;
}
