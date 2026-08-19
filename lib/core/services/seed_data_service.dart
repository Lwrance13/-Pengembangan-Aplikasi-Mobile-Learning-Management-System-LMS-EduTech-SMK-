import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script seed data demo untuk EduTech SMK.
/// Jalankan sekali dari Admin Dashboard untuk mengisi data awal.
///
/// Akun demo yang dibuat:
/// - siswa1@edutech.smk / password123  (SISWA, Kelas XII-TKJ-1)
/// - guru.mapel@edutech.smk / password123 (GURU_MAPEL, Mapel: Pemrograman)
/// - wali.kelas@edutech.smk / password123 (WALI_KELAS, Kelas XII-TKJ-1)
/// - guru.bk@edutech.smk / password123   (GURU_BK)
/// - guru.piket@edutech.smk / password123 (GURU_PIKET)
/// - admin@edutech.smk / password123      (ADMIN)
class SeedDataService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await seedUsers();
    await seedMateri();
    await seedTugas();
    await seedKuis();
    await seedJadwal();
    await seedPengumuman();
  }

  // ── 1. USERS ──────────────────────────────────────────────────────────────
  static Future<void> seedUsers() async {
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
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: u['email'] as String,
          password: u['password'] as String,
        );
        await cred.user!.updateDisplayName(u['name'] as String);
        await _db.collection('users').doc(cred.user!.uid).set({
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
      } catch (e) {
        // User mungkin sudah ada, lanjut
      }
    }
  }

  // ── 2. MATERI ─────────────────────────────────────────────────────────────
  static Future<void> seedMateri() async {
    final materiList = [
      {
        'judul': 'Pengenalan HTML & CSS',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Pemrograman Web',
        'deskripsi': 'Dasar-dasar pembuatan halaman web menggunakan HTML5 dan CSS3.',
        'type': 'pdf',
        'file_url': null,
        'file_name': 'html_css_dasar.pdf',
        'guru_name': 'Pak Ahmad Fauzi',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'judul': 'JavaScript Fundamentals',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Pemrograman Web',
        'deskripsi': 'Konsep dasar pemrograman JavaScript: variabel, fungsi, dan DOM.',
        'type': 'video',
        'file_url': null,
        'file_name': 'js_fundamentals.mp4',
        'guru_name': 'Pak Ahmad Fauzi',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'judul': 'Database MySQL Dasar',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Basis Data',
        'deskripsi': 'Pengenalan SQL: CREATE TABLE, INSERT, SELECT, UPDATE, DELETE.',
        'type': 'pdf',
        'file_url': null,
        'file_name': 'mysql_dasar.pdf',
        'guru_name': 'Pak Ahmad Fauzi',
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final m in materiList) {
      await _db.collection('materi').add(m);
    }
  }

  // ── 3. TUGAS ──────────────────────────────────────────────────────────────
  static Future<void> seedTugas() async {
    final tugasList = [
      {
        'judul': 'Tugas 1: Buat Halaman HTML Profil',
        'deskripsi': 'Buat halaman HTML yang menampilkan profil dirimu. Harus menggunakan minimal 5 tag HTML berbeda.',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Pemrograman Web',
        'guru_name': 'Pak Ahmad Fauzi',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'created_at': FieldValue.serverTimestamp(),
        'submission_count': 0,
      },
      {
        'judul': 'Tugas 2: Query SQL Dasar',
        'deskripsi': 'Buat 10 query SQL untuk tabel siswa: CREATE, INSERT 5 data, SELECT dengan WHERE, UPDATE, DELETE.',
        'kelas': 'XII-TKJ-1',
        'mapel': 'Basis Data',
        'guru_name': 'Pak Ahmad Fauzi',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'created_at': FieldValue.serverTimestamp(),
        'submission_count': 0,
      },
    ];

    for (final t in tugasList) {
      await _db.collection('tugas').add(t);
    }
  }

  // ── 4. KUIS ───────────────────────────────────────────────────────────────
  static Future<void> seedKuis() async {
    final kuisRef = await _db.collection('kuis').add({
      'judul': 'Kuis HTML Dasar',
      'kelas': 'XII-TKJ-1',
      'mapel': 'Pemrograman Web',
      'guru_name': 'Pak Ahmad Fauzi',
      'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'created_at': FieldValue.serverTimestamp(),
    });

    // Soal kuis
    final soalList = [
      {
        'soal': 'Tag HTML untuk membuat judul terbesar adalah...',
        'pilihan': ['<h6>', '<h1>', '<title>', '<head>'],
        'jawaban': 1,
      },
      {
        'soal': 'Atribut CSS untuk mengubah warna teks adalah...',
        'pilihan': ['background-color', 'font-size', 'color', 'text-align'],
        'jawaban': 2,
      },
      {
        'soal': 'Tag HTML untuk membuat link adalah...',
        'pilihan': ['<link>', '<a>', '<href>', '<url>'],
        'jawaban': 1,
      },
    ];

    for (final s in soalList) {
      await kuisRef.collection('questions').add(s);
    }
  }

  // ── 5. JADWAL ─────────────────────────────────────────────────────────────
  static Future<void> seedJadwal() async {
    final jadwalList = [
      {'hari': 'Senin', 'jam': '07:00-08:30', 'mapel': 'Pemrograman Web', 'guru': 'Pak Ahmad Fauzi', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Komputer 1'},
      {'hari': 'Senin', 'jam': '08:30-10:00', 'mapel': 'Basis Data', 'guru': 'Pak Ahmad Fauzi', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Komputer 1'},
      {'hari': 'Selasa', 'jam': '07:00-08:30', 'mapel': 'Jaringan Komputer', 'guru': 'Bu Sri Wahyuni', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Jaringan'},
      {'hari': 'Rabu', 'jam': '09:00-10:30', 'mapel': 'Pemrograman Web', 'guru': 'Pak Ahmad Fauzi', 'kelas': 'XII-TKJ-1', 'ruang': 'Lab Komputer 1'},
      {'hari': 'Kamis', 'jam': '07:00-08:30', 'mapel': 'Matematika', 'guru': 'Bu Sari', 'kelas': 'XII-TKJ-1', 'ruang': 'Kelas XII-TKJ-1'},
      {'hari': 'Jumat', 'jam': '07:00-08:30', 'mapel': 'Bahasa Indonesia', 'guru': 'Pak Rudi', 'kelas': 'XII-TKJ-1', 'ruang': 'Kelas XII-TKJ-1'},
    ];

    for (final j in jadwalList) {
      await _db.collection('jadwal').add(j);
    }
  }

  // ── 6. PENGUMUMAN ─────────────────────────────────────────────────────────
  static Future<void> seedPengumuman() async {
    await _db.collection('pengumuman').add({
      'judul': 'Selamat Datang di EduTech SMK!',
      'isi': 'Aplikasi LMS EduTech SMK resmi diluncurkan. Silakan gunakan fitur-fitur yang tersedia untuk mendukung proses pembelajaran.',
      'jenis': 'umum',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('pengumuman').add({
      'judul': 'Jadwal Ujian Tengah Semester',
      'isi': 'UTS akan dilaksanakan pada tanggal 20-25 Agustus 2026. Persiapkan diri dengan baik!',
      'jenis': 'umum',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
