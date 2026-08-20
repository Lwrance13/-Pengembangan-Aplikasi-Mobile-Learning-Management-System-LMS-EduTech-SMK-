import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/services/seed_data_service.dart';
import '../shared/notification_list_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _AdminHomeTab(),
      _AdminUserManagementTab(),
      _AdminJadwalTab(),
      _AdminStatistikTab(),
      _AdminPelanggaranTab(),
      _AdminProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Admin Portal'),
        backgroundColor: AppTheme.adminColor,
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
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outlined), label: 'Pengguna'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Statistik'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), label: 'Pelanggaran'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ──────────────────────────────────────────────────────────────
class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            color: AppTheme.adminColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: AppTheme.adminColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.name ?? 'Admin',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Kepala Sekolah / Admin',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats Row
          const _StatsRow(),
          const SizedBox(height: 20),
          const Text('Pengumuman Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const _PengumumanList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminColor),
              onPressed: () => _addPengumuman(context),
              icon: const Icon(Icons.campaign),
              label: const Text('Buat Pengumuman'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _seedData(context),
              icon: const Icon(Icons.data_object),
              label: const Text('Seed Data Demo'),
            ),
          ),
        ],
      ),
    );
  }

  void _addPengumuman(BuildContext context) {
    final judulCtrl = TextEditingController();
    final isiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Pengumuman Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: judulCtrl,
                decoration: const InputDecoration(labelText: 'Judul Pengumuman')),
            const SizedBox(height: 8),
            TextField(controller: isiCtrl, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Isi Pengumuman')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminColor),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.pengumumanCollection)
                  .add({
                'judul': judulCtrl.text.trim(),
                'isi': isiCtrl.text.trim(),
                'jenis': 'umum',
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _seedData(BuildContext context) {
    showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Seed Data Demo'),
                content: const Text(
                  'Ini akan membuat akun demo dan data awal untuk testing.\n\n'
                  'Akun yang dibuat:\n'
                  '• siswa1@edutech.smk\n'
                  '• guru.mapel@edutech.smk\n'
                  '• wali.kelas@edutech.smk\n'
                  '• guru.bk@edutech.smk\n'
                  '• guru.piket@edutech.smk\n\n'
                  'Password semua akun: password123',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuat data demo...')),
                        );
                      }
                      await SeedDataService.seedAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Data demo berhasil dibuat!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Buat Data Demo'),
                  ),
                ],
              ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .snapshots(),
      builder: (context, snap) {
        final users = snap.data?.docs ?? [];
        final siswa = users.where((u) => (u.data() as Map)['role'] == 'SISWA').length;
        final guru = users.where((u) {
          final r = (u.data() as Map)['role'] as String? ?? '';
          return r == 'GURU_MAPEL' || r == 'WALI_KELAS' || r == 'GURU_BK' || r == 'GURU_PIKET';
        }).length;

        return Row(
          children: [
            _StatCard(label: 'Total Siswa', value: siswa, icon: Icons.school, color: AppTheme.siswaColor),
            _StatCard(label: 'Total Guru', value: guru, icon: Icons.person, color: AppTheme.guruMapelColor),
            _StatCard(label: 'Total User', value: users.length, icon: Icons.people, color: AppTheme.adminColor),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _PengumumanList extends StatelessWidget {
  const _PengumumanList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.pengumumanCollection)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Card(child: ListTile(title: Text('Belum ada pengumuman.')));
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined, color: AppTheme.adminColor),
                title: Text(d['judul'] ?? ''),
                subtitle: Text(d['isi'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  onPressed: () => doc.reference.delete(),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── USER MANAGEMENT TAB ───────────────────────────────────────────────────
class _AdminUserManagementTab extends StatefulWidget {
  const _AdminUserManagementTab();

  @override
  State<_AdminUserManagementTab> createState() => _AdminUserManagementTabState();
}

class _AdminUserManagementTabState extends State<_AdminUserManagementTab> {
  String _filterRole = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              'ALL', 'SISWA', 'GURU_MAPEL', 'WALI_KELAS', 'GURU_BK', 'GURU_PIKET',
            ].map((r) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(r == 'ALL' ? 'Semua' : AppRoles.getDisplayName(r)),
                selected: _filterRole == r,
                onSelected: (_) => setState(() => _filterRole = r),
                selectedColor: AppTheme.adminColor.withValues(alpha: 0.2),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _filterRole == 'ALL'
                ? FirebaseFirestore.instance
                    .collection(FirebaseConstants.usersCollection).snapshots()
                : FirebaseFirestore.instance
                    .collection(FirebaseConstants.usersCollection)
                    .where('role', isEqualTo: _filterRole).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('Tidak ada pengguna.'));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final role = d['role'] as String? ?? '';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(role),
                        child: Text(
                          (d['name'] as String? ?? '?').isNotEmpty
                              ? (d['name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(d['name'] ?? ''),
                      subtitle: Text('${d['email'] ?? ''}\n${AppRoles.getDisplayName(role)}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) => _handleUserAction(context, docs[i].id, val, d),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit Role')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SISWA': return AppTheme.siswaColor;
      case 'GURU_MAPEL': return AppTheme.guruMapelColor;
      case 'WALI_KELAS': return AppTheme.waliKelasColor;
      case 'GURU_BK': return AppTheme.guruBkColor;
      case 'GURU_PIKET': return AppTheme.guruPiketColor;
      default: return AppTheme.adminColor;
    }
  }

  void _handleUserAction(BuildContext ctx, String uid, String action, Map d) {
    if (action == 'delete') {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Hapus Pengguna?'),
          content: Text('Yakin hapus ${d['name']}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () {
                FirebaseFirestore.instance.collection(FirebaseConstants.usersCollection).doc(uid).delete();
                Navigator.pop(ctx);
              },
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
    } else if (action == 'edit') {
      String selectedRole = d['role'] ?? 'SISWA';
      showDialog(
        context: ctx,
        builder: (dlgCtx) => StatefulBuilder(
          builder: (dlgCtx, setState) => AlertDialog(
            title: Text('Edit Role: ${d['name']}'),
            content: DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: AppRoles.all.map((r) => DropdownMenuItem(
                value: r,
                child: Text(AppRoles.getDisplayName(r)),
              )).toList(),
              onChanged: (v) => setState(() => selectedRole = v!),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection(FirebaseConstants.usersCollection)
                      .doc(uid)
                      .update({'role': selectedRole});
                  Navigator.pop(dlgCtx);
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// ─── JADWAL TAB ────────────────────────────────────────────────────────────
class _AdminJadwalTab extends StatelessWidget {
  const _AdminJadwalTab();

  static const _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addJadwal(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
        backgroundColor: AppTheme.adminColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.jadwalCollection)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada jadwal. Klik + untuk tambah.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            );
          }
          // Group by kelas
          final byKelas = <String, List<QueryDocumentSnapshot>>{};
          for (final d in docs) {
            final kelas = (d.data() as Map)['kelas'] as String? ?? '-';
            byKelas.putIfAbsent(kelas, () => []).add(d);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            children: byKelas.entries.map((e) {
              final sorted = [...e.value]..sort((a, b) {
                  final ha = (a.data() as Map)['hari'] as String? ?? '';
                  final hb = (b.data() as Map)['hari'] as String? ?? '';
                  return _hariList.indexOf(ha).compareTo(_hariList.indexOf(hb));
                });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Kelas ${e.key}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.adminColor)),
                  ),
                  ...sorted.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.adminColor.withValues(alpha: 0.1),
                          child: Text(
                            (d['hari'] as String? ?? '-').substring(0, 2),
                            style: const TextStyle(
                                color: AppTheme.adminColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(d['mapel'] ?? ''),
                        subtitle: Text(
                          '${d['hari'] ?? '-'} • ${d['jam_mulai'] ?? ''}-${d['jam_selesai'] ?? ''} • ${d['guru'] ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(d['ruang'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.danger, size: 18),
                              onPressed: () => doc.reference.delete(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _addJadwal(BuildContext context) {
    final kelasCtrl = TextEditingController();
    final mapelCtrl = TextEditingController();
    final guruCtrl = TextEditingController();
    final jamMulaiCtrl = TextEditingController(text: '07:00');
    final jamSelesaiCtrl = TextEditingController(text: '08:30');
    final ruangCtrl = TextEditingController();
    String hari = 'Senin';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Tambah Jadwal Pelajaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: kelasCtrl,
                    decoration: const InputDecoration(labelText: 'Kelas', hintText: 'XII-TKJ-1')),
                const SizedBox(height: 8),
                TextField(controller: mapelCtrl,
                    decoration: const InputDecoration(labelText: 'Mata Pelajaran')),
                const SizedBox(height: 8),
                TextField(controller: guruCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Guru')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: hari,
                  items: _hariList
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: (v) => setS(() => hari = v!),
                  decoration: const InputDecoration(labelText: 'Hari'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: jamMulaiCtrl,
                        decoration: const InputDecoration(labelText: 'Jam Mulai'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: jamSelesaiCtrl,
                        decoration: const InputDecoration(labelText: 'Jam Selesai'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: ruangCtrl,
                    decoration: const InputDecoration(labelText: 'Ruang', hintText: 'Lab TKJ 1')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminColor),
              onPressed: () async {
                if (kelasCtrl.text.trim().isEmpty || mapelCtrl.text.trim().isEmpty) return;
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.jadwalCollection)
                    .add({
                  'kelas': kelasCtrl.text.trim(),
                  'mapel': mapelCtrl.text.trim(),
                  'guru': guruCtrl.text.trim(),
                  'hari': hari,
                  'jam_mulai': jamMulaiCtrl.text.trim(),
                  'jam_selesai': jamSelesaiCtrl.text.trim(),
                  'ruang': ruangCtrl.text.trim(),
                  'created_at': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STATISTIK TAB ─────────────────────────────────────────────────────────
class _AdminStatistikTab extends StatelessWidget {
  const _AdminStatistikTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistik Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          const _AbsensiStatCard(),
          const SizedBox(height: 12),
          const _MateriStatCard(),
          const SizedBox(height: 12),
          const _TugasStatCard(),
        ],
      ),
    );
  }
}

class _AbsensiStatCard extends StatelessWidget {
  const _AbsensiStatCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.absensiCollection)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final hadir = docs.where((d) => (d.data() as Map)['status'] == 'hadir').length;
        final alpha = docs.where((d) => (d.data() as Map)['status'] == 'alpha').length;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Rekap Absensi Total', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat('Hadir', hadir, AppTheme.success),
                    _MiniStat('Alpha', alpha, AppTheme.danger),
                    _MiniStat('Total', docs.length, AppTheme.primary),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MateriStatCard extends StatelessWidget {
  const _MateriStatCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.materiCollection)
          .snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.guruMapelColor),
            title: const Text('Total Materi Diunggah'),
            trailing: Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.guruMapelColor)),
          ),
        );
      },
    );
  }
}

class _TugasStatCard extends StatelessWidget {
  const _TugasStatCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.tugasCollection)
          .snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment, color: AppTheme.primary),
            title: const Text('Total Tugas Diberikan'),
            trailing: Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── PELANGGARAN TAB ───────────────────────────────────────────────────────
class _AdminPelanggaranTab extends StatelessWidget {
  const _AdminPelanggaranTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPelanggaran(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: AppTheme.adminColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.pelanggaranCollection)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Tidak ada catatan pelanggaran.'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final poin = d['poin'] ?? 0;
              final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: poin >= 80 ? AppTheme.danger : poin >= 50 ? AppTheme.warning : AppTheme.textSecondary,
                    child: Text('$poin', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(d['student_name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['deskripsi'] ?? ''),
                      Text(
                        '${d['jenis'] ?? ''} • ${d['kelas'] ?? ''} • ${tanggal != null ? '${tanggal.day}/${tanggal.month}/${tanggal.year}' : '-'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                    onPressed: () => docs[i].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addPelanggaran(BuildContext context) {
    final namaCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final poinCtrl = TextEditingController();
    String jenis = 'Tata Tertib';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Tambah Pelanggaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Siswa')),
                const SizedBox(height: 8),
                TextField(controller: kelasCtrl,
                    decoration: const InputDecoration(labelText: 'Kelas')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(value: 'Tata Tertib', child: Text('Tata Tertib')),
                    DropdownMenuItem(value: 'Akademik', child: Text('Akademik')),
                    DropdownMenuItem(value: 'Sosial', child: Text('Sosial')),
                    DropdownMenuItem(value: 'Disiplin', child: Text('Disiplin')),
                  ],
                  onChanged: (v) => setS(() => jenis = v!),
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                const SizedBox(height: 8),
                TextField(controller: deskripsiCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi Pelanggaran')),
                const SizedBox(height: 8),
                TextField(
                  controller: poinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Poin Pelanggaran (0–100)', hintText: '10'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminColor),
              onPressed: () async {
                final poin = int.tryParse(poinCtrl.text.trim()) ?? 0;
                if (namaCtrl.text.trim().isEmpty) return;
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.pelanggaranCollection)
                    .add({
                  'student_name': namaCtrl.text.trim(),
                  'kelas': kelasCtrl.text.trim(),
                  'jenis': jenis,
                  'deskripsi': deskripsiCtrl.text.trim(),
                  'poin': poin,
                  'tanggal': FieldValue.serverTimestamp(),
                  'input_by': 'admin',
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROFIL TAB ────────────────────────────────────────────────────────────
class _AdminProfilTab extends StatelessWidget {
  const _AdminProfilTab();

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
            backgroundColor: AppTheme.adminColor,
            child: Icon(Icons.admin_panel_settings, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const Chip(label: Text('Admin / Kepala Sekolah', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.adminColor),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versi Aplikasi'),
            trailing: const Text('1.0.0', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Firebase Project'),
            trailing: const Text('project-1-96fa1', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
          ),
        ],
      ),
    );
  }
}
