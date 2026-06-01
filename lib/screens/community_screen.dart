import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import '../services/social_service.dart';
import '../models/social_models.dart';
import 'team_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng ALOVU', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green[700],
          tabs: const [
            Tab(text: 'Đội nhóm'),
            Tab(text: 'Ghép kèo'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateTeamDialog();
          } else {
            _showCreateMatchDialog();
          }
        },
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamList(),
          _buildMatchList(),
        ],
      ),
    );
  }

  Widget _buildTeamList() {
    return StreamBuilder<List<Team>>(
      stream: SocialService().getTeams(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => _buildTeamSkeleton(),
          );
        }
        final teams = snapshot.data!;
        if (teams.isEmpty) return const Center(child: Text('Chưa có đội nhóm nào. Hãy tạo đội ngay!'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final amIMember = team.members.contains(FirebaseAuth.instance.currentUser?.uid);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.hardEdge,
              child: ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(teamInfo: team)));
                },
                leading: CircleAvatar(backgroundImage: NetworkImage(team.logoUrl)),
                title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${team.members.length} thành viên • Trình độ: ${team.level}'),
                trailing: amIMember
                    ? const Icon(Icons.chevron_right)
                    : TextButton(
                        onPressed: () => SocialService().joinTeam(team.id),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green[50], 
                          foregroundColor: Colors.green[700]
                        ),
                        child: const Text('GIA NHẬP', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchList() {
    return StreamBuilder<List<SportMatch>>(
      stream: SocialService().getOpenMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => _buildTeamSkeleton(),
          );
        }
        final matches = snapshot.data!;
        if (matches.isEmpty) {
          return const Center(child: Text('Chưa có kèo nào được tạo. Hãy tạo kèo ngay!'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            return _buildMatchCard(matches[index]);
          },
        );
      },
    );
  }

  Widget _buildMatchCard(SportMatch match) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final amIJoined = match.joinedPlayers.contains(currentUser?.uid);
    final isFull = match.joinedPlayers.length >= match.maxPlayers;

    String statusStr = 'Thiếu ${match.maxPlayers - match.joinedPlayers.length} người';
    if (isFull) {
      statusStr = 'Đã đủ người';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.field,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull ? Colors.grey[200] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusStr,
                    style: TextStyle(
                      color: isFull ? Colors.grey[700] : Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('🕒 ${match.time}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('👑 Chủ kèo: ${match.hostName}', style: TextStyle(color: Colors.green[700], fontSize: 13)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.price,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: currentUser == null
                      ? null
                      : () => SocialService().toggleJoinMatch(match.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amIJoined ? Colors.red[600] : Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(amIJoined ? 'HỦY KÈO' : 'KÈO NGAY'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMatchDialog() {
    final fieldController = TextEditingController();
    final timeController = TextEditingController();
    final priceController = TextEditingController();
    final maxPlayersController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo kèo ghép mới', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fieldController,
                decoration: const InputDecoration(
                  labelText: 'Tên sân & Khu vực',
                  hintText: 'Ví dụ: Sân Chảo Lửa - Sân 5',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Thời gian',
                  hintText: 'Ví dụ: 19:00 Hôm nay hoặc 20:30 Mai',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Chi phí (mỗi người)',
                  hintText: 'Ví dụ: 50k/người',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxPlayersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số người tối đa',
                  hintText: 'Ví dụ: 10',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final field = fieldController.text.trim();
              final time = timeController.text.trim();
              final price = priceController.text.trim();
              final maxPlayers = int.tryParse(maxPlayersController.text) ?? 10;

              if (field.isNotEmpty && time.isNotEmpty && price.isNotEmpty) {
                SocialService().createMatch(
                  field: field,
                  time: time,
                  price: price,
                  maxPlayers: maxPlayers,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đăng kèo ghép thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: const Text('TẠO KÈO'),
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String level = 'Trung bình';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo đội bóng mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên đội')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: level,
              isExpanded: true,
              onChanged: (v) => level = v!,
              items: ['Mới chơi', 'Trung bình', 'Khá', 'Pro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () {
              SocialService().createTeam(nameController.text, descController.text, level);
              Navigator.pop(context);
            },
            child: const Text('TẠO ĐỘI'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const CircleAvatar(radius: 25, backgroundColor: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(height: 16, width: 150, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(height: 14, width: 100, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(height: 36, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
            )
          ],
        )
      )
    );
  }
}
