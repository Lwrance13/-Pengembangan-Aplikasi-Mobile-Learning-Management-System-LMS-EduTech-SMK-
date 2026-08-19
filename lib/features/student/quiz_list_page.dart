import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'quiz_take_page.dart';

class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kelas = context.watch<AuthProvider>().user?.kelas ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis Online'),
        backgroundColor: AppTheme.siswaColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.kuisCollection)
            .where('kelas', isEqualTo: kelas)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text("Belum ada data.", style: TextStyle(color: Color(0xFF6B7280))));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada kuis.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final deadline = (d['deadline'] as Timestamp?)?.toDate();
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.quiz_outlined, color: AppTheme.accent),
                  ),
                  title: Text(d['judul'] ?? ''),
                  subtitle: Text(
                    '${d['mapel'] ?? '-'}'
                    '${deadline != null ? ' • Deadline: ${deadline.day}/${deadline.month}/${deadline.year}' : ''}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizTakePage(kuisId: docs[i].id, kuisData: d),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
