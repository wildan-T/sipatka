// lib/screens/admin/admin_chat_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final UserModel parent;
  const AdminChatDetailScreen({super.key, required this.parent});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  late final String _adminId;

  @override
  void initState() {
    super.initState();
    
    // Ambil ID admin yang sedang login
    _adminId = context.read<AuthProvider>().userModel!.uid;

    // Siapkan stream untuk mendengarkan pesan real-time dari Supabase
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.parent.uid) // Ambil pesan untuk user ini
        .order('created_at', ascending: false); // Urutkan dari terbaru
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      // Kirim pesan ke tabel 'messages' di Supabase
      await supabase.from('messages').insert({
        'user_id': widget.parent.uid, // ID percakapan, merujuk ke wali murid
        'sender_id': _adminId,       // Pengirim adalah admin yang sedang login
        'content': content,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim pesan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat dengan ${widget.parent.parentName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text("Belum ada percakapan dengan ${widget.parent.parentName}."),
                  );
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final bool isFromAdmin = messageData['sender_id'] == _adminId;
                    return _buildMessageBubble(
                      text: messageData['content'] ?? '',
                      isFromAdmin: isFromAdmin,
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik balasan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  elevation: 2,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isFromAdmin}) {
    // Jika pesan dari admin, tampilkan di kanan. Jika dari user, di kiri.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isFromAdmin
                    ? AppTheme.primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                   topLeft: const Radius.circular(16),
                   topRight: const Radius.circular(16),
                   bottomLeft: isFromAdmin ? const Radius.circular(16) : const Radius.circular(0),
                   bottomRight: isFromAdmin ? const Radius.circular(0) : const Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isFromAdmin ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isFromAdmin) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.support_agent, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}