# EduTech SMK � Mobile Learning Management System (LMS)

**Mata Kuliah: Mobile Cross-Platform Development**

---
## 👥 Kelompok 8

| No | Nama |
|----|------|
| 1 | MUH. YAHYA AL-QADRI |
| 2 | MUH. KHAIDIR NUR |
| 3 | NURSYAHLAN RUSLAN |
| 4 | MUSTAPIAH |

---
## Deskripsi Proyek

Aplikasi mobile berbasis cross-platform untuk mendukung proses pembelajaran di lingkungan SMK. Dibangun menggunakan **Flutter** dengan backend **Google Firebase**.

## Tech Stack

| Komponen | Teknologi |
|----------|-----------|
| Framework | Flutter 3.x (Android, iOS, Web) |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Push Notification | Firebase Cloud Messaging (FCM) |
| Hosting | Firebase Hosting |

## Live Demo

**https://project-1-96fa1.web.app**

## 🎬 Video Demo

▶️ **[Tonton Video Demo (Google Drive)](https://drive.google.com/file/d/1b1jWW22aXODtt6MWS-4pEob6Ucb4G6rb/view?usp=sharing)**

## 6 Role Pengguna

| Role | Fitur Utama |
|------|------------|
| Siswa | Materi, Tugas, Kuis, Absensi, Nilai, Chat Guru, BK, Pelanggaran |
| Guru Mapel | Upload Materi, Buat Tugas/Kuis, Input Absensi Realtime |
| Wali Kelas | Monitoring Kelas, Alert System Cerdas |
| Guru BK | Konseling, Chat Confidential, Case Tracking |
| Guru Piket | QR/NISN Scan, Catatan Harian, Broadcast Darurat |
| Admin | Manajemen User, Statistik, Web Admin Portal |

## Struktur Folder

```
lib/
+-- main.dart
+-- firebase_options.dart
+-- core/
�   +-- constants/      # roles.dart, firebase_constants.dart
�   +-- theme/          # app_theme.dart
�   +-- services/       # auth, fcm, storage, notification, seed
+-- features/
�   +-- auth/           # login_page.dart, role_selection.dart
�   +-- student/        # dashboard, tugas, kuis, jadwal, nilai, bk, pelanggaran
�   +-- teacher/        # dashboard, upload_material
�   +-- wali_kelas/     # dashboard, alert_system_widget
�   +-- bk/             # dashboard, case_tracking
�   +-- piket/          # dashboard, quick_scan
�   +-- admin/          # admin_dashboard
�   +-- shared/         # chat_room, notification_list
```

## Setup

```bash
flutter pub get
flutter run
flutter build web --release
firebase deploy --only hosting
```

## Akun Demo

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@edutech.smk | password123 |
| Siswa | siswa1@edutech.smk | password123 |
| Guru Mapel | guru.mapel@edutech.smk | password123 |
| Wali Kelas | wali.kelas@edutech.smk | password123 |
| Guru BK | guru.bk@edutech.smk | password123 |
| Guru Piket | guru.piket@edutech.smk | password123 |

> Login Admin ? klik **"Seed Data Demo"** untuk membuat semua akun demo.

## Checklist Penilaian

- [x] Fungsional Multi-Role (6 role)
- [x] Backend Cloud Integration (Firebase Auth + Firestore)
- [x] Live Web Deployment � https://project-1-96fa1.web.app
- [x] Push Notification FCM (auto-trigger)
- [ ] Video Demo 10 Menit
