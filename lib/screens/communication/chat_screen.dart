import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  Stream<List<Map<String, dynamic>>> _getMessagesStream(String userId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  void _sendMessage(String userId) async {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();
    await supabase.from('messages').insert({
      'user_id': userId,
      'sender_id': userId,
      'content': content,
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16).copyWith(top: MediaQuery.of(context).padding.top + 16),
            color: AppTheme.primaryColor,
            child: const Row(children: [Text('Layanan Bantuan', style: TextStyle(color: Colors.white, fontSize: 20))]),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getMessagesStream(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final bool isFromMe = messageData['sender_id'] == user.uid;
                    return Align(
                      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isFromMe ? Theme.of(context).primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Text(messageData['content'] ?? '', style: TextStyle(color: isFromMe ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Ketik pesan...'))),
                IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage(user.uid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}