import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../shared/notification_list_page.dart';
import '../auth/login_page.dart';
import 'quick_scan_page.dart';

class PiketDashboardPage extends StatefulWidget {
  const PiketDashboardPage({super.key});

  @override
  State<PiketDashboardPage> createState() => _PiketDashboardPageState();
}

class _PiketDashboardPageState extends State<PiketDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _PiketHomeTab(),
      QuickScanPage(),
      _PiketCatatanTab(),
      _PiketProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Guru Piket'),
        backgroundColor: AppTheme.guruPiketColor,
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
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Catatan'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _PiketHomeTab extends StatelessWidget {
  const _PiketHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.guruPiketColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.access_time, color: AppTheme.guruPiketColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.name ?? 'Guru Piket',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Piket ${now.day}/${now.month}/${now.year}',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruPiketColor),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuickScanPage()),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Absensi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                  onPressed: () => _broadcastDialog(context),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Broadcast'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Siswa Terlambat Hari Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.piketCollection)
                .where('jenis', isEqualTo: 'terlambat')
                .where('tanggal_str',
                    isEqualTo: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppTheme.success),
                    title: Text('Tidak ada siswa terlambat hari ini.'),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: AppTheme.warning),
                      title: Text(d['student_name'] ?? ''),
                      subtitle: Text('Kelas: ${d['kelas'] ?? '-'} • ${d['jam'] ?? ''}'),
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

  void _broadcastDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Broadcast Darurat'),
          ],
        ),
        content: TextField(
          controller: msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ketik pesan darurat...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () async {
              final msg = msgCtrl.text.trim();
              if (msg.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.pengumumanCollection)
                  .add({
                'judul': '⚠️ Pengumuman Darurat',
                'isi': msg,
                'jenis': 'darurat',
                'sender_id': FirebaseAuth.instance.currentUser?.uid,
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

class _PiketCatatanTab extends StatelessWidget {
  const _PiketCatatanTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCatatan(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
        backgroundColor: AppTheme.guruPiketColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.piketCollection)
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada catatan.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final jenis = d['jenis'] ?? '';
              return Card(
                child: ListTile(
                  leading: Icon(
                    jenis == 'terlambat' ? Icons.access_time :
                    jenis == 'izin_pulang' ? Icons.exit_to_app :
                    Icons.event_note,
                    color: jenis == 'terlambat' ? AppTheme.warning :
                           jenis == 'izin_pulang' ? AppTheme.accent :
                           AppTheme.primary,
                  ),
                  title: Text(d['student_name'] ?? ''),
                  subtitle: Text(d['keterangan'] ?? ''),
                  trailing: Text(jenis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addCatatan(BuildContext context) {
    final nameCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    final ketCtrl = TextEditingController();
    String jenis = 'terlambat';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Catatan Harian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Siswa')),
                const SizedBox(height: 8),
                TextField(controller: kelasCtrl,
                    decoration: const InputDecoration(labelText: 'Kelas')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                    DropdownMenuItem(value: 'izin_pulang', child: Text('Izin Pulang')),
                    DropdownMenuItem(value: 'kejadian_khusus', child: Text('Kejadian Khusus')),
                  ],
                  onChanged: (v) => setState(() => jenis = v!),
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                const SizedBox(height: 8),
                TextField(controller: ketCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Keterangan')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.piketCollection)
                    .add({
                  'student_name': nameCtrl.text.trim(),
                  'kelas': kelasCtrl.text.trim(),
                  'jenis': jenis,
                  'keterangan': ketCtrl.text.trim(),
                  'piket_id': FirebaseAuth.instance.currentUser?.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                  'tanggal_str': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                  'jam': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
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

class _PiketProfilTab extends StatelessWidget {
  const _PiketProfilTab();

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
            backgroundColor: AppTheme.guruPiketColor,
            child: Icon(Icons.access_time, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
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
