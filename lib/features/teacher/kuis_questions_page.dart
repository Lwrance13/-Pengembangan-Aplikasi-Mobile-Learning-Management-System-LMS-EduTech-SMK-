import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class KuisQuestionsPage extends StatelessWidget {
  final String kuisId;
  final String kuisJudul;

  const KuisQuestionsPage({
    super.key,
    required this.kuisId,
    required this.kuisJudul,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soal: $kuisJudul'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addQuestion(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
        backgroundColor: AppTheme.guruMapelColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.kuisCollection)
            .doc(kuisId)
            .collection(FirebaseConstants.quizQuestionsSub)
            .orderBy('index')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Belum ada soal.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addQuestion(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Soal Pertama'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.guruMapelColor),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final pilihan = List<String>.from(d['pilihan'] ?? []);
              final jawaban = d['jawaban'] as int? ?? 0;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.guruMapelColor,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(d['pertanyaan'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18,
                                color: AppTheme.guruMapelColor),
                            onPressed: () =>
                                _editQuestion(context, docs[i].id, d),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppTheme.danger),
                            onPressed: () => docs[i].reference.delete(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(pilihan.length, (j) {
                        final isCorrect = j == jawaban;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: isCorrect
                                    ? AppTheme.success
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${String.fromCharCode(65 + j)}. ${pilihan[j]}',
                                  style: TextStyle(
                                    color: isCorrect
                                        ? AppTheme.success
                                        : AppTheme.textSecondary,
                                    fontWeight: isCorrect
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

  void _addQuestion(BuildContext context) {
    _showQuestionDialog(context);
  }

  void _editQuestion(
      BuildContext context, String docId, Map<String, dynamic> data) {
    _showQuestionDialog(context, docId: docId, existing: data);
  }

  void _showQuestionDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? existing}) {
    final pertanyaanCtrl =
        TextEditingController(text: existing?['pertanyaan'] ?? '');
    final List<TextEditingController> pilihanCtrls = List.generate(
      4,
      (i) {
        final pilihan = List<String>.from(existing?['pilihan'] ?? []);
        return TextEditingController(text: i < pilihan.length ? pilihan[i] : '');
      },
    );
    int jawaban = existing?['jawaban'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(docId == null ? 'Tambah Soal' : 'Edit Soal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: pertanyaanCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Pilihan Jawaban:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                RadioGroup<int>(
                  groupValue: jawaban,
                  onChanged: (v) => setS(() => jawaban = v!),
                  child: Column(
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              activeColor: AppTheme.success,
                            ),
                            Expanded(
                              child: TextField(
                                controller: pilihanCtrls[i],
                                decoration: InputDecoration(
                                  labelText:
                                      '${String.fromCharCode(65 + i)}${i == jawaban ? ' (Jawaban Benar)' : ''}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const Text(
                  '* Pilih radio di kiri untuk menandai jawaban benar',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.guruMapelColor),
              onPressed: () async {
                final pertanyaan = pertanyaanCtrl.text.trim();
                if (pertanyaan.isEmpty) return;
                final pilihan =
                    pilihanCtrls.map((c) => c.text.trim()).toList();
                if (pilihan.any((p) => p.isEmpty)) return;

                // Get current question count for index
                final col = FirebaseFirestore.instance
                    .collection(FirebaseConstants.kuisCollection)
                    .doc(kuisId)
                    .collection(FirebaseConstants.quizQuestionsSub);

                final data = {
                  'pertanyaan': pertanyaan,
                  'pilihan': pilihan,
                  'jawaban': jawaban,
                };

                if (docId != null) {
                  await col.doc(docId).update(data);
                } else {
                  final snap = await col.count().get();
                  await col.add({...data, 'index': snap.count ?? 0});
                }
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
