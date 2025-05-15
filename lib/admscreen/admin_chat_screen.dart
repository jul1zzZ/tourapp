import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminChatScreen extends StatelessWidget {
  final String chatId;
  final String adminId;

  AdminChatScreen({required this.chatId, required this.adminId});

  final TextEditingController _controller = TextEditingController();

  void _sendMessage(BuildContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': adminId,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text('Чат с пользователем')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data()! as Map<String, dynamic>;
                    final isAdmin = data['senderId'] == adminId;

                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.green[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data['message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(context),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
