import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../shared/notification_list_page.dart';
import '../shared/chat_room_page.dart';
import 'assignment_view.dart';
import 'jadwal_page.dart';
import 'nilai_page.dart';
import 'quiz_list_page.dart';
import 'bk_booking_page.dart';
import 'pelanggaran_siswa_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _selectedIndex = 0;

  final _pages = const [
    _StudentHomeTab(),
    _StudentMateriTab(),
    _StudentAbsensiTab(),
    _StudentProfilTab(),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>(); // watch for rebuild
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Siswa'),
        backgroundColor: AppTheme.siswaColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationListPage()),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Materi'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _StudentHomeTab extends StatelessWidget {
  const _StudentHomeTab();

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _pushChatGuru(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatGuruListPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Card
          Card(
            color: AppTheme.siswaColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppTheme.siswaColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${user?.name ?? 'Siswa'}!',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('Kelas: ${user?.kelas ?? '-'}',
                            style: const TextStyle(color: Colors.white70)),
                        Text('NISN: ${user?.nisn ?? '-'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick Actions
          const Text('Menu Cepat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _QuickAction(icon: Icons.calendar_today_outlined, label: 'Jadwal', color: AppTheme.primary, onTap: () => _push(context, const JadwalPage())),
              _QuickAction(icon: Icons.quiz_outlined, label: 'Kuis', color: AppTheme.accent, onTap: () => _push(context, const QuizListPage())),
              _QuickAction(icon: Icons.bar_chart_outlined, label: 'Nilai', color: AppTheme.success, onTap: () => _push(context, const NilaiPage())),
              _QuickAction(icon: Icons.assignment_outlined, label: 'Tugas', color: AppTheme.primary, onTap: () => _push(context, const _TugasSiswaPage())),
              _QuickAction(icon: Icons.chat_outlined, label: 'Chat Guru', color: AppTheme.guruMapelColor, onTap: () => _pushChatGuru(context)),
              _QuickAction(icon: Icons.psychology_outlined, label: 'BK', color: AppTheme.guruBkColor, onTap: () => _push(context, const BkBookingPage())),
              _QuickAction(icon: Icons.report_outlined, label: 'Pelanggaran', color: AppTheme.danger, onTap: () => _push(context, const PelanggaranSiswaPage())),
              _QuickAction(icon: Icons.campaign_outlined, label: 'Pengumuman', color: AppTheme.warning, onTap: () => _push(context, const _PengumumanPage())),
            ],
          ),
          const SizedBox(height: 20),
          // Tugas Terbaru
          const Text('Tugas Terbaru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.tugasCollection)
                .where('kelas', isEqualTo: user?.kelas).limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppTheme.success),
                    title: Text('Tidak ada tugas baru'),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final deadline = (d['deadline'] as Timestamp?)?.toDate();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                      title: Text(d['judul'] ?? ''),
                      subtitle: Text('${d['mapel']} • Deadline: ${deadline != null ? '${deadline.day}/${deadline.month}/${deadline.year}' : '-'}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentView(tugasId: doc.id, tugasData: d),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentMateriTab extends StatelessWidget {
  const _StudentMateriTab();

  void _openUrl(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Link materi:'),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(color: AppTheme.primary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Copy to clipboard & show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Salin link di atas dan buka di browser'),
                  action: SnackBarAction(label: 'OK', onPressed: () {}),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Buka Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.materiCollection)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Belum ada materi.'));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada materi.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    d['type'] == 'video' ? Icons.play_circle_outline : Icons.picture_as_pdf,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(d['judul'] ?? ''),
                subtitle: Text('${d['mapel']} • ${d['guru_name']}'),
                trailing: Icon(
                  d['file_url'] != null ? Icons.open_in_new : Icons.lock_outline,
                  color: d['file_url'] != null ? AppTheme.primary : Colors.grey,
                ),
                onTap: () {
                  final url = d['file_url'] as String?;
                  if (url != null && url.isNotEmpty) {
                    _openUrl(context, url, d['judul'] ?? 'Materi');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File tidak tersedia.')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _StudentAbsensiTab extends StatelessWidget {
  const _StudentAbsensiTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.siswaColor,
          child: const Text(
            'Rekap Absensi',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.absensiCollection)
                .where('student_id', isEqualTo: uid).limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_month, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Belum ada data absensi.', style: TextStyle(color: AppTheme.textSecondary)),
                  ]),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              final hadir = docs.where((d) => (d.data() as Map)['status'] == 'hadir').length;
              final alpha = docs.where((d) => (d.data() as Map)['status'] == 'alpha').length;
              final izin = docs.where((d) => (d.data() as Map)['status'] == 'izin').length;
              final sakit = docs.where((d) => (d.data() as Map)['status'] == 'sakit').length;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _AbsensiStat(label: 'Hadir', value: hadir, color: AppTheme.success),
                        _AbsensiStat(label: 'Alpha', value: alpha, color: AppTheme.danger),
                        _AbsensiStat(label: 'Izin', value: izin, color: AppTheme.warning),
                        _AbsensiStat(label: 'Sakit', value: sakit, color: AppTheme.accent),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
                      final status = d['status'] ?? '';
                      Color statusColor;
                      switch (status) {
                        case 'hadir': statusColor = AppTheme.success; break;
                        case 'alpha': statusColor = AppTheme.danger; break;
                        case 'izin': statusColor = AppTheme.warning; break;
                        default: statusColor = AppTheme.accent;
                      }
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.calendar_today, color: statusColor),
                          title: Text(tanggal != null
                              ? '${tanggal.day}/${tanggal.month}/${tanggal.year}'
                              : '-'),
                          subtitle: Text(d['mapel'] ?? ''),
                          trailing: Chip(
                            label: Text(status.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: statusColor,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StudentProfilTab extends StatelessWidget {
  const _StudentProfilTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.siswaColor,
            child: Icon(Icons.person, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          _InfoRow(label: 'NISN', value: user?.nisn ?? '-'),
          _InfoRow(label: 'Kelas', value: user?.kelas ?? '-'),
          _InfoRow(label: 'Role', value: 'Siswa'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AbsensiStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AbsensiStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$value', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          const Text(': '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Halaman daftar guru mapel untuk chat
class _ChatGuruListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat dengan Guru'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.usersCollection)
            .where('role', isEqualTo: 'GURU_MAPEL')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada guru tersedia.', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.guruMapelColor,
                    child: Text(
                      (d['name'] as String? ?? '?').isNotEmpty
                          ? (d['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(d['name'] ?? ''),
                  subtitle: Text('${d['mapel'] ?? '-'}'),
                  trailing: const Icon(Icons.chat_outlined, color: AppTheme.guruMapelColor),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        otherUserId: docs[i].id,
                        otherUserName: d['name'] ?? 'Guru',
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Halaman daftar tugas untuk siswa
class _TugasSiswaPage extends StatelessWidget {
  const _TugasSiswaPage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        backgroundColor: AppTheme.siswaColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.tugasCollection)
            .where('kelas', isEqualTo: kelas)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada tugas.', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final deadline = (d['deadline'] as Timestamp?)?.toDate();
              final isDeadlinePassed = deadline != null && deadline.isBefore(DateTime.now());
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDeadlinePassed
                        ? AppTheme.danger.withValues(alpha: 0.1)
                        : AppTheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: isDeadlinePassed ? AppTheme.danger : AppTheme.primary,
                    ),
                  ),
                  title: Text(d['judul'] ?? ''),
                  subtitle: Text(
                    '${d['mapel'] ?? '-'}'
                    '${deadline != null ? '\nDeadline: ${deadline.day}/${deadline.month}/${deadline.year}' : ''}',
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDeadlinePassed ? AppTheme.danger : null,
                  ),
                  isThreeLine: deadline != null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignmentView(tugasId: docs[i].id, tugasData: d),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Halaman pengumuman sekolah
class _PengumumanPage extends StatelessWidget {
  const _PengumumanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Sekolah'),
        backgroundColor: AppTheme.warning,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.pengumumanCollection)
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada pengumuman.', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final timestamp = (d['timestamp'] as Timestamp?)?.toDate();
              final isDarurat = d['jenis'] == 'darurat';
              return Card(
                color: isDarurat ? AppTheme.danger.withValues(alpha: 0.05) : null,
                shape: isDarurat
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.4)),
                      )
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDarurat
                        ? AppTheme.danger.withValues(alpha: 0.15)
                        : AppTheme.warning.withValues(alpha: 0.15),
                    child: Icon(
                      isDarurat ? Icons.warning_amber : Icons.campaign,
                      color: isDarurat ? AppTheme.danger : AppTheme.warning,
                    ),
                  ),
                  title: Text(
                    d['judul'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarurat ? AppTheme.danger : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['isi'] ?? ''),
                      if (timestamp != null)
                        Text(
                          '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
