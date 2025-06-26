import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/screens/admin/admin_chat_detail_screen.dart';
import 'package:sipatka/screens/admin/student_detail_screen.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Siswa & Pesan')),
      body: StreamBuilder<List<UserModel>>(
        stream: adminProvider.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data siswa terdaftar.'));
          }
          final students = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(student: student),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    child: Text(student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : 'S'),
                  ),
                  title: Text(student.studentName),
                  subtitle: Text('Wali: ${student.parentName}'),
                  trailing: IconButton(
                    tooltip: "Chat dengan ${student.parentName}",
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatDetailScreen(parent: student),
                        ),
                      );
                    },
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