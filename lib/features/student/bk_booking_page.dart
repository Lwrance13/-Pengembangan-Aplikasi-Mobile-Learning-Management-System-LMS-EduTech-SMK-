import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';

class BkBookingPage extends StatefulWidget {
  const BkBookingPage({super.key});

  @override
  State<BkBookingPage> createState() => _BkBookingPageState();
}

class _BkBookingPageState extends State<BkBookingPage> {
  String _selectedKategori = 'Akademik';
  final _deskripsiCtrl = TextEditingController();
  bool _loading = false;

  static const _kategoriList = [
    'Akademik', 'Sosial', 'Pribadi', 'Karir', 'Pelanggaran',
  ];

  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _booking() async {
    if (_deskripsiCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Cari Guru BK
      final bkSnap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'GURU_BK')
          .limit(1)
          .get();
      final bkId = bkSnap.docs.isNotEmpty ? bkSnap.docs.first.id : null;

      await FirebaseFirestore.instance
          .collection(FirebaseConstants.konselingCollection)
          .add({
        'student_id': uid,
        'student_name': auth.user?.name ?? '',
        'bk_id': bkId,
        'kategori': _selectedKategori,
        'deskripsi': _deskripsiCtrl.text.trim(),
        'status': 'pending',
        'tanggal': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking konseling berhasil! Tunggu konfirmasi Guru BK.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _deskripsiCtrl.clear();
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Konseling BK'),
        backgroundColor: AppTheme.guruBkColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppTheme.guruBkColor.withValues(alpha: 0.08),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: AppTheme.guruBkColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Konseling bersifat RAHASIA. Tidak ada yang bisa membaca percakapanmu selain Guru BK.',
                        style: TextStyle(color: AppTheme.guruBkColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Buat Booking Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Kategori Masalah:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _kategoriList.map((k) => ChoiceChip(
                label: Text(k),
                selected: _selectedKategori == k,
                selectedColor: AppTheme.guruBkColor.withValues(alpha: 0.2),
                onSelected: (_) => setState(() => _selectedKategori = k),
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deskripsiCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ceritakan masalahmu (opsional)',
                hintText: 'Tulis secara singkat...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.guruBkColor),
                onPressed: _loading ? null : _booking,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.calendar_month),
                label: const Text('Kirim Booking'),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Riwayat Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.konselingCollection)
                  .where('student_id', isEqualTo: uid).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Card(child: ListTile(title: Text('Belum ada riwayat booking.')));
                }
                return Column(
                  children: snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? 'pending';
                    final tanggal = (d['tanggal'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(status),
                          child: Icon(_statusIcon(status), color: Colors.white, size: 18),
                        ),
                        title: Text(d['kategori'] ?? ''),
                        subtitle: Text(tanggal != null
                            ? '${tanggal.day}/${tanggal.month}/${tanggal.year}'
                            : 'Menunggu...'),
                        trailing: Chip(
                          label: Text(status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: _statusColor(status),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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
}
