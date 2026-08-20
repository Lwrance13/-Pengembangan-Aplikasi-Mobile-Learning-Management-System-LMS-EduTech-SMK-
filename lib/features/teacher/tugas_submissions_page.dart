import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class TugasSubmissionsPage extends StatelessWidget {
  final String tugasId;
  final String tugasJudul;

  const TugasSubmissionsPage({
    super.key,
    required this.tugasId,
    required this.tugasJudul,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submission: $tugasJudul'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.tugasCollection)
            .doc(tugasId)
            .collection('submissions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_late_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada siswa yang mengumpulkan.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final ts = (d['submitted_at'] as Timestamp?)?.toDate();
              final nilai = d['nilai'] as num?;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: nilai != null
                                ? AppTheme.success
                                : AppTheme.guruMapelColor,
                            child: Icon(
                              nilai != null
                                  ? Icons.check
                                  : Icons.assignment_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['student_name'] ?? docs[i].id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                if (ts != null)
                                  Text(
                                    '${ts.day}/${ts.month}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          if (nilai != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _nilaiColor(nilai.toDouble()),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${nilai.round()}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            OutlinedButton(
                              onPressed: () =>
                                  _inputNilai(context, docs[i].id, d),
                              child: const Text('Nilai'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('Jawaban Siswa:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d['jawaban'] ?? '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (nilai != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.comment_outlined,
                                size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                d['feedback'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _inputNilai(context, docs[i].id, d),
                              child: const Text('Edit Nilai',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _nilaiColor(double n) {
    if (n >= 80) return AppTheme.success;
    if (n >= 60) return AppTheme.warning;
    return AppTheme.danger;
  }

  void _inputNilai(
      BuildContext context, String docId, Map<String, dynamic> existing) {
    final nilaiCtrl = TextEditingController(
        text: existing['nilai']?.toString() ?? '');
    final feedbackCtrl =
        TextEditingController(text: existing['feedback'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Nilai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nilaiCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nilai (0–100)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan / Feedback',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.guruMapelColor),
            onPressed: () async {
              final nilai = double.tryParse(nilaiCtrl.text.trim());
              if (nilai == null || nilai < 0 || nilai > 100) return;
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.tugasCollection)
                  .doc(tugasId)
                  .collection('submissions')
                  .doc(docId)
                  .update({
                'nilai': nilai,
                'feedback': feedbackCtrl.text.trim(),
                'status': 'graded',
                'graded_at': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
