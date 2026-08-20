import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_provider.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

/// Widget alert sistem cerdas untuk Wali Kelas.
/// Menampilkan notifikasi otomatis ketika siswa:
/// - Alpha > 3x
/// - Nilai drop >20% dibanding rata-rata sebelumnya
/// - Poin pelanggaran >= 80 (mendekati batas maksimum 100)
class AlertSystemWidget extends StatelessWidget {
  const AlertSystemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kelas = auth.user?.kelas ?? '';

    if (kelas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlphaAlert(kelas: kelas),
        _NilaiDropAlert(kelas: kelas),
        _PelanggaranAlert(kelas: kelas),
      ],
    );
  }
}

class _AlphaAlert extends StatelessWidget {
  final String kelas;
  const _AlphaAlert({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'SISWA')
          .where('kelas', isEqualTo: kelas)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        final students = userSnap.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAlphaStudents(students),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
            return _AlertCard(
              icon: Icons.person_off_outlined,
              title: '⚠️ Alert Alpha',
              color: AppTheme.warning,
              items: snap.data!
                  .map((s) => '${s['name']} — Alpha ${s['count']}x')
                  .toList(),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAlphaStudents(
      List<QueryDocumentSnapshot> students) async {
    final result = <Map<String, dynamic>>[];
    for (final student in students) {
      final snap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.absensiCollection)
          .where('student_id', isEqualTo: student.id)
          .where('status', isEqualTo: 'alpha')
          .get();
      if (snap.docs.length > 3) {
        result.add({
          'name': (student.data() as Map)['name'] ?? '',
          'count': snap.docs.length,
        });
      }
    }
    return result;
  }
}

class _NilaiDropAlert extends StatelessWidget {
  final String kelas;
  const _NilaiDropAlert({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getDropStudents(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        return _AlertCard(
          icon: Icons.trending_down,
          title: '📉 Alert Nilai Drop >20%',
          color: AppTheme.accent,
          items: snap.data!,
        );
      },
    );
  }

  Future<List<String>> _getDropStudents() async {
    // Get all students in this class
    final studentsSnap = await FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .where('role', isEqualTo: 'SISWA')
        .where('kelas', isEqualTo: kelas)
        .get();

    final result = <String>[];
    for (final student in studentsSnap.docs) {
      final name = (student.data())['name'] as String? ?? '';
      // Get nilai sorted by time for this student
      final nilaiSnap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.nilaiCollection)
          .where('student_id', isEqualTo: student.id)
          .get();
      if (nilaiSnap.docs.length < 2) continue;

      final sorted = nilaiSnap.docs.toList()
        ..sort((a, b) {
          final ta = (a.data())['tanggal'] as Timestamp?;
          final tb = (b.data())['tanggal'] as Timestamp?;
          if (ta == null || tb == null) return 0;
          return ta.compareTo(tb);
        });

      // Compare latest vs previous nilai
      final latest = ((sorted.last.data())['nilai'] as num?)?.toDouble() ?? 0;
      final previous = ((sorted[sorted.length - 2].data())['nilai'] as num?)?.toDouble() ?? 0;

      if (previous > 0 && (previous - latest) / previous > 0.20) {
        result.add('$name — ${previous.round()} → ${latest.round()} (drop ${(((previous - latest) / previous) * 100).round()}%)');
      }
    }
    return result;
  }
}

class _PelanggaranAlert extends StatelessWidget {
  final String kelas;
  const _PelanggaranAlert({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.pelanggaranCollection)
          .where('kelas', isEqualTo: kelas)
          .where('poin', isGreaterThanOrEqualTo: 80)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final alerts = snapshot.data!.docs;
        return _AlertCard(
          icon: Icons.warning_amber_outlined,
          title: '🚨 Alert Pelanggaran Kritis',
          color: AppTheme.danger,
          items: alerts
              .map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return '${d['student_name'] ?? '-'} — Poin: ${d['poin']}';
              })
              .toList(),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _AlertCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• $item',
                style: TextStyle(color: color, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
