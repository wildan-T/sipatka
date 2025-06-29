// lib/screens/admin/manage_students_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/screens/admin/admin_chat_detail_screen.dart';
import 'package:sipatka/screens/admin/student_detail_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Siswa & Pesan')),
      body: Column(
        children: [
          // --- KOLOM PENCARIAN ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Cari Siswa...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // --- DAFTAR SISWA (STREAMBUILDER) ---
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: adminProvider.getStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data siswa terdaftar.'),
                  );
                }

                // Filter siswa berdasarkan query pencarian
                final allStudents = snapshot.data!;
                final filteredStudents =
                    _searchQuery.isEmpty
                        ? allStudents
                        : allStudents.where((student) {
                          return student.studentName.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              student.parentName.toLowerCase().contains(
                                _searchQuery,
                              );
                        }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(child: Text('Siswa tidak ditemukan.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _buildStudentTile(context, student);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, UserModel student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => StudentDetailScreen(
                    // Kirim ID dan nama siswa
                    studentId:
                        student.uid, // student.uid sekarang adalah ID siswa
                    initialStudentName: student.studentName,
                  ),
            ),
          );
        },

        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColorLight,
          child: Text(
            student.studentName.isNotEmpty
                ? student.studentName[0].toUpperCase()
                : 'S',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // --- INFORMASI TAMBAHAN ---
        subtitle: Text(
          'Wali: ${student.parentName} | Kelas: ${student.className}',
        ),
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
  }
}
