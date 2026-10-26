import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_storage.dart';
import 'photo_storage.dart';

enum PhotoTargetKind { exercise, session }

/// The entity a pending pick belongs to. Persisted before launching the system
/// picker so a process restart can attach a recovered image (`PHO-001`).
class PhotoTarget {
  const PhotoTarget({required this.kind, required this.id});

  factory PhotoTarget.exercise(String id) {
    _requireSafe(id);
    return PhotoTarget(kind: PhotoTargetKind.exercise, id: id);
  }

  factory PhotoTarget.session(String id) {
    _requireSafe(id);
    return PhotoTarget(kind: PhotoTargetKind.session, id: id);
  }

  final PhotoTargetKind kind;
  final String id;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'id': id,
  };

  static PhotoTarget? fromJson(Map<String, Object?> json) {
    final Object? kindValue = json['kind'];
    final Object? idValue = json['id'];
    if (kindValue is! String || idValue is! String) {
      return null;
    }
    if (!isPhotoEntityIdSafe(idValue)) {
      return null;
    }
    for (final PhotoTargetKind kind in PhotoTargetKind.values) {
      if (kind.name == kindValue) {
        return PhotoTarget(kind: kind, id: idValue);
      }
    }
    return null;
  }

  static void _requireSafe(String id) {
    if (!isPhotoEntityIdSafe(id)) {
      throw ArgumentError.value(id, 'id', 'Unsafe photo target id');
    }
  }
}

class PhotoPendingStoreException implements Exception {
  const PhotoPendingStoreException();

  @override
  String toString() => 'PhotoPendingStoreException';
}

abstract interface class PhotoPendingStore {
  Future<PhotoTarget?> read();

  Future<void> write(PhotoTarget target);

  Future<void> clear();
}

/// Small app-private marker file. It contains only a kind and an entity ID,
/// never a path or image content.
class JsonPhotoPendingStore implements PhotoPendingStore {
  JsonPhotoPendingStore(this._file);

  final Future<File> Function() _file;

  @override
  Future<PhotoTarget?> read() async {
    final File file = await _file();
    if (!await file.exists()) {
      return null;
    }
    try {
      final String text = await file.readAsString();
      if (text.trim().isEmpty) {
        await _clearQuietly();
        return null;
      }
      final Object? decoded = jsonDecode(text);
      if (decoded is! Map) {
        await _clearQuietly();
        return null;
      }
      final PhotoTarget? target = PhotoTarget.fromJson(
        decoded.cast<String, Object?>(),
      );
      if (target == null) {
        await _clearQuietly();
      }
      return target;
    } catch (_) {
      await _clearQuietly();
      return null;
    }
  }

  @override
  Future<void> write(PhotoTarget target) async {
    final File file = await _file();
    final File temporary = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await temporary.writeAsString(jsonEncode(target.toJson()), flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      await _clearQuietly(temporary);
      throw const PhotoPendingStoreException();
    }
  }

  @override
  Future<void> clear() async {
    try {
      final File file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      throw const PhotoPendingStoreException();
    }
  }

  Future<void> _clearQuietly([File? file]) async {
    try {
      final File target = file ?? await _file();
      if (await target.exists()) {
        await target.delete();
      }
    } catch (_) {
      // A stale marker is ignored on the next read.
    }
  }
}

final Provider<PhotoPendingStore> photoPendingStoreProvider =
    Provider<PhotoPendingStore>((Ref ref) {
      final Future<File> file = appSupportFile(ref, 'photo_pending.json');
      return JsonPhotoPendingStore(() => file);
    });
