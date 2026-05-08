import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _getIcon(String type) {
    switch (type) {
      case 'favorite':
        return Icons.favorite;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'reminder':
        return Icons.access_time;
      case 'booking':
        return Icons.sports_soccer;
      case 'payment':
        return Icons.payment;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'favorite':
        return Colors.red;
      case 'chat':
        return Colors.blue;
      case 'reminder':
        return Colors.orange;
      case 'booking':
        return Colors.green;
      case 'payment':
        return Colors.purple;
      case 'promotion':
        return Colors.deepOrange;
      default:
        return Colors.green;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Vừa xong';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'read_all') {
                await service.markAllAsRead();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đánh dấu tất cả là đã đọc'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }

              if (value == 'clear_all') {
                await service.clearAll();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xoá toàn bộ thông báo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'read_all',
                child: Text('Đánh dấu tất cả đã đọc'),
              ),
              PopupMenuItem(value: 'clear_all', child: Text('Xoá toàn bộ')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.notificationStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final title = data['title'] ?? 'Thông báo';

              final body = data['body'] ?? '';

              final type = data['type'] ?? 'other';

              final isRead = data['isRead'] ?? false;

              final createdAt = data['createdAt'] as Timestamp?;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onDismissed: (_) async {
                  await service.deleteNotification(doc.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xoá thông báo'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    if (!isRead) {
                      await service.markAsRead(doc.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _getColor(type).withOpacity(0.15),
                          child: Icon(
                            _getIcon(type),
                            color: _getColor(type),
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isRead
                                      ? Colors.black87
                                      : Colors.green[700],
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                body,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
