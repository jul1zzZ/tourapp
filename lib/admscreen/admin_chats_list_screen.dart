import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'admin_chat_screen.dart';

class AdminChatsListScreen extends StatelessWidget {
  final chatsRef = FirebaseFirestore.instance.collection('chats');

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чаты с пользователями')),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsRef.orderBy('lastMessageTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(child: Text('Нет активных чатов'));
          }

          return ListView.builder(
            itemCount: chats.length,
            padding: EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              final userId = data['userId'] ?? 'Неизвестно';
              final lastMessage = data['lastMessage'] ?? '';
              final lastMessageTime = data['lastMessageTime'] as Timestamp?;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(Icons.chat, color: Colors.white),
                  ),
                  title: Text('Пользователь: $userId',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    lastMessageTime != null
                        ? formatTimestamp(lastMessageTime)
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => AdminChatScreen(
                          chatId: chat.id,
                          adminId: FirebaseAuth.instance.currentUser!.uid,
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
