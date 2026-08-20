import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../shared/notification_list_page.dart';
import 'alert_system_widget.dart';

class WaliDashboardPage extends StatefulWidget {
  const WaliDashboardPage({super.key});

  @override
  State<WaliDashboardPage> createState() => _WaliDashboardPageState();
}

class _WaliDashboardPageState extends State<WaliDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _WaliHomeTab(),
      _WaliAbsensiTab(),
      _WaliPelanggaranTab(),
      _WaliBukuPenghubungTab(),
      _WaliProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Wali Kelas'),
        backgroundColor: AppTheme.waliKelasColor,
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
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), label: 'Pelanggaran'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Buku'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _WaliHomeTab extends StatelessWidget {
  const _WaliHomeTab();

  void _showStudentDetail(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(d['name'] ?? 'Siswa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('NISN', d['nisn'] ?? '-'),
            _DetailRow('Email', d['email'] ?? '-'),
            _DetailRow('Kelas', d['kelas'] ?? '-'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final kelas = user?.kelas ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.waliKelasColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.supervisor_account, color: AppTheme.waliKelasColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '-',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Wali Kelas: $kelas',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AlertSystemWidget(),
          const SizedBox(height: 16),
          const Text('Daftar Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.usersCollection)
                .where('role', isEqualTo: 'SISWA')
                .where('kelas', isEqualTo: kelas)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
              final students = snapshot.data!.docs;
              if (students.isEmpty) {
                return const Card(child: ListTile(title: Text('Belum ada siswa di kelas ini.')));
              }
              return Column(
                children: students.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(d['name'] ?? ''),
                      subtitle: Text('NISN: ${d['nisn'] ?? '-'}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showStudentDetail(context, d),
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

class _WaliAbsensiTab extends StatelessWidget {
  const _WaliAbsensiTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.absensiCollection)
          .where('kelas', isEqualTo: kelas).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada data absensi.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final status = d['status'] ?? '';
            Color color;
            switch (status) {
              case 'hadir': color = AppTheme.success; break;
              case 'alpha': color = AppTheme.danger; break;
              case 'izin': color = AppTheme.warning; break;
              default: color = AppTheme.accent;
            }
            return Card(
              child: ListTile(
                leading: Icon(Icons.person_outlined, color: color),
                title: Text(d['student_name'] ?? d['student_id'] ?? ''),
                subtitle: Text(d['mapel'] ?? ''),
                trailing: Chip(
                  label: Text(status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: color,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WaliPelanggaranTab extends StatelessWidget {
  const _WaliPelanggaranTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.pelanggaranCollection)
          .where('kelas', isEqualTo: kelas).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Tidak ada catatan pelanggaran.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final poin = d['poin'] ?? 0;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: poin >= 80 ? AppTheme.danger : AppTheme.warning,
                  child: Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(d['student_name'] ?? ''),
                subtitle: Text(d['deskripsi'] ?? ''),
                trailing: Text(d['jenis'] ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }
}

class _WaliBukuPenghubungTab extends StatelessWidget {
  const _WaliBukuPenghubungTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';
    return Scaffold(
      appBar: null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _kirimPesan(context, auth.user?.name ?? 'Wali Kelas', kelas),
        icon: const Icon(Icons.send),
        label: const Text('Kirim Pesan'),
        backgroundColor: AppTheme.waliKelasColor,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.waliKelasColor.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.book, color: AppTheme.waliKelasColor),
                SizedBox(width: 8),
                Text('Buku Penghubung Digital',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.waliKelasColor)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.bukuPenghubungCollection)
                  .where('kelas', isEqualTo: kelas)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada pesan.\nKlik tombol + untuk kirim pesan ke orang tua.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final ts = (d['timestamp'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.waliKelasColor,
                          child: Icon(Icons.mail_outline, color: Colors.white),
                        ),
                        title: Text(d['student_name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['pesan'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (ts != null)
                              Text('${ts.day}/${ts.month}/${ts.year}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(d['status'] ?? 'terkirim',
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: AppTheme.success,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _kirimPesan(BuildContext context, String waliName, String kelas) {
    final namaCtrl = TextEditingController();
    final pesanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Pesan ke Orang Tua'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Siswa')),
            const SizedBox(height: 8),
            TextField(controller: pesanCtrl, maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pesan untuk Orang Tua',
                  hintText: 'contoh: Kehadiran ananda perlu ditingkatkan...',
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.waliKelasColor),
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty || pesanCtrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.bukuPenghubungCollection)
                  .add({
                'student_name': namaCtrl.text.trim(),
                'kelas': kelas,
                'pesan': pesanCtrl.text.trim(),
                'wali_name': waliName,
                'status': 'terkirim',
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Pesan berhasil dikirim!'), backgroundColor: AppTheme.success),
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

class _WaliProfilTab extends StatelessWidget {
  const _WaliProfilTab();

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
            backgroundColor: AppTheme.waliKelasColor,
            child: Icon(Icons.supervisor_account, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          _WaliInfoRow(label: 'Kelas', value: user?.kelas ?? '-'),
          _WaliInfoRow(label: 'NIP', value: user?.nip ?? '-'),
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

class _WaliInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _WaliInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          const Text(': '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}