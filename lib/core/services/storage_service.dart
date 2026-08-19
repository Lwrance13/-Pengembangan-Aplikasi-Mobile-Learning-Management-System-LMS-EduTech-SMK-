import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload raw bytes (works on all platforms: Android, iOS, Web).
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String storagePath,
    String? customFileName,
    String contentType = 'application/octet-stream',
  }) async {
    final fileName = customFileName ?? _uuid.v4();
    final ref = _storage.ref().child('$storagePath$fileName');
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }
}
