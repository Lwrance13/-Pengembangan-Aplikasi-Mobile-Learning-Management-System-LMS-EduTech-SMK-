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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran'),
        backgroundColor: AppTheme.siswaColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.jadwalCollection)
            .where('kelas', isEqualTo: kelas)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: _EmptyState(icon: Icons.calendar_today, message: 'Jadwal belum tersedia.'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: _EmptyState(icon: Icons.calendar_today, message: 'Belum ada jadwal untuk kelas ini.'));
          }
          // Kelompokkan per hari
          final grouped = <String, List<QueryDocumentSnapshot>>{};
          for (final doc in docs) {
            final hari = (doc.data() as Map)['hari'] as String? ?? '-';
            grouped.putIfAbsent(hari, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: _hari.where((h) => grouped.containsKey(h)).map((hari) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(hari,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  ),
                  ...grouped[hari]!.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.siswaColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.schedule, color: AppTheme.siswaColor),
                        ),
                        title: Text(d['mapel'] ?? ''),
                        subtitle: Text(
                          '${d['jam'] ?? ''} • ${d['guru'] ?? d['guru_name'] ?? '-'}\n${d['ruang'] ?? ''}',
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
      ),
    );
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

