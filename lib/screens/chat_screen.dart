import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;

  const ChatScreen({super.key, required this.currentUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  late final DocumentReference chatDoc;
  late final CollectionReference msgsRef;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chatDoc = FirebaseFirestore.instance
        .collection('chats')
        .doc('support_chat_${widget.currentUserId}');
    msgsRef = chatDoc.collection('messages');
    _initChat();
  }

  Future<void> _initChat() async {
    final doc = await chatDoc.get();
    if (!doc.exists) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .get();
      final userName = userDoc.data()?['name'] ?? 'Пользователь';
      await chatDoc.set({
        'userId': widget.currentUserId,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': ['support', widget.currentUserId],
        'adminReplied': true,
      });
    }
    await _markRead();
    setState(() => isLoading = false);
  }

  Future<void> _markRead() async {
    final unread =
        await msgsRef
            .where('senderId', isNotEqualTo: widget.currentUserId)
            .where('isRead', isEqualTo: false)
            .get();
    for (var d in unread.docs) {
      await d.reference.update({'isRead': true});
    }
    await chatDoc.update({'adminReplied': true});
  }

  void _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;

    _ctrl.clear();
    await msgsRef.add({
      'senderId': widget.currentUserId,
      'message': txt,
      'sentAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    await chatDoc.update({
      'lastMessage': txt,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'adminReplied': false,
    });
  }

  @override
  Widget build(BuildContext ctx) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Чат с поддержкой')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Чат с поддержкой')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: msgsRef.orderBy('sentAt', descending: true).snapshots(),
              builder: (c, snap) {
                if (!snap.hasData)
                  return Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final d = msgs[i];
                    final m = d.data()! as Map<String, dynamic>;
                    final isMe = m['senderId'] == widget.currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe
                                  ? Colors.blueAccent.withOpacity(0.2)
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(m['message'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Ваше сообщение…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Theme.of(ctx).colorScheme.primary,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
