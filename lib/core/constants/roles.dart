class AppRoles {
  static const String siswa = 'SISWA';
  static const String guruMapel = 'GURU_MAPEL';
  static const String waliKelas = 'WALI_KELAS';
  static const String guruBk = 'GURU_BK';
  static const String guruPiket = 'GURU_PIKET';
  static const String admin = 'ADMIN';

  static const List<String> all = [
    siswa,
    guruMapel,
    waliKelas,
    guruBk,
    guruPiket,
    admin,
  ];

  static String getDisplayName(String role) {
    switch (role) {
      case siswa:
        return 'Siswa';
      case guruMapel:
        return 'Guru Mata Pelajaran';
      case waliKelas:
        return 'Wali Kelas';
      case guruBk:
        return 'Guru BK';
      case guruPiket:
        return 'Guru Piket';
      case admin:
        return 'Admin / Kepala Sekolah';
      default:
        return 'Unknown';
    }
  }
}
