import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ProofSaveException implements Exception {
  ProofSaveException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Stores proof photos inside the app's private documents directory.
/// A save is only reported as successful after the copied file has been
/// verified to exist and be non-empty.
class ProofStorage {
  ProofStorage(this._baseDir);

  final Future<Directory> Function() _baseDir;
  static const _uuid = Uuid();

  Future<String> save(File source) async {
    if (!await source.exists()) {
      throw ProofSaveException('الصورة المختارة غير موجودة');
    }
    final base = await _baseDir();
    final dir = Directory(p.join(base.path, 'proofs'));
    await dir.create(recursive: true);
    final ext = p.extension(source.path).toLowerCase();
    final safeExt = (ext == '.png' || ext == '.webp') ? ext : '.jpg';
    final dest = File(p.join(dir.path, '${_uuid.v4()}$safeExt'));
    try {
      await source.copy(dest.path);
      final ok = await dest.exists() && await dest.length() > 0;
      if (!ok) {
        throw ProofSaveException('تعذر حفظ الصورة');
      }
    } on FileSystemException {
      await _tryDelete(dest);
      throw ProofSaveException('تعذر حفظ الصورة');
    } on ProofSaveException {
      await _tryDelete(dest);
      rethrow;
    }
    return dest.path;
  }

  Future<bool> exists(String path) => File(path).exists();

  Future<void> delete(String path) => _tryDelete(File(path));

  Future<void> _tryDelete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Best effort cleanup.
    }
  }
}
