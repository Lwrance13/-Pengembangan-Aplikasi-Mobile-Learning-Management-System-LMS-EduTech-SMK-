import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class ChatRoomPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isConfidential;

  const ChatRoomPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.isConfidential = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _db = FirebaseFirestore.instance;
  final User _currentUser = FirebaseAuth.instance.currentUser!;

  String get _chatId {
    final ids = [_currentUser.uid, widget.otherUserId]..sort();
    return ids.join('_');
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    await _db
        .collection(FirebaseConstants.chatCollection)
        .doc(_chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender_id': _currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'is_confidential': widget.isConfidential,
    });

    await _db.collection(FirebaseConstants.chatCollection).doc(_chatId).set({
      'participants': [_currentUser.uid, widget.otherUserId],
      'last_message': text,
      'last_timestamp': FieldValue.serverTimestamp(),
      'is_confidential': widget.isConfidential,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.isConfidential)
              const Icon(Icons.lock, size: 16, color: Colors.white),
            if (widget.isConfidential) const SizedBox(width: 6),
            Text(widget.otherUserName),
          ],
        ),
        backgroundColor:
            widget.isConfidential ? AppTheme.guruBkColor : AppTheme.primary,
      ),
      body: Column(
        children: [
          if (widget.isConfidential)
            Container(
              width: double.infinity,
              color: AppTheme.guruBkColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Text(
                '🔒 Percakapan ini bersifat rahasia dan terenkripsi',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.guruBkColor),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection(FirebaseConstants.chatCollection)
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i].data() as Map<String, dynamic>;
                    final isMe = msg['sender_id'] == _currentUser.uid;
                    return _MessageBubble(
                      text: msg['text'] ?? '',
                      isMe: isMe,
                      timestamp: (msg['timestamp'] as Timestamp?)?.toDate(),
                    );
                  },
                );
              },
            ),
          ),
          _MessageInput(controller: _msgCtrl, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? timestamp;

  const _MessageBubble(
      {required this.text, required this.isMe, this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.zero : null,
            bottomLeft: isMe ? null : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text,
                style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary)),
            if (timestamp != null)
              Text(
                '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: onSend,
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
