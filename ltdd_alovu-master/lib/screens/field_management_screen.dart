import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/field_service.dart';
import '../models/sport_field.dart';

class FieldManagementScreen extends StatefulWidget {
  const FieldManagementScreen({super.key});

  @override
  State<FieldManagementScreen> createState() => _FieldManagementScreenState();
}

class _FieldManagementScreenState extends State<FieldManagementScreen> {
  final FieldService _fieldService = FieldService();

  // =========================================================================
  // 1. MENU CHỌN THÊM SÂN HOẶC DANH MỤC (NÚT DẤU CỘNG)
  // =========================================================================
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryManager(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.category, color: Colors.orange, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text('Danh Mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showFieldForm(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(Icons.stadium, color: Colors.green, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text('Sân Bãi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // 2. QUẢN LÝ DANH MỤC (THÊM / XÓA / SỬA) TỪ DATABASE
  // =========================================================================
  void _showCategoryManager(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý Môn thể thao', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập tên môn mới (VD: Bơi lội)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)),
                  onPressed: () async {
                    if (categoryController.text.trim().isEmpty) return;
                    await FirebaseFirestore.instance.collection('settings').doc('categories').set({
                      'list': FieldValue.arrayUnion([categoryController.text.trim()])
                    }, SetOptions(merge: true));
                    categoryController.clear();
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Danh sách hiện tại:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('categories').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<dynamic> categories = [];
                if (snapshot.data!.exists && (snapshot.data!.data() as Map<String, dynamic>).containsKey('list')) {
                  categories = (snapshot.data!.data() as Map<String, dynamic>)['list'];
                }

                if (categories.isEmpty) return const Text('Chưa có môn nào. Hãy thêm ở trên.');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final String catName = categories[index].toString();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(catName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _editCategoryName(context, catName),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('settings').doc('categories').update({
                                'list': FieldValue.arrayRemove([catName])
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _editCategoryName(BuildContext context, String oldName) {
    TextEditingController editCtrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa danh mục'),
        content: TextField(
          controller: editCtrl,
          decoration: const InputDecoration(hintText: 'Nhập tên mới', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              String newName = editCtrl.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                Navigator.pop(context);
                await FirebaseFirestore.instance.collection('settings').doc('categories').update({
                  'list': FieldValue.arrayRemove([oldName])
                });
                await FirebaseFirestore.instance.collection('settings').doc('categories').update({
                  'list': FieldValue.arrayUnion([newName])
                });
              }
            },
            child: const Text('Lưu lại', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. QUẢN LÝ SÂN BÃI
  // =========================================================================
  void _showDeleteDialog(BuildContext context, SportField field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sân bãi'),
        content: Text('Bạn có chắc chắn muốn xóa sân "${field.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _fieldService.deleteField(field.id);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sân thành công!'), backgroundColor: Colors.green));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Load category từ database KHÔNG DÙNG async/await để tránh bị đơ form
  void _showFieldForm(BuildContext context, {SportField? field}) {
    final nameController = TextEditingController(text: field?.name ?? '');
    final addressController = TextEditingController(text: field?.address ?? '');
    final priceController = TextEditingController(text: field?.price ?? '');
    final imageUrlController = TextEditingController(text: field?.imageUrl ?? '');

    String? selectedCategory = field?.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field == null ? 'Thêm sân bãi mới' : 'Cập nhật thông tin sân',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên sân', border: OutlineInputBorder(), prefixIcon: Icon(Icons.stadium, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('settings').doc('categories').snapshots(),
                          builder: (context, snapshot) {
                            List<String> categories = ['Bóng đá'];

                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              if (data.containsKey('list') && data['list'] != null) {

                                categories = (data['list'] as List).map((e) => e.toString()).toList();
                              }
                            }

                            categories = categories.toSet().toList();

                            if (selectedCategory != null && !categories.contains(selectedCategory)) {
                              categories.add(selectedCategory!);
                            }

                            if (selectedCategory == null || !categories.contains(selectedCategory)) {
                              selectedCategory = categories.isNotEmpty ? categories.first : 'Bóng đá';
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                  labelText: 'Môn thể thao',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category, color: Colors.green)
                              ),
                              items: categories.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c)
                              )).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedCategory = val;
                                });
                              },
                            );
                          }
                      ),

                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Giá (VD: 200.000đ / giờ)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monetization_on, color: Colors.green)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(labelText: 'Link hình ảnh (URL)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image, color: Colors.green)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () async {
                            if (nameController.text.isEmpty || priceController.text.isEmpty || addressController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ Tên, Địa chỉ và Giá!')));
                              return;
                            }
                            try {
                              if (field == null) {
                                final newField = SportField(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: nameController.text.trim(),
                                  category: selectedCategory ?? 'Khác',
                                  address: addressController.text.trim(),
                                  price: priceController.text.trim(),
                                  imageUrl: imageUrlController.text.trim().isEmpty ? 'https://via.placeholder.com/150' : imageUrlController.text.trim(),
                                  rating: 5.0, reviews: [], subCourts: [],
                                );
                                await _fieldService.addField(newField);
                              } else {
                                await _fieldService.updateField(field.id, {
                                  'name': nameController.text.trim(), 'category': selectedCategory ?? 'Khác',
                                  'address': addressController.text.trim(), 'price': priceController.text.trim(),
                                  'imageUrl': imageUrlController.text.trim(),
                                });
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(field == null ? 'Đã thêm sân mới!' : 'Đã cập nhật sân!'), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                            }
                          },
                          child: Text(field == null ? 'LƯU SÂN MỚI' : 'CẬP NHẬT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản lý Sân bãi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[700],
        elevation: 0.5,
        actions: [
          // Nút + duy nhất mở Menu chọn
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            tooltip: 'Thêm mới',
            onPressed: () => _showAddOptions(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<SportField>>(
        stream: _fieldService.getSportFields(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stadium, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Chưa có sân bãi nào.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final fields = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade100)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        field.imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                    title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${field.category} • ${field.price}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.blue),
                          tooltip: 'Quản lý khung giờ',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleManagementScreen(fieldId: field.id, fieldName: field.name)));
                          },
                        ),
                        IconButton(icon: const Icon(Icons.edit_note, color: Colors.orange), onPressed: () => _showFieldForm(context, field: field)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _showDeleteDialog(context, field)),
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

