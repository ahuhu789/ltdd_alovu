import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_models.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy danh sách đội
  Stream<List<Team>> getTeams() {
    return _db.collection('teams').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Team.fromJson(doc.data())).toList();
    });
  }

  // Tạo đội mới
  Future<void> createTeam(String name, String description, String level) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('teams').doc();
    final team = Team(
      id: docRef.id,
      name: name,
      hostId: user.uid,
      logoUrl: 'https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?auto=format&fit=crop&q=80&w=150',
      description: description,
      level: level,
      members: [user.uid],
      createdAt: DateTime.now(),
    );

    await docRef.set(team.toJson());
  }

  // Tham gia đội
  Future<void> joinTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([user.uid])
    });
  }

  // Xóa thành viên hoặc Rời đội
  Future<void> removeMember(String teamId, String userId) async {
    await _db.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayRemove([userId])
    });
  }

  // Lấy Stream chi tiết 1 đội để update Real-time
  Stream<Team> getTeamStream(String teamId) {
    return _db.collection('teams').doc(teamId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Team not found");
      return Team.fromJson(doc.data()!);
    });
  }

  // Lấy thông tin user của các thành viên
  Future<List<Map<String, dynamic>>> getTeamMembersInfo(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    
    List<Map<String, dynamic>> memberInfos = [];
    for (String id in memberIds) {
      final doc = await _db.collection('users').doc(id).get();
      if (doc.exists) {
        memberInfos.add({'id': id, ...doc.data() as Map<String, dynamic>});
      } else {
        memberInfos.add({
          'id': id, 
          'name': 'Người chơi', 
          'email': '', 
          'avatar': 'https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?auto=format&fit=crop&q=80&w=150',
          'role': 'user'
        });
      }
    }
    return memberInfos;
  }

  // Lấy danh sách ghép kèo (Sử dụng collection 'matches')
  Stream<List<SportMatch>> getOpenMatches() {
    return _db.collection('matches').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SportMatch.fromJson(doc.data())).toList();
    });
  }

  // Tạo kèo mới
  Future<void> createMatch({
    required String field,
    required String time,
    required String price,
    required int maxPlayers,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('matches').doc();

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final hostName = userDoc.data()?['name'] ?? user.displayName ?? 'Người chơi';

    final match = SportMatch(
      id: docRef.id,
      field: field,
      time: time,
      price: price,
      maxPlayers: maxPlayers,
      joinedPlayers: [user.uid],
      hostId: user.uid,
      hostName: hostName,
      createdAt: DateTime.now(),
    );

    await docRef.set(match.toJson());
  }

  // Tham gia / Rời kèo
  Future<void> toggleJoinMatch(String matchId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('matches').doc(matchId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final match = SportMatch.fromJson(doc.data()!);
    if (match.joinedPlayers.contains(user.uid)) {
      // Đã tham gia -> Rời kèo
      await docRef.update({
        'joinedPlayers': FieldValue.arrayRemove([user.uid])
      });
    } else {
      // Chưa tham gia -> Tham gia kèo nếu còn chỗ
      if (match.joinedPlayers.length < match.maxPlayers) {
        await docRef.update({
          'joinedPlayers': FieldValue.arrayUnion([user.uid])
        });
      }
    }
  }

  // --- CHAT LOGIC ---

  // Gửi tin nhắn
  Future<void> sendMessage(String chatId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final message = ChatMessage(
      senderId: user.uid,
      senderName: user.displayName ?? 'Người dùng',
      content: content,
      timestamp: DateTime.now(),
      type: 'text',
    );

    await _db.collection('chats').doc(chatId).collection('messages').add(message.toJson());
    
    // Cập nhật tin nhắn sau cùng cho document chat chính để sort danh sách chat
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': content,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'isGroup': true,
    }, SetOptions(merge: true));
  }

  // Lấy tin nhắn Real-time
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();
    });
  }
}
