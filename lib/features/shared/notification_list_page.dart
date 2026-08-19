import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tandai semua dibaca',
            onPressed: () => _markAllRead(uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.notifikasiCollection)
            .where('user_id', isEqualTo: uid).limit(50).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada notifikasi',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          final notifs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = notifs[i].data() as Map<String, dynamic>;
              final isRead = data['is_read'] ?? false;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              return _NotifCard(
                title: data['title'] ?? '',
                body: data['body'] ?? '',
                type: data['type'] ?? 'info',
                isRead: isRead,
                timestamp: timestamp,
                onTap: () => _markRead(notifs[i].id),
              );
            },
          );
        },
      ),
    );
  }

  void _markRead(String docId) {
    FirebaseFirestore.instance
        .collection(FirebaseConstants.notifikasiCollection)
        .doc(docId)
        .update({'is_read': true});
  }

  void _markAllRead(String? uid) {
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection(FirebaseConstants.notifikasiCollection)
        .where('user_id', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .get()
        .then((snap) {
      for (final doc in snap.docs) {
        doc.reference.update({'is_read': true});
      }
    });
  }
}

class _NotifCard extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? timestamp;
  final VoidCallback onTap;

  const _NotifCard({
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.timestamp,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case 'tugas':
        return Icons.assignment_outlined;
      case 'absensi':
        return Icons.how_to_reg_outlined;
      case 'pelanggaran':
        return Icons.warning_amber_outlined;
      case 'konseling':
        return Icons.psychology_outlined;
      case 'darurat':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (type) {
      case 'tugas':
        return AppTheme.primary;
      case 'absensi':
        return AppTheme.success;
      case 'pelanggaran':
        return AppTheme.danger;
      case 'konseling':
        return AppTheme.guruBkColor;
      case 'darurat':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isRead ? Colors.white : _color.withValues(alpha: 0.05),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, color: _color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (timestamp != null)
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(timestamp!),
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
              ),
        isThreeLine: true,
      ),
    );
  }
}
