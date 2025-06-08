import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminChatScreen extends StatefulWidget {
  final String chatId;
  final String adminId;

  const AdminChatScreen({
    super.key,
    required this.chatId,
    required this.adminId,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final DocumentReference chatRef;
  late final CollectionReference messagesRef;

  @override
  void initState() {
    super.initState();
    chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    messagesRef = chatRef.collection('messages');

    _markMessagesAsRead(); // <- прочтение непрочитанных клиентских сообщений
  }

  Future<void> _markMessagesAsRead() async {
    final unreadMessages =
        await messagesRef
            .where('senderId', isNotEqualTo: widget.adminId)
            .where('isRead', isEqualTo: false)
            .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }

    await chatRef.update({'adminReplied': false});
  }

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    await messagesRef.add({
      'senderId': widget.adminId,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'isRead': true, // админские сообщения всегда прочитаны
    });

    await chatRef.update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'adminReplied': true, // админ ответил
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = messagesRef.orderBy('sentAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text('Чат с пользователем')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data()! as Map<String, dynamic>;
                    final isAdmin = data['senderId'] == widget.adminId;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment:
                            isAdmin
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isAdmin
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft:
                                  isAdmin
                                      ? Radius.circular(16)
                                      : Radius.circular(0),
                              bottomRight:
                                  isAdmin
                                      ? Radius.circular(0)
                                      : Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            data['message'] ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 6),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
