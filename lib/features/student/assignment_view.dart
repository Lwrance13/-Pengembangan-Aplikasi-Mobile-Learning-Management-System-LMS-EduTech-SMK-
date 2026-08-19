import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class AssignmentView extends StatefulWidget {
  final String tugasId;
  final Map<String, dynamic> tugasData;

  const AssignmentView({super.key, required this.tugasId, required this.tugasData});

  @override
  State<AssignmentView> createState() => _AssignmentViewState();
}

class _AssignmentViewState extends State<AssignmentView> {
  final _jawabanCtrl = TextEditingController();
  bool _submitted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkSubmission();
  }

  Future<void> _checkSubmission() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance
        .collection(FirebaseConstants.tugasCollection)
        .doc(widget.tugasId)
        .collection('submissions')
        .doc(uid)
        .get();
    if (snap.exists) {
      setState(() {
        _submitted = true;
        _jawabanCtrl.text = snap.data()?['jawaban'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (_jawabanCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.tugasCollection)
        .doc(widget.tugasId)
        .collection('submissions')
        .doc(uid)
        .set({
      'jawaban': _jawabanCtrl.text.trim(),
      'student_id': uid,
      'submitted_at': FieldValue.serverTimestamp(),
      'status': 'submitted',
    });
    setState(() {
      _submitted = true;
      _loading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil dikumpulkan!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.tugasData;
    final deadline = (d['deadline'] as Timestamp?)?.toDate();
    return Scaffold(
      appBar: AppBar(
        title: Text(d['judul'] ?? 'Tugas'),
        backgroundColor: AppTheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['judul'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.book_outlined, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(d['mapel'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 16, color: AppTheme.warning),
                        const SizedBox(width: 4),
                        Text(
                          deadline != null ? '${deadline.day}/${deadline.month}/${deadline.year}' : '-',
                          style: const TextStyle(color: AppTheme.warning),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(d['deskripsi'] ?? 'Tidak ada deskripsi.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _submitted ? 'Jawaban Kamu' : 'Kerjakan Tugas',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jawabanCtrl,
              maxLines: 8,
              readOnly: _submitted,
              decoration: InputDecoration(
                hintText: 'Tulis jawabanmu di sini...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: _submitted ? Colors.grey.shade100 : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_submitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success),
                    SizedBox(width: 8),
                    Text('Tugas sudah dikumpulkan',
                        style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: const Text('Kumpulkan Tugas'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
