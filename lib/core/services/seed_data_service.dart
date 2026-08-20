import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script seed data demo untuk EduTech SMK.
/// Jalankan sekali dari Admin Dashboard untuk mengisi data awal.
///
/// Bug yang sudah diperbaiki:
/// - guru_id ditambahkan ke materi/tugas/kuis agar tampil di dashboard guru
/// - field 'pertanyaan' (bukan 'soal') sesuai dengan QuizTakePage
/// - field 'index' ditambahkan agar kuis bisa di-load dengan orderBy
/// - Re-sign in sebagai admin setelah seedUsers selesai
/// - Seed absensi demo untuk trigger alert wali kelas
class SeedDataService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    // 1. Buat semua user, simpan UID guru mapel
    final guruMapelUid = await seedUsers();

    // 2. Re-login sebagai admin setelah pembuatan user
    //    (createUserWithEmailAndPassword auto-signin user baru)
    try {
      await _auth.signInWithEmailAndPassword(
        email: 'admin@edutech.smk',
        password: 'password123',
      );
    } catch (_) {}

    // 3. Seed konten dengan guru_id yang benar
    await seedMateri(guruId: guruMapelUid);
    await seedTugas(guruId: guruMapelUid);
    await seedKuis(guruId: guruMapelUid);
    await seedJadwal();
    await seedPengumuman();
    await seedAbsensiDemo();
  }

  // ── 1. USERS — returns guru.mapel UID ──────────────────────────────────────
  static Future<String> seedUsers() async {
    String guruMapelUid = '';

    final users = [
      {
        'email': 'siswa1@edutech.smk',
        'password': 'password123',
        'name': 'Budi Santoso',
        'role': 'SISWA',
        'nisn': '1234567890',
        'kelas': 'XII-TKJ-1',
      },
      {
        'email': 'siswa2@edutech.smk',
        'password': 'password123',
        'name': 'Siti Rahayu',
        'role': 'SISWA',
        'nisn': '1234567891',
        'kelas': 'XII-TKJ-1',
      },
      {
        'email': 'guru.mapel@edutech.smk',
        'password': 'password123',
        'name': 'Pak Ahmad Fauzi',
        'role': 'GURU_MAPEL',
        'nip': 'NIP001',
        'mapel': 'Pemrograman Web',
        'kelas': 'XII-TKJ-1',
      },
      {
        'email': 'wali.kelas@edutech.smk',
        'password': 'password123',
        'name': 'Bu Sri Wahyuni',
        'role': 'WALI_KELAS',
        'nip': 'NIP002',
        'kelas': 'XII-TKJ-1',
      },
      {
        'email': 'guru.bk@edutech.smk',
        'password': 'password123',
        'name': 'Bu Dewi Pertiwi',
        'role': 'GURU_BK',
        'nip': 'NIP003',
      },
      {
        'email': 'guru.piket@edutech.smk',
        'password': 'password123',
        'name': 'Pak Hendra Wijaya',
        'role': 'GURU_PIKET',
        'nip': 'NIP004',
      },
      {
        'email': 'admin@edutech.smk',
        'password': 'password123',
        'name': 'Kepala Sekolah',
        'role': 'ADMIN',
        'nip': 'NIP000',
      },
    ];

    for (final u in users) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: u['email'] as String,
          password: u['password'] as String,
        );
        final uid = cred.user!.uid;
        await cred.user!.updateDisplayName(u['name'] as String);
        await _db.collection('users').doc(uid).set({
          'email': u['email'],
          'name': u['name'],
          'role': u['role'],
          'nisn': u['nisn'],
          'nip': u['nip'],
          'kelas': u['kelas'],
          'mapel': u['mapel'],
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
        });
        if (u['email'] == 'guru.mapel@edutech.smk') guruMapelUid = uid;
      } catch (_) {
        // User sudah ada — coba ambil UID guru mapel dari Firebase Auth
        if (u['email'] == 'guru.mapel@edutech.smk') {
          try {
            final snap = await _auth.signInWithEmailAndPassword(
              email: 'guru.mapel@edutech.smk',
              password: 'password123',
            );
            guruMapelUid = snap.user?.uid ?? '';
          } catch (_) {}
        }
      }
    }
    return guruMapelUid;
  }

  // ── 2. MATERI ─────────────────────────────────────────────────────────────
  static Future<void> seedMateri({required String guruId}) async {
    final list = [
      {
        'judul': 'Pengenalan HTML & CSS',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Pemrograman Web',
        'deskripsi': 'Dasar-dasar pembuatan halaman web menggunakan HTML5 dan CSS3.',
        'type': 'pdf',
        'file_url': 'https://www.w3schools.com/html/html_intro.asp',
        'file_name': 'html_css_dasar.pdf',
        'guru_id': guruId,
        'guru_name': 'Pak Ahmad Fauzi',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'judul': 'JavaScript Fundamentals',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Pemrograman Web',
        'deskripsi': 'Konsep dasar pemrograman JavaScript: variabel, fungsi, dan DOM.',
        'type': 'video',
        'file_url': 'https://www.youtube.com/watch?v=W6NZfCO5SIk',
        'file_name': 'js_fundamentals.mp4',
        'guru_id': guruId,
        'guru_name': 'Pak Ahmad Fauzi',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'judul': 'Database MySQL Dasar',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Basis Data',
        'deskripsi': 'Pengenalan SQL: CREATE TABLE, INSERT, SELECT, UPDATE, DELETE.',
        'type': 'pdf',
        'file_url': 'https://dev.mysql.com/doc/refman/8.0/en/tutorial.html',
        'file_name': 'mysql_dasar.pdf',
        'guru_id': guruId,
        'guru_name': 'Pak Ahmad Fauzi',
        'created_at': FieldValue.serverTimestamp(),
      },
    ];
    for (final m in list) {
      await _db.collection('materi').add(m);
    }
  }

  // ── 3. TUGAS ──────────────────────────────────────────────────────────────
  static Future<void> seedTugas({required String guruId}) async {
    final list = [
      {
        'judul': 'Tugas 1: Buat Halaman HTML Profil',
        'deskripsi': 'Buat halaman HTML profil dirimu. Gunakan minimal 5 tag HTML: heading, paragraph, list, image, dan link.',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Pemrograman Web',
        'guru_id': guruId,
        'guru_name': 'Pak Ahmad Fauzi',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'created_at': FieldValue.serverTimestamp(),
        'submission_count': 0,
      },
      {
        'judul': 'Tugas 2: Query SQL Dasar',
        'deskripsi': 'Buat 10 query SQL: CREATE TABLE, INSERT 5 data, SELECT WHERE, UPDATE, DELETE.',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Basis Data',
        'guru_id': guruId,
        'guru_name': 'Pak Ahmad Fauzi',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'created_at': FieldValue.serverTimestamp(),
        'submission_count': 0,
      },
    ];
    for (final t in list) {
      await _db.collection('tugas').add(t);
    }
  }

  // ── 4. KUIS ───────────────────────────────────────────────────────────────
  static Future<void> seedKuis({required String guruId}) async {
    final kuisRef = await _db.collection('kuis').add({
      'judul': 'Kuis HTML Dasar',
      'kelas': 'XII-TKJ-1',
      'mapel': 'Pemrograman Web',
      'guru_id': guruId,
      'guru_name': 'Pak Ahmad Fauzi',
      'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'created_at': FieldValue.serverTimestamp(),
    });

    // PENTING: field 'pertanyaan' (bukan 'soal') sesuai QuizTakePage
    // PENTING: field 'index' diperlukan untuk orderBy('index') di QuizTakePage
    final soalList = [
      {
        'pertanyaan': 'Tag HTML untuk membuat judul terbesar adalah...',
        'pilihan': ['<h6>', '<h1>', '<title>', '<head>'],
        'jawaban': 1,
        'index': 0,
      },
      {
        'pertanyaan': 'Property CSS untuk mengubah warna teks adalah...',
        'pilihan': ['background-color', 'font-size', 'color', 'text-align'],
        'jawaban': 2,
        'index': 1,
      },
      {
        'pertanyaan': 'Tag HTML untuk membuat hyperlink adalah...',
        'pilihan': ['<link>', '<a>', '<href>', '<url>'],
        'jawaban': 1,
        'index': 2,
      },
      {
        'pertanyaan': 'Atribut HTML untuk menentukan tujuan link adalah...',
        'pilihan': ['src', 'href', 'link', 'target'],
        'jawaban': 1,
        'index': 3,
      },
      {
        'pertanyaan': 'Tag HTML untuk membuat daftar tanpa nomor adalah...',
        'pilihan': ['<ol>', '<dl>', '<ul>', '<list>'],
        'jawaban': 2,
        'index': 4,
      },
    ];
    for (final s in soalList) {
      await kuisRef.collection('questions').add(s);
    }
  }

  // ── 5. JADWAL ─────────────────────────────────────────────────────────────
  static Future<void> seedJadwal() async {
    final list = [
      {'hari': 'Senin',  'jam_mulai': '07:00', 'jam_selesai': '08:30', 'mapel': 'Pemrograman Web',   'guru': 'Pak Ahmad Fauzi', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Komputer 1'},
      {'hari': 'Senin',  'jam_mulai': '08:30', 'jam_selesai': '10:00', 'mapel': 'Basis Data',        'guru': 'Pak Ahmad Fauzi', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Komputer 1'},
      {'hari': 'Selasa', 'jam_mulai': '07:00', 'jam_selesai': '08:30', 'mapel': 'Jaringan Komputer', 'guru': 'Bu Sri Wahyuni',  'kelas': 'XII-TKJ-1', 'ruang': 'Lab Jaringan'},
      {'hari': 'Rabu',   'jam_mulai': '09:00', 'jam_selesai': '10:30', 'mapel': 'Pemrograman Web',   'guru': 'Pak Ahmad Fauzi', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Komputer 1'},
      {'hari': 'Kamis',  'jam_mulai': '07:00', 'jam_selesai': '08:30', 'mapel': 'Matematika',        'guru': 'Bu Sari',         'kelas': 'XII-TKJ-1', 'ruang': 'Kelas XII-TKJ-1'},
      {'hari': 'Jumat',  'jam_mulai': '07:00', 'jam_selesai': '08:30', 'mapel': 'Bahasa Indonesia',  'guru': 'Pak Rudi',        'kelas': 'XII-TKJ-1', 'ruang': 'Kelas XII-TKJ-1'},
    ];
    for (final j in list) {
      await _db.collection('jadwal').add(j);
    }
  }

  // ── 6. PENGUMUMAN ─────────────────────────────────────────────────────────
  static Future<void> seedPengumuman() async {
    await _db.collection('pengumuman').add({
      'judul': 'Selamat Datang di EduTech SMK!',
      'isi': 'Aplikasi LMS EduTech SMK resmi diluncurkan. Gunakan fitur pembelajaran digital ini sebaik-baiknya.',
      'jenis': 'umum',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('pengumuman').add({
      'judul': 'Jadwal Ujian Tengah Semester',
      'isi': 'UTS dilaksanakan 20–25 Agustus 2026. Persiapkan diri dengan baik!',
      'jenis': 'umum',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ── 7. ABSENSI & PELANGGARAN DEMO ─────────────────────────────────────────
  static Future<void> seedAbsensiDemo() async {
    final siswaSnap = await _db.collection('users')
        .where('nisn', isEqualTo: '1234567890').limit(1).get();
    if (siswaSnap.docs.isEmpty) return;

    final siswaId = siswaSnap.docs.first.id;
    final siswaName = (siswaSnap.docs.first.data())['name'] as String? ?? 'Budi Santoso';

    // 4 alpha agar alert >3x terpicu di Wali Kelas
    for (int i = 0; i < 4; i++) {
      await _db.collection('absensi').add({
        'student_id': siswaId,
        'student_name': siswaName,
        'kelas': 'XII-TKJ-1',
        'status': 'alpha',
        'mapel': 'Pemrograman Web',
        'tanggal': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i + 1))),
      });
    }

    // 6 hadir
    for (int i = 0; i < 6; i++) {
      await _db.collection('absensi').add({
        'student_id': siswaId,
        'student_name': siswaName,
        'kelas': 'XII-TKJ-1',
        'status': 'hadir',
        'mapel': 'Pemrograman Web',
        'tanggal': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i + 5))),
      });
    }

    // Satu catatan pelanggaran
    await _db.collection('pelanggaran').add({
      'student_name': siswaName,
      'student_id': siswaId,
      'kelas': 'XII-TKJ-1',
      'jenis': 'Tata Tertib',
      'deskripsi': 'Terlambat masuk kelas lebih dari 15 menit',
      'poin': 20,
      'input_by': 'guru_piket',
      'tanggal': FieldValue.serverTimestamp(),
    });

    // Satu catatan piket harian
    final now = DateTime.now();
    await _db.collection('piket_harian').add({
      'student_name': siswaName,
      'kelas': 'XII-TKJ-1',
      'jenis': 'terlambat',
      'keterangan': 'Terlambat 20 menit karena ban kempes',
      'timestamp': FieldValue.serverTimestamp(),
      'tanggal_str': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'jam': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    });
  }
}
