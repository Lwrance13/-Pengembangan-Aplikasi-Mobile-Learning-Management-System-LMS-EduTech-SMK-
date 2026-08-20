import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/services/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/firebase_constants.dart';
import '../shared/notification_list_page.dart';
import '../shared/chat_room_page.dart';
import 'case_tracking_page.dart';

class BkDashboardPage extends StatefulWidget {
  const BkDashboardPage({super.key});

  @override
  State<BkDashboardPage> createState() => _BkDashboardPageState();
}

class _BkDashboardPageState extends State<BkDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _BkHomeTab(),
      _BkKonselingTab(),
      CaseTrackingPage(),
      _BkPelanggaranTab(),
      _BkProfilTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Guru BK'),
        backgroundColor: AppTheme.guruBkColor,
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
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Konseling'),
          NavigationDestination(icon: Icon(Icons.track_changes_outlined), label: 'Kasus'),
          NavigationDestination(icon: Icon(Icons.gavel_outlined), label: 'Pelanggaran'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: 'Profil'),
        ],
      ),
    );
  }
}

class _BkHomeTab extends StatelessWidget {
  const _BkHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.guruBkColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.psychology, color: AppTheme.guruBkColor, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.name ?? 'Guru BK',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Bimbingan & Konseling',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Booking yang masuk
          const Text('Booking Konseling Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.konselingCollection)
                .where('bk_id', isEqualTo: uid)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(child: ListTile(
                  leading: Icon(Icons.check_circle, color: AppTheme.success),
                  title: Text('Tidak ada booking baru.'),
                ));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline, color: AppTheme.guruBkColor),
                      title: Text(d['student_name'] ?? 'Siswa'),
                      subtitle: Text(d['kategori'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: AppTheme.success),
                            onPressed: () => doc.reference.update({'status': 'approved'}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: AppTheme.danger),
                            onPressed: () => doc.reference.update({'status': 'rejected'}),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Chat Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.chatCollection)
                .where('participants', arrayContains: uid)
                .where('is_confidential', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
              final chats = snapshot.data!.docs;
              if (chats.isEmpty) return const Card(child: ListTile(title: Text('Belum ada percakapan.')));
              return Column(
                children: chats.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final participants = List<String>.from(d['participants'] ?? []);
                  final studentId = participants.firstWhere((id) => id != uid, orElse: () => '');
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.guruBkColor,
                        child: Icon(Icons.lock, color: Colors.white, size: 16),
                      ),
                      title: Text(d['student_name'] ?? 'Siswa'),
                      subtitle: Text(d['last_message'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            otherUserId: studentId,
                            otherUserName: d['student_name'] ?? 'Siswa',
                            isConfidential: true,
                          ),
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

class _BkKonselingTab extends StatelessWidget {
  const _BkKonselingTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addJadwal(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
        backgroundColor: AppTheme.guruBkColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.konselingCollection)
            .where('bk_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada jadwal konseling.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
              final status = d['status'] ?? 'pending';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(status),
                    child: Icon(_statusIcon(status), color: Colors.white, size: 18),
                  ),
                  title: Text(d['student_name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori: ${d['kategori'] ?? '-'}'),
                      if (tanggal != null)
                        Text('${tanggal.day}/${tanggal.month}/${tanggal.year} ${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: _statusColor(status),
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

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.danger;
      case 'done': return AppTheme.textSecondary;
      default: return AppTheme.warning;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'done': return Icons.task_alt;
      default: return Icons.schedule;
    }
  }

  void _addJadwal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Jadwal Konseling'),
        content: Text('Gunakan tab Beranda untuk menyetujui booking dari siswa.'),
      ),
    );
  }
}

class _BkPelanggaranTab extends StatelessWidget {
  const _BkPelanggaranTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.pelanggaranCollection)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          // Sort by poin desc in memory
          final sorted = [...docs]..sort((a, b) {
              final pa = (a.data() as Map)['poin'] as int? ?? 0;
              final pb = (b.data() as Map)['poin'] as int? ?? 0;
              return pb.compareTo(pa);
            });
          if (sorted.isEmpty) {
            return const Center(child: Text('Belum ada catatan pelanggaran.'));
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppTheme.guruBkColor.withValues(alpha: 0.08),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_outlined, color: AppTheme.guruBkColor, size: 18),
                    SizedBox(width: 8),
                    Text('Verifikasi & Penanganan Pelanggaran',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.guruBkColor)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = sorted[i].data() as Map<String, dynamic>;
                    final poin = d['poin'] as int? ?? 0;
                    final verified = d['bk_verified'] as bool? ?? false;
                    final ts = (d['tanggal'] as Timestamp?)?.toDate();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: poin >= 80 ? AppTheme.danger : AppTheme.warning,
                                  child: Text('$poin',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d['student_name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('${d['kelas'] ?? '-'} • ${d['jenis'] ?? '-'}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (verified)
                                  const Chip(
                                    label: Text('Terverifikasi',
                                        style: TextStyle(color: Colors.white, fontSize: 10)),
                                    backgroundColor: AppTheme.success,
                                  )
                                else
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.guruBkColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 12)),
                                    onPressed: () => _showVerifyDialog(context, sorted[i].id, d),
                                    child: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
                                  ),
                              ],
                            ),
                            if ((d['deskripsi'] as String? ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(d['deskripsi'] ?? '',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                            if (ts != null)
                              Text('${ts.day}/${ts.month}/${ts.year}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            if (verified && (d['bk_catatan'] as String? ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.psychology_outlined, size: 14, color: AppTheme.guruBkColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text('Catatan BK: ${d['bk_catatan'] ?? ''}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.guruBkColor)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVerifyDialog(BuildContext context, String docId, Map<String, dynamic> existing) {
    final catatanCtrl = TextEditingController(text: existing['bk_catatan'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Pelanggaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Siswa: ${existing['student_name'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Jenis: ${existing['jenis'] ?? '-'} • Poin: ${existing['poin'] ?? 0}'),
            const SizedBox(height: 12),
            TextField(
              controller: catatanCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan / Rekomendasi BK',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Siswa telah dipanggil, diberikan bimbingan...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruBkColor),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.pelanggaranCollection)
                  .doc(docId)
                  .update({
                'bk_verified': true,
                'bk_catatan': catatanCtrl.text.trim(),
                'bk_verified_at': FieldValue.serverTimestamp(),
                'bk_id': FirebaseAuth.instance.currentUser?.uid,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Verifikasi & Simpan'),
          ),
        ],
      ),
    );
  }
}

class _BkProfilTab extends StatelessWidget {
  const _BkProfilTab();

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
            backgroundColor: AppTheme.guruBkColor,
            child: Icon(Icons.psychology, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
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
