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
        title: const Text('Tin nhắn khách hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy danh sách các cuộc trò chuyện, ưu tiên tin mới nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text('Chưa có tin nhắn nào.'));
          }

          return ListView.separated(
            itemCount: chatDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final String userId = chatDocs[index].id; // ID của khách hàng

              return FutureBuilder<DocumentSnapshot>(
                // Lấy tên và avatar thật của khách từ bảng users
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnap) {
                  String name = "Khách hàng";
                  String avatar = "";
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final userData = userSnap.data!.data() as Map<String, dynamic>;
                    name = userData['name'] ?? "Người dùng";
                    avatar = userData['avatar'] ?? "";
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.purple.shade50,
                      backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.green)) : null,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      MaterialPageRoute(builder: (context) => ChatRoomScreen(userId: userId, userName: name)),
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