import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

/// Halaman transparansi poin pelanggaran untuk siswa
class PelanggaranSiswaPage extends StatelessWidget {
  const PelanggaranSiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Pelanggaranku'),
        backgroundColor: AppTheme.danger,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.pelanggaranCollection)
            .where('student_id', isEqualTo: uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];

          // Hitung total poin
          final totalPoin = docs.fold<int>(
              0, (total, doc) => total + ((doc.data() as Map)['poin'] as int? ?? 0));

          return Column(
            children: [
              // Poin Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: totalPoin >= 80
                    ? AppTheme.danger
                    : totalPoin >= 50
                        ? AppTheme.warning
                        : AppTheme.success,
                child: Column(
                  children: [
                    Text(
                      '$totalPoin',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const Text('Total Poin Pelanggaran',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      totalPoin >= 80
                          ? '⚠️ KRITIS — Segera hubungi Guru BK'
                          : totalPoin >= 50
                              ? '⚠️ Waspada — Jaga perilaku'
                              : '✅ Baik — Pertahankan!',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (totalPoin / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Batas Maksimum: 100 Poin',
                        style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              // List pelanggaran
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: AppTheme.success),
                            SizedBox(height: 12),
                            Text('Tidak ada catatan pelanggaran!',
                                style: TextStyle(color: AppTheme.success, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          final poin = d['poin'] as int? ?? 0;
                          final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: poin >= 20 ? AppTheme.danger : AppTheme.warning,
                                child: Text('+$poin',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(d['deskripsi'] ?? ''),
                              subtitle: Text(
                                '${d['jenis'] ?? ''} • ${tanggal != null ? '${tanggal.day}/${tanggal.month}/${tanggal.year}' : '-'}',
                                style: const TextStyle(fontSize: 12),
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
}