// ========================================================================= //
// --- 3. MÀN HÌNH QUẢN LÝ LỊCH (KHUNG GIỜ / SUBCOURTS) DÀNH CHO ADMIN ---
// ========================================================================= //

class ScheduleManagementScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;

  const ScheduleManagementScreen({super.key, required this.fieldId, required this.fieldName});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {

  Future<void> _updateSubCourts(List<dynamic> updatedSubCourts) async {
    try {
      await FirebaseFirestore.instance.collection('sport_fields').doc(widget.fieldId).update({
        'subCourts': updatedSubCourts,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật lịch sân!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  void _addSubCourt(List<dynamic> currentSubCourts) {
    TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Khu vực sân'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'VD: Sân 5 người (A)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                currentSubCourts.add({'name': nameCtrl.text.trim(), 'slots': []});
                _updateSubCourts(currentSubCourts);
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addSlot(List<dynamic> currentSubCourts, int subCourtIndex) {
    TextEditingController timeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm khung giờ'),
        content: TextField(controller: timeCtrl, decoration: const InputDecoration(hintText: 'VD: 17:00 - 18:00')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              String newTime = timeCtrl.text.trim();
              if (newTime.isNotEmpty) {
                List slots = currentSubCourts[subCourtIndex]['slots'] ?? [];

                // RÀNG BUỘC: KIỂM TRA KHUNG GIỜ CÓ TRÙNG LẶP KHÔNG
                bool isDuplicate = slots.any((slot) => slot['time'] == newTime);
                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Khung giờ "$newTime" đã tồn tại!'), backgroundColor: Colors.red)
                  );
                  return; // Không thực hiện lệnh thêm và không đóng cửa sổ
                }

                slots.add({'time': newTime, 'isAvailable': true});
                currentSubCourts[subCourtIndex]['slots'] = slots;
                _updateSubCourts(currentSubCourts);
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Lịch: ${widget.fieldName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[700],
        elevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('sport_fields').doc(widget.fieldId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          List<dynamic> subCourts = data?['subCourts'] ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Thêm Khu vực sân mới (Sân nhỏ)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _addSubCourt(subCourts),
                  ),
                ),
              ),
              Expanded(
                child: subCourts.isEmpty
                    ? const Center(child: Text('Chưa có khu vực sân nào.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: subCourts.length,
                  itemBuilder: (context, index) {
                    final subCourt = subCourts[index];
                    final slots = subCourt['slots'] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade100)),
                      elevation: 0,
                      child: ExpansionTile(
                        title: Text(subCourt['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        leading: const Icon(Icons.sports_soccer, color: Colors.green),
                        children: [
                          const Divider(height: 1),
                          // Danh sách khung giờ
                          ...List.generate(slots.length, (slotIndex) {
                            final slot = slots[slotIndex];
                            return ListTile(
                              title: Text(slot['time'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(slot['isAvailable'] ? 'Đang trống' : 'Đã có người đặt',
                                  style: TextStyle(color: slot['isAvailable'] ? Colors.green : Colors.red, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    activeColor: Colors.green,
                                    value: slot['isAvailable'],
                                    onChanged: (val) {
                                      slots[slotIndex]['isAvailable'] = val;
                                      subCourts[index]['slots'] = slots;
                                      _updateSubCourts(subCourts);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () {
                                      slots.removeAt(slotIndex);
                                      subCourts[index]['slots'] = slots;
                                      _updateSubCourts(subCourts);
                                    },
                                  )
                                ],
                              ),
                            );
                          }),
                          // Nút thêm giờ
                          TextButton.icon(
                              onPressed: () => _addSlot(subCourts, index),
                              icon: const Icon(Icons.add_alarm, color: Colors.blue),
                              label: const Text('Thêm khung giờ', style: TextStyle(color: Colors.blue))
                          ),
                          // Nút xóa toàn bộ khu vực
                          TextButton.icon(
                              onPressed: () {
                                subCourts.removeAt(index);
                                _updateSubCourts(subCourts);
                              },
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              label: const Text('Xóa khu vực sân này', style: TextStyle(color: Colors.red))
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}