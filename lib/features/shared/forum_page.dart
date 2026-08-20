import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';

class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Diskusi'),
        backgroundColor: AppTheme.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newThread(context),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Topik Baru'),
        backgroundColor: AppTheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.forumCollection)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          // sort by timestamp desc in memory (no composite index needed)
          final sorted = [...docs]..sort((a, b) {
              final ta = (a.data() as Map)['timestamp'] as Timestamp?;
              final tb = (b.data() as Map)['timestamp'] as Timestamp?;
              if (ta == null || tb == null) return 0;
              return tb.compareTo(ta);
            });
          if (sorted.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada diskusi.\nBuat topik baru!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = sorted[i].data() as Map<String, dynamic>;
              final ts = (d['timestamp'] as Timestamp?)?.toDate();
              final replies = d['replies_count'] as int? ?? 0;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.forum_outlined, color: AppTheme.primary),
                  ),
                  title: Text(d['judul'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d['mapel'] ?? '-'} • ${d['author_name'] ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (ts != null)
                        Text(
                          '${ts.day}/${ts.month}/${ts.year}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 16, color: AppTheme.textSecondary),
                      Text('$replies',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForumThreadPage(
                          threadId: sorted[i].id, threadData: d),
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

  void _newThread(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final judulCtrl = TextEditingController();
    final isiCtrl = TextEditingController();
    final mapelCtrl = TextEditingController(
        text: auth.user?.mapel ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Topik Diskusi Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(
                    labelText: 'Judul Topik',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mapelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: isiCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Isi / Pertanyaan',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              if (judulCtrl.text.trim().isEmpty ||
                  isiCtrl.text.trim().isEmpty) {
                return;
              }
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.forumCollection)
                  .add({
                'judul': judulCtrl.text.trim(),
                'isi': isiCtrl.text.trim(),
                'mapel': mapelCtrl.text.trim(),
                'author_id': FirebaseAuth.instance.currentUser?.uid,
                'author_name': auth.user?.name ?? 'Anonim',
                'author_role': auth.user?.role ?? '',
                'kelas': auth.user?.kelas ?? '',
                'replies_count': 0,
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Posting'),
          ),
        ],
      ),
    );
  }
}

class ForumThreadPage extends StatefulWidget {
  final String threadId;
  final Map<String, dynamic> threadData;

  const ForumThreadPage(
      {super.key, required this.threadId, required this.threadData});

  @override
  State<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends State<ForumThreadPage> {
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    _replyCtrl.clear();
    final ref = FirebaseFirestore.instance
        .collection(FirebaseConstants.forumCollection)
        .doc(widget.threadId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['replies_count'] as int?) ?? 0;
      tx.update(ref, {'replies_count': current + 1});
      tx.set(ref.collection('replies').doc(), {
        'text': text,
        'author_id': uid,
        'author_name': auth.user?.name ?? 'Anonim',
        'author_role': auth.user?.role ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.threadData;
    return Scaffold(
      appBar: AppBar(
        title: Text(d['judul'] ?? 'Diskusi',
            overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(
        children: [
          // Original post
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        (d['author_name'] as String? ?? 'A')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['author_name'] ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(
                          '${d['mapel'] ?? '-'} • ${d['kelas'] ?? '-'}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(d['isi'] ?? '', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Replies
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.forumCollection)
                  .doc(widget.threadId)
                  .collection('replies')
                  .snapshots(),
              builder: (context, snap) {
                final replies = snap.data?.docs ?? [];
                final sorted = [...replies]..sort((a, b) {
                    final ta =
                        (a.data() as Map)['timestamp'] as Timestamp?;
                    final tb =
                        (b.data() as Map)['timestamp'] as Timestamp?;
                    if (ta == null || tb == null) return 0;
                    return ta.compareTo(tb);
                  });
                if (sorted.isEmpty) {
                  return const Center(
                    child: Text('Belum ada balasan.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }
                return ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r =
                        sorted[i].data() as Map<String, dynamic>;
                    final isMe = r['author_id'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    final ts =
                        (r['timestamp'] as Timestamp?)?.toDate();
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['author_name'] ?? '-',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isMe
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(r['text'] ?? ''),
                            if (ts != null)
                              Text(
                                '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tulis balasan...',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendReply,
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
