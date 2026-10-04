import 'dart:typed_data';

/// One backup file found in Saved Messages.
class BackupEntry {
  const BackupEntry({required this.id, required this.date, required this.size, required this.name});

  /// Transport-specific id (Telegram message id).
  final String id;
  final DateTime date;
  final int size;
  final String name;
}

/// Where encrypted backups are stored: the user's own Saved Messages.
abstract class BackupTransport {
  /// Uploads [data] as a file; [progress] gets 0..1 while uploading.
  Future<void> upload(Uint8List data, {required String fileName, required String caption, void Function(double)? progress});

  /// Backups found, newest first.
  Future<List<BackupEntry>> list();

  Future<Uint8List> download(BackupEntry entry);
}

/// Mock data and tests: backups live in memory.
class MemoryBackupTransport implements BackupTransport {
  final files = <BackupEntry, Uint8List>{};
  var _id = 0;

  @override
  Future<void> upload(Uint8List data, {required String fileName, required String caption, void Function(double)? progress}) async {
    progress?.call(0.5);
    files[BackupEntry(id: '${++_id}', date: DateTime.now(), size: data.length, name: fileName)] = data;
    progress?.call(1);
  }

  @override
  Future<List<BackupEntry>> list() async => files.keys.toList()..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<Uint8List> download(BackupEntry entry) async => files[entry]!;
}
