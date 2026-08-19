import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_constants.dart';

/// Service untuk mengirim notifikasi ke Firestore.
/// Notifikasi disimpan di koleksi `notifikasi` dan akan
/// diterima oleh semua user yang relevan via FCM topic.
class NotificationTriggerService {
  static final _db = FirebaseFirestore.instance;

  /// Kirim notifikasi ke semua siswa satu kelas saat ada tugas baru
  static Future<void> notifyTugasBaru({
    required String kelas,
    required String judulTugas,
    required String mapel,
    required String guruId,
  }) async {
    final siswaSnap = await _db
        .collection(FirebaseConstants.usersCollection)
        .where('role', isEqualTo: 'SISWA')
        .where('kelas', isEqualTo: kelas)
        .get();

    final batch = _db.batch();
    for (final siswa in siswaSnap.docs) {
      final ref = _db.collection(FirebaseConstants.notifikasiCollection).doc();
      batch.set(ref, {
        'user_id': siswa.id,
        'title': '📚 Tugas Baru: $mapel',
        'body': '$judulTugas — Segera kerjakan sebelum deadline!',
        'type': 'tugas',
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'related_id': guruId,
      });
    }
    await batch.commit();
  }

  /// Kirim notifikasi ke Wali Kelas saat siswa melebihi batas pelanggaran
  static Future<void> notifyAlertPelanggaran({
    required String studentId,
    required String studentName,
    required String kelas,
    required int totalPoin,
  }) async {
    // Cari wali kelas
    final waliSnap = await _db
        .collection(FirebaseConstants.usersCollection)
        .where('role', isEqualTo: 'WALI_KELAS')
        .where('kelas', isEqualTo: kelas)
        .get();

    final batch = _db.batch();

    for (final wali in waliSnap.docs) {
      final ref = _db.collection(FirebaseConstants.notifikasiCollection).doc();
      batch.set(ref, {
        'user_id': wali.id,
        'title': '🚨 Alert Pelanggaran: $studentName',
        'body': 'Total poin pelanggaran: $totalPoin/100. Segera tindak lanjuti!',
        'type': 'pelanggaran',
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'related_id': studentId,
      });
    }

    // Juga notifikasi ke Guru BK
    final bkSnap = await _db
        .collection(FirebaseConstants.usersCollection)
        .where('role', isEqualTo: 'GURU_BK')
        .get();

    for (final bk in bkSnap.docs) {
      final ref = _db.collection(FirebaseConstants.notifikasiCollection).doc();
      batch.set(ref, {
        'user_id': bk.id,
        'title': '⚠️ Perlu Perhatian BK: $studentName',
        'body': 'Poin pelanggaran mencapai $totalPoin. Pertimbangkan sesi konseling.',
        'type': 'pelanggaran',
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'related_id': studentId,
      });
    }

    await batch.commit();
  }

  /// Kirim notifikasi ke siswa saat alpha melebihi batas
  static Future<void> notifyAlertAlpha({
    required String studentId,
    required String studentName,
    required int jumlahAlpha,
  }) async {
    // Notifikasi ke wali murid / siswa sendiri
    final ref = _db.collection(FirebaseConstants.notifikasiCollection).doc();
    await ref.set({
      'user_id': studentId,
      'title': '⚠️ Peringatan Kehadiran',
      'body': 'Kamu sudah alpha $jumlahAlpha kali. Harap segera hadir!',
      'type': 'absensi',
      'is_read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Broadcast pengumuman darurat ke semua user
  static Future<void> broadcastDarurat({
    required String judul,
    required String pesan,
    required String senderId,
  }) async {
    // Simpan pengumuman
    await _db.collection(FirebaseConstants.pengumumanCollection).add({
      'judul': judul,
      'isi': pesan,
      'jenis': 'darurat',
      'sender_id': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Notifikasi ke semua user
    final allUsers = await _db
        .collection(FirebaseConstants.usersCollection)
        .get();

    final batch = _db.batch();
    for (final user in allUsers.docs) {
      final ref = _db.collection(FirebaseConstants.notifikasiCollection).doc();
      batch.set(ref, {
        'user_id': user.id,
        'title': '🔔 $judul',
        'body': pesan,
        'type': 'darurat',
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
