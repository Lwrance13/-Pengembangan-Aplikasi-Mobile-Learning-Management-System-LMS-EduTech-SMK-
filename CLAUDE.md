# CLAUDE.md

File ini memberikan panduan kepada Claude Code (claude.ai/code) saat bekerja dengan kode di repositori ini.

## Gambaran Umum

EduTech SMK — sebuah Learning Management System (LMS) mobile lintas-platform untuk Sekolah Menengah Kejuruan (SMK) di Indonesia, dibangun dengan Flutter dan Firebase. Proyek Flutter berada di subdirektori `edutech_smk/` (di dalamnya terdapat `pubspec.yaml` dan `main.dart` yang mendefinisikan aplikasi). Akar repositori juga memuat spesifikasi tugas (`TUGAS FINAL ... .md`) dan sebuah PDF yang menjelaskan fitur yang dituju, tetapi bukan implementasinya.

Jalankan semua perintah `flutter`/`dart`/`firebase` dari dalam `edutech_smk/`.

## Perintah

```bash
flutter pub get              # memasang dependensi
flutter run                  # menjalankan di perangkat/emulator yang terhubung
flutter build apk            # build rilis Android
flutter build web --release  # build output web ke build/web
flutter analyze              # analisis statis (flutter_lints)
flutter test                 # menjalankan unit/widget test
flutter test test/foo_test.dart   # menjalankan satu file test
```

Deployment Firebase (dari `edutech_smk/`):

```bash
firebase deploy --only hosting             # deploy build/web ke Firebase Hosting
firebase deploy --only firestore:rules     # deploy firestore.rules
```

Konfigurasi Firebase berada di `firebase.json` (direktori publik hosting = `build/web`, aturan Firestore = `firestore.rules`). Tidak ada `firebase_options.dart` — `main.dart` memanggil `Firebase.initializeApp()` tanpa opsi dan mengandalkan konfigurasi default platform, sehingga proyek Firebase baru harus dihubungkan melalui `flutterfire configure` atau `google-services.json`/`GoogleService-Info.plist`.

## Arsitektur

**State management** menggunakan `provider`. Sebuah `AuthProvider` (`lib/core/services/auth_provider.dart`, sebuah `ChangeNotifier`) didaftarkan di `main.dart` melalui `MultiProvider` dan menyimpan `UserModel` saat ini. Service-service (`AuthService`, `FcmService`, `StorageService`) adalah singleton (konstruktor private + `factory` yang mengembalikan `_instance` bersama); mereka membungkus Firebase SDK dan dipanggil dari provider/halaman, bukan diekspos lewat provider.

**Entry / routing aplikasi** bukan menggunakan library router — `main.dart` menggunakan widget stateful `_AuthGate`. Widget ini memuat user saat ini, lalu melakukan `switch` pada `auth.user.role` (dari `AppRoles`) untuk mengembalikan halaman dashboard yang sesuai. `go_router` ada di dependensi tetapi tidak dihubungkan ke navigasi; layar berpindah dengan `Navigator.push`.

**Model role** (`lib/core/constants/roles.dart`) mendefinisikan enam role sebagai string huruf besar: `SISWA`, `GURU_MAPEL`, `WALI_KELAS`, `GURU_BK`, `GURU_PIKET`, `ADMIN`. String-string ini disimpan langsung di dokumen Firestore `users` (field `role`) dan harus sama persis antara kode aplikasi, aturan keamanan Firestore, dan data seed apa pun.

**Struktur folder berbasis fitur** di bawah `lib/`:

- `core/` — lintas-fitur: `constants/` (`roles.dart`, `firebase_constants.dart` berisi nama koleksi Firestore, path Storage, dan topik FCM), `theme/` (`app_theme.dart`), `services/` (`auth_service.dart`, `auth_provider.dart`, `fcm_service.dart`, `storage_service.dart`, `user_model.dart`).
- `features/` — satu folder per role plus `shared/` dan `auth/`: `student/`, `teacher/`, `wali_kelas/`, `bk/`, `piket/`, `shared/` (chat, notifikasi), `auth/` (login, pemilihan role).

Tambahkan fitur/role baru dengan mengikuti pola ini: konstanta baru di `roles.dart` + `firebase_constants.dart`, sebuah halaman di folder `features/<role>/` yang sesuai, dan sebuah case di dalam `switch` pada `_AuthGate`.

## Model data utama

`UserModel` (`lib/core/services/user_model.dart`) adalah sumber kebenaran tunggal untuk dokumen Firestore `users`. Nama field menggunakan snake_case di Firestore (`photo_url`, `fcm_token`, `is_active`, `created_at`), dipetakan ke properti camelCase Dart melalui `fromFirestore`/`toMap`. Field spesifik-role bersifat nullable dan hanya diisi untuk role yang relevan: `nisn`/`kelas` (siswa), `nip`/`mapel` (guru), `kelas` (wali kelas). `FirebaseConstants` memusatkan semua nama koleksi — gunakan konstanta ini dalam query daripada menuliskan string secara langsung.

## Integrasi Firebase

- **Auth**: email/password melalui `firebase_auth`; saat registrasi, profil ditulis ke `users/{uid}` di Firestore. Custom Claims untuk role dijelaskan di spesifikasi, tetapi kode saat ini menyimpan role di dokumen Firestore, bukan di auth claims.
- **FCM**: `FcmService` men-subscribe setiap user ke `all_users`, dan juga men-subscribe ke topik bernama `role.toLowerCase()` (misal `guru_bk`). Pesan background ditangani oleh handler top-level `@pragma('vm:entry-point')` di `main.dart`.
- **Storage**: `StorageService` mengunggah ke path yang didefinisikan di `FirebaseConstants` (misal `materi/`, `tugas_submissions/`), menghasilkan nama file UUID dan mengembalikan URL unduhan.
