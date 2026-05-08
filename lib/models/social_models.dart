import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String hostId;
  final String logoUrl;
  final String description;
  final String level; // Mới chơi, Trung bình, Khá, Pro
  final List<String> members;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.hostId,
    required this.logoUrl,
    required this.description,
    required this.level,
    required this.members,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        hostId: json['hostId'] as String,
        logoUrl: json['logoUrl'] as String,
        description: json['description'] as String,
        level: json['level'] as String,
        members: List<String>.from(json['members'] ?? []),
        createdAt: (json['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hostId': hostId,
        'logoUrl': logoUrl,
        'description': description,
        'level': level,
        'members': members,
        'createdAt': createdAt,
      };
}

class ChatMessage {
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String type; // text, image

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        content: json['content'] as String,
        timestamp: (json['timestamp'] as Timestamp).toDate(),
        type: json['type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': timestamp,
        'type': type,
      };
}
