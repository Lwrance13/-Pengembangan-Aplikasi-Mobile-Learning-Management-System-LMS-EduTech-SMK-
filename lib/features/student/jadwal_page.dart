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
            .orderBy('hari_index')
            .orderBy('jam_mulai')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada jadwal untuk kelas ini.'));
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
                    child: Text(
                      hari,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
                          '${d['jam_mulai'] ?? ''} - ${d['jam_selesai'] ?? ''} • ${d['guru_name'] ?? '-'}',
                        ),
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
