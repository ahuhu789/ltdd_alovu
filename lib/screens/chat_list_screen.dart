import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_chat_sceen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Danh sách nhóm chat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy danh sách các cuộc trò chuyện từ admin_chats, ưu tiên tin mới nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('admin_chats')
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text('Chưa có tin nhắn nào.'));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final String userId = chatDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                // Lấy thông tin từ collection users. Nếu ID không tồn tại trong bảng users, 
                // chứng tỏ đây là một teamId (chat nhóm), do đó ẩn hoàn toàn cuộc trò chuyện này.
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnap.data!.data() as Map<String, dynamic>;
                  String name = userData['name'] ?? "Người dùng";
                  String avatar = userData['avatar'] ?? "";
                  final displayName = "$name";

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.purple.shade50,
                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.green)) : null,
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          chatData['lastMessage'] ?? 'Đã gửi một tin nhắn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        trailing: Text(
                          chatData['lastTimestamp'] != null
                              ? DateFormat('HH:mm').format((chatData['lastTimestamp'] as Timestamp).toDate())
                              : '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatRoomScreen(userId: userId, userName: displayName)),
                        ),
                      ),
                      const Divider(height: 1, indent: 70),
                    ],
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