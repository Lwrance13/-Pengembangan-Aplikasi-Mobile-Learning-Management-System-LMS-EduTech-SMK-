class FirebaseConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String materiCollection = 'materi';
  static const String tugasCollection = 'tugas';
  static const String kuisCollection = 'kuis';
  static const String absensiCollection = 'absensi';
  static const String pelanggaranCollection = 'pelanggaran';
  static const String konselingCollection = 'konseling';
  static const String chatCollection = 'chats';
  static const String notifikasiCollection = 'notifikasi';
  static const String pengumumanCollection = 'pengumuman';
  static const String jadwalCollection = 'jadwal';
  static const String nilaiCollection = 'nilai';
  static const String piketCollection = 'piket_harian';
  static const String forumCollection = 'forum';
  static const String bukuPenghubungCollection = 'buku_penghubung';

  // Quiz sub-collections
  static const String quizQuestionsSub = 'questions';
  static const String quizSubmissionsSub = 'submissions';

  // Firebase Storage Paths
  static const String materiStoragePath = 'materi/';
  static const String tugasStoragePath = 'tugas_submissions/';
  static const String profileStoragePath = 'profile_photos/';
  static const String piketStoragePath = 'piket_reports/';

  // FCM Topics
  static const String topicAllUsers = 'all_users';
  static const String topicSiswa = 'siswa';
  static const String topicGuru = 'guru';
}
