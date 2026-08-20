import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class NilaiPage extends StatelessWidget {
  const NilaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Nilai'),
        backgroundColor: AppTheme.siswaColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.nilaiCollection)
            .where('student_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Belum ada nilai.', style: TextStyle(color: AppTheme.textSecondary)));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada nilai.'));
          }

          // Hitung rata-rata per mapel
          final byMapel = <String, List<double>>{};
          for (final doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            final mapel = d['mapel'] as String? ?? '-';
            final nilai = (d['nilai'] as num?)?.toDouble() ?? 0;
            byMapel.putIfAbsent(mapel, () => []).add(nilai);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Ringkasan rata-rata per mapel
              const Text('Rata-rata per Mapel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...byMapel.entries.map((e) {
                final avg = e.value.reduce((a, b) => a + b) / e.value.length;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colorForNilai(avg),
                      child: Text(avg.round().toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(e.key),
                    subtitle: Text('${e.value.length} penilaian'),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('Riwayat Nilai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final nilai = (d['nilai'] as num?)?.toDouble() ?? 0;
                final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colorForNilai(nilai),
                      child: Text(nilai.round().toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(d['judul'] ?? d['jenis'] ?? 'Nilai'),
                    subtitle: Text(
                      '${d['mapel'] ?? '-'} • ${d['jenis'] ?? '-'}'
                      '${tanggal != null ? ' • ${tanggal.day}/${tanggal.month}/${tanggal.year}' : ''}',
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Color _colorForNilai(double n) {
    if (n >= 80) return AppTheme.success;
    if (n >= 60) return AppTheme.warning;
    return AppTheme.danger;
  }
}
