import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import '../models/social_models.dart';
import '../services/social_service.dart';
import 'chat_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team teamInfo;

  const TeamDetailScreen({super.key, required this.teamInfo});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Team>(
      stream: SocialService().getTeamStream(widget.teamInfo.id),
      initialData: widget.teamInfo,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, elevation: 1),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSkeleton(),
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(3, (_) => _buildMemberSkeleton()),
                    )
                  )
                ],
              ),
            ),
          );
        }
        
        final team = snapshot.data!;
        final isHost = team.hostId == _currentUserId;
        final isMember = team.members.contains(_currentUserId);

        return Scaffold(
          appBar: AppBar(
            title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              if (isMember)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatId: team.id, chatName: 'Nhóm: ${team.name}'),
                      ),
                    );
                  },
                )
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(team, isMember),
                const Divider(height: 1, thickness: 1),
                _buildMembersList(team, isHost, isMember),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Team team, bool isMember) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(team.logoUrl),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Trình độ: ${team.level}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(team.description, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 12),
                if (!isMember)
                  ElevatedButton(
                    onPressed: () {
                      SocialService().joinTeam(team.id);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                    child: const Text('XIN VÀO ĐỘI'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(chatId: team.id, chatName: 'Nhóm ${team.name}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.chat, size: 18), SizedBox(width: 8), Text('CHAT NHÓM')],
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMembersList(Team team, bool isHost, bool isMember) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thành viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: Text('${team.members.length} người', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: SocialService().getTeamMembersInfo(team.members),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildMemberSkeleton()
                );
              }
              final membersInfo = snapshot.data!;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: membersInfo.length,
                itemBuilder: (context, index) {
                  final member = membersInfo[index];
                  final bool isMemberHost = member['id'] == team.hostId;
                  final bool isMe = member['id'] == _currentUserId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!)
                    ),
                    child: ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(member['avatar'] ?? '')),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              member['name'] ?? 'Ẩn danh', 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) 
                            const Padding(padding: EdgeInsets.only(left: 4), child: Text('(Bạn)', style: TextStyle(color: Colors.grey, fontSize: 12))),
                        ],
                      ),
                      subtitle: isMemberHost 
                          ? const Text('Đội trưởng', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                          : const Text('Thành viên'),
                      trailing: isHost && !isMemberHost
                          ? IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.red),
                              onPressed: () => _showRemoveDialog(team.id, member['id']!, member['name'] ?? ''),
                            )
                          : (!isHost && isMe && !isMemberHost)
                             ? IconButton(
                                 icon: const Icon(Icons.exit_to_app, color: Colors.red),
                                 onPressed: () => _showLeaveDialog(team.id),
                               )
                             : null,
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  void _showRemoveDialog(String teamId, String memberId, String memberName) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa thành viên'),
      content: Text('Bạn có chắc muốn xóa $memberName khỏi đội?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            SocialService().removeMember(teamId, memberId);
            Navigator.pop(context);
          }, 
          child: const Text('XÓA', style: TextStyle(color: Colors.white)),
        )
      ]
    ));
  }

  void _showLeaveDialog(String teamId) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Rời đội'),
      content: const Text('Bạn có chắc muốn rời khỏi đội này? Bạn sẽ không thể chat nhóm nữa.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            SocialService().removeMember(teamId, _currentUserId);
            Navigator.pop(context);
            Navigator.pop(context); // Quay ra ngoài ds đội
          }, 
          child: const Text('RỜI ĐỘI', style: TextStyle(color: Colors.white)),
        )
      ]
    ));
  }

  Widget _buildMemberSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: const CircleAvatar(backgroundColor: Colors.white)),
        title: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 16, width: 100, color: Colors.white)),
        subtitle: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 12, width: 60, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: const CircleAvatar(radius: 40, backgroundColor: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 20, width: 150, color: Colors.white)),
                const SizedBox(height: 8),
                Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 14, width: 100, color: Colors.white)),
                const SizedBox(height: 12),
                Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 14, width: double.infinity, color: Colors.white)),
                const SizedBox(height: 8),
                Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 14, width: double.infinity, color: Colors.white)),
                const SizedBox(height: 12),
                Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 35, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              ]
            )
          )
        ]
      )
    );
  }
}

