import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class QuizTakePage extends StatefulWidget {
  final String kuisId;
  final Map<String, dynamic> kuisData;

  const QuizTakePage({super.key, required this.kuisId, required this.kuisData});

  @override
  State<QuizTakePage> createState() => _QuizTakePageState();
}

class _QuizTakePageState extends State<QuizTakePage> {
  List<QueryDocumentSnapshot>? _questions;
  List<int?> _answers = [];
  int _current = 0;
  bool _loading = true;
  bool _alreadyDone = false;
  int? _finalScore;
  int? _totalQuestions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Cek apakah sudah pernah mengerjakan
    final subSnap = await FirebaseFirestore.instance
        .collection(FirebaseConstants.kuisCollection)
        .doc(widget.kuisId)
        .collection(FirebaseConstants.quizSubmissionsSub)
        .doc(uid)
        .get();
    if (subSnap.exists && mounted) {
      final data = subSnap.data()!;
      setState(() {
        _alreadyDone = true;
        _finalScore = data['score'];
        _totalQuestions = data['total_questions'];
        _loading = false;
      });
      return;
    }

    final qSnap = await FirebaseFirestore.instance
        .collection(FirebaseConstants.kuisCollection)
        .doc(widget.kuisId)
        .collection(FirebaseConstants.quizQuestionsSub)
        .orderBy('index')
        .get();
    if (mounted) {
      setState(() {
        _questions = qSnap.docs;
        _answers = List<int?>.filled(qSnap.docs.length, null);
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_questions == null || _questions!.isEmpty) return;
    if (!mounted) return;

    int benar = 0;
    for (int i = 0; i < _questions!.length; i++) {
      final q = _questions![i].data() as Map<String, dynamic>;
      final correct = q['jawaban'] as int?;
      if (_answers[i] == correct) benar++;
    }
    final score = ((benar / _questions!.length) * 100).round();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ref = FirebaseFirestore.instance
        .collection(FirebaseConstants.kuisCollection)
        .doc(widget.kuisId)
        .collection(FirebaseConstants.quizSubmissionsSub)
        .doc(uid);

    await ref.set({
      'student_id': uid,
      'answers': _answers.whereType<int>().toList(),
      'score': score,
      'total_questions': _questions!.length,
      'submitted_at': FieldValue.serverTimestamp(),
    });

    // Tulis ke koleksi nilai
    await FirebaseFirestore.instance.collection(FirebaseConstants.nilaiCollection).add({
      'student_id': uid,
      'kelas': widget.kuisData['kelas'],
      'mapel': widget.kuisData['mapel'],
      'jenis': 'kuis',
      'judul': widget.kuisData['judul'],
      'nilai': score,
      'guru_id': widget.kuisData['guru_id'],
      'tanggal': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _alreadyDone = true;
        _finalScore = score;
        _totalQuestions = _questions!.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kuisData['judul'] ?? 'Kuis'),
        backgroundColor: AppTheme.accent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_alreadyDone) {
      return _ResultView(score: _finalScore!, total: _totalQuestions!);
    }
    if (_questions == null || _questions!.isEmpty) {
      return const Center(child: Text('Kuis ini belum memiliki soal.'));
    }

    final q = _questions![_current].data() as Map<String, dynamic>;
    final pilihan = List<String>.from(q['pilihan'] ?? []);
    final isLast = _current == _questions!.length - 1;

    return Column(
      children: [
        // Progress
        LinearProgressIndicator(
          value: (_current + 1) / _questions!.length,
          backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
          color: AppTheme.accent,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Soal ${_current + 1} dari ${_questions!.length}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                q['pertanyaan'] ?? '',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...pilihan.asMap().entries.map((e) {
                final idx = e.key;
                final opt = e.value;
                final selected = _answers[_current] == idx;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected ? AppTheme.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: selected ? AppTheme.accent : Colors.grey.shade200,
                      child: Text(
                        String.fromCharCode(65 + idx),
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(opt),
                    onTap: () => setState(() => _answers[_current] = idx),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_current > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _current--),
                    child: const Text('Sebelumnya'),
                  ),
                ),
              if (_current > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  onPressed: _answers[_current] == null
                      ? null
                      : () {
                          if (isLast) {
                            _submit();
                          } else {
                            setState(() => _current++);
                          }
                        },
                  child: Text(isLast ? 'Kumpulkan' : 'Selanjutnya'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;

  const _ResultView({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final passed = score >= 75;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.replay,
              size: 72,
              color: passed ? AppTheme.success : AppTheme.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Skor Kamu',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: passed ? AppTheme.success : AppTheme.warning,
              ),
            ),
            Text(
              'dari $total soal',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'Selamat, kamu lulus kuis ini! 🎉' : 'Belum lulus. Coba lagi lain waktu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: passed ? AppTheme.success : AppTheme.warning,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
