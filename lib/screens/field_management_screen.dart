import 'package:flutter/material.dart';
import '../services/field_service.dart';
import '../models/sport_field.dart';

class FieldManagementScreen extends StatelessWidget {
  const FieldManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sân bãi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Mở form thêm sân
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SportField>>(
        stream: FieldService().getSportFields(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final fields = snapshot.data!;

          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(field.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                ),
                title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${field.category} • ${field.price}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
