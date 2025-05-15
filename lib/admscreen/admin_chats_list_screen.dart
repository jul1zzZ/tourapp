import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_chat_screen.dart';

class AdminChatsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    return Scaffold(
      appBar: AppBar(title: Text('Чаты с пользователями')),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsRef.orderBy('lastMessageTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) return Center(child: Text('Нет активных чатов'));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              return ListTile(
                leading: Icon(Icons.chat_bubble_outline),
                title: Text('Пользователь: ${data['userId'] ?? 'Неизвестно'}'),
                subtitle: Text(data['lastMessage'] ?? ''),               
                      trailing: Text(
                    data['lastMessageTime'] != null
                        ? TimeOfDay.fromDateTime((data['lastMessageTime'] as Timestamp).toDate()).format(context)
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminChatScreen(
                        chatId: chat.id,
                        adminId: FirebaseAuth.instance.currentUser!.uid,
                      ),
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

