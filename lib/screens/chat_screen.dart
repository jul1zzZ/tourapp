import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;

  const ChatScreen({super.key, required this.currentUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    chatId = 'support_chat_${widget.currentUserId}';
    final chatRef = _firestore.collection('chats').doc(chatId);
    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        'userId': widget.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': ['support', widget.currentUserId],
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': widget.currentUserId,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат с поддержкой')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final messagesRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат с поддержкой'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Нет сообщений. Напишите нам!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data()! as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;
                    final messageText = data['message'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          messageText,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isMe
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      hintText: 'Введите сообщение...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sendMessage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
