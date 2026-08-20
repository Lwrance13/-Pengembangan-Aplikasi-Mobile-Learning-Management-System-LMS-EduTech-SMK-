import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';
import 'package:provider/provider.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  static const List<String> _hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu',
  ];

  @override
  Widget build(BuildContext context) {
    final kelas = context.watch<AuthProvider>().user?.kelas ?? '';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jadwal'),
          backgroundColor: AppTheme.siswaColor,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'Pelajaran'),
              Tab(icon: Icon(Icons.cleaning_services_outlined), text: 'Piket Kelas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JadwalPelajaranTab(kelas: kelas, hari: _hari),
            _JadwalPiketTab(kelas: kelas),
          ],
        ),
      ),
    );
  }
}

class _JadwalPelajaranTab extends StatelessWidget {
  final String kelas;
  final List<String> hari;
  const _JadwalPelajaranTab({required this.kelas, required this.hari});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.jadwalCollection)
          .where('kelas', isEqualTo: kelas)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: _EmptyState(icon: Icons.calendar_today, message: 'Belum ada jadwal untuk kelas ini.'));
        }
        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (final doc in docs) {
          final h = (doc.data() as Map)['hari'] as String? ?? '-';
          grouped.putIfAbsent(h, () => []).add(doc);
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: hari.where((h) => grouped.containsKey(h)).map((h) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                ),
                ...grouped[h]!.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.siswaColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule, color: AppTheme.siswaColor),
                      ),
                      title: Text(d['mapel'] ?? ''),
                      subtitle: Text(
                        '${d['jam_mulai'] ?? d['jam'] ?? ''}-${d['jam_selesai'] ?? ''} • ${d['guru'] ?? d['guru_name'] ?? '-'}\n${d['ruang'] ?? ''}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class _JadwalPiketTab extends StatelessWidget {
  final String kelas;
  const _JadwalPiketTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.piketCollection)
          .where('kelas', isEqualTo: kelas)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: _EmptyState(
              icon: Icons.cleaning_services_outlined,
              message: 'Belum ada catatan piket untuk kelas ini.',
            ),
          );
        }
        // Sort by timestamp desc
        final sorted = [...docs]..sort((a, b) {
            final ta = (a.data() as Map)['timestamp'] as Timestamp?;
            final tb = (b.data() as Map)['timestamp'] as Timestamp?;
            if (ta == null || tb == null) return 0;
            return tb.compareTo(ta);
          });
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.siswaColor.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan harian piket kelas — keterlambatan, izin, & kejadian khusus.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final d = sorted[i].data() as Map<String, dynamic>;
                  final jenis = d['jenis'] ?? '';
                  final ts = (d['timestamp'] as Timestamp?)?.toDate();
                  Color color;
                  IconData icon;
                  switch (jenis) {
                    case 'terlambat':
                      color = AppTheme.warning; icon = Icons.access_time;
                      break;
                    case 'izin_pulang':
                      color = AppTheme.accent; icon = Icons.exit_to_app;
                      break;
                    default:
                      color = AppTheme.primary; icon = Icons.event_note;
                  }
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      title: Text(d['student_name'] ?? ''),
                      subtitle: Text(
                        '${_jenisLabel(jenis)} • ${d['keterangan'] ?? ''}'
                        '${ts != null ? '\n${ts.day}/${ts.month}/${ts.year} ${d['jam'] ?? ''}' : ''}',
                      ),
                      isThreeLine: ts != null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _jenisLabel(String jenis) {
    switch (jenis) {
      case 'terlambat': return 'Terlambat';
      case 'izin_pulang': return 'Izin Pulang';
      case 'kejadian_khusus': return 'Kejadian Khusus';
      default: return jenis;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
      ],
    );
  }
}

