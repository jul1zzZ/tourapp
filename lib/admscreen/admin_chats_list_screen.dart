import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'admin_chat_screen.dart';

class AdminChatsListScreen extends StatelessWidget {
  final chatsRef = FirebaseFirestore.instance.collection('chats');

  AdminChatsListScreen({super.key});

  String formatTimestamp(Timestamp ts) {
    final date = ts.toDate();
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return DateFormat('HH:mm').format(date);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext ctx) {
    final currentAdminId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text('Чаты с пользователями')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            chatsRef.orderBy('lastMessageTime', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final userName =
                  data['userName'] ?? data['userId'] ?? 'Пользователь';
              final lastMsg = data['lastMessage'] ?? '';
              final lastTime = data['lastMessageTime'] as Timestamp?;
              final adminReplied = data['adminReplied'] ?? true;

              final unreadQuery = doc.reference
                  .collection('messages')
                  .where('senderId', isEqualTo: data['userId'])
                  .where('isRead', isEqualTo: false);

              return StreamBuilder<QuerySnapshot>(
                stream: unreadQuery.snapshots(),
                builder: (c, s2) {
                  final hasUnread = s2.data?.docs.isNotEmpty ?? false;
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        child: Icon(Icons.chat, color: Colors.white),
                      ),
                      title: Text(
                        'Пользователь: $userName',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastTime != null)
                            Text(
                              formatTimestamp(lastTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasUnread)
                                Icon(
                                  Icons.mark_chat_unread,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                              if (!adminReplied)
                                Icon(
                                  Icons.feedback,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AdminChatScreen(
                                  chatId: doc.id,
                                  adminId: currentAdminId,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
