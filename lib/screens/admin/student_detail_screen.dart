// lib/screens/admin/student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- PERBAIKAN: Import yang dibutuhkan

class StudentDetailScreen extends StatefulWidget {
  final UserModel student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  // Stream untuk profil siswa agar bisa refresh otomatis saat di-edit
  Stream<UserModel> _profileStream() {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.student.uid)
        .map((maps) => UserModel.fromSupabase(maps.first));
  }
  
  // Stream untuk riwayat pembayaran siswa
  Stream<List<Payment>> _paymentsStream() {
     return supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.student.uid)
        .order('created_at', ascending: false) // Tampilkan dari yang terbaru
        .map((maps) => maps.map((map) => Payment.fromSupabase(map)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.studentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Data Siswa",
            onPressed: () => _showEditStudentDialog(context, widget.student),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: "Hapus Siswa",
            onPressed: () => _showDeleteConfirmation(context, widget.student.uid),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Profil Siswa (Real-time)
            StreamBuilder<UserModel>(
              stream: _profileStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return const Text("Gagal memuat data siswa.");
                }
                return _buildProfileCard(snapshot.data!);
              },
            ),
            const SizedBox(height: 24),
            const Text("Riwayat Tagihan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            // Daftar Riwayat Pembayaran (Real-time)
            StreamBuilder<List<Payment>>(
              stream: _paymentsStream(),
              builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                   if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Belum ada riwayat tagihan.")));
                  }
                  final payments = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentTile(payments[index]);
                    },
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  // --- IMPLEMENTASI FUNGSI HELPER UNTUK UI ---

  Widget _buildProfileCard(UserModel student) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.child_care, "Nama Siswa", student.studentName),
            _buildInfoRow(Icons.class_, "Kelas", student.className),
            _buildInfoRow(Icons.person, "Nama Wali", student.parentName),
            _buildInfoRow(Icons.email, "Email", student.email),
            if (student.saldo > 0)
              _buildInfoRow(Icons.wallet, "Saldo", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(student.saldo)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 16),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final totalAmount = payment.amount + payment.denda;
    final statusInfo = payment.getStatusInfo();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusInfo['icon'], color: statusInfo['color']),
        title: Text('${payment.month} ${payment.year}'),
        subtitle: Text("Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}"),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(currencyFormat.format(totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, UserModel student) {
    final parentNameController = TextEditingController(text: student.parentName);
    final studentNameController = TextEditingController(text: student.studentName);
    final classNameController = TextEditingController(text: student.className);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Data Siswa"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: parentNameController, decoration: const InputDecoration(labelText: "Nama Wali")),
                TextFormField(controller: studentNameController, decoration: const InputDecoration(labelText: "Nama Siswa")),
                TextFormField(controller: classNameController, decoration: const InputDecoration(labelText: "Kelas")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await supabase.from('profiles').update({
                    'parent_name': parentNameController.text.trim(),
                    'student_name': studentNameController.text.trim(),
                    'class_name': classNameController.text.trim(),
                  }).eq('id', student.uid);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil diupdate"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengupdate data: $e"), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Siswa"),
        content: const Text("Apakah Anda yakin? Tindakan ini akan menghapus akun dan semua data terkait secara permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await supabase.functions.invoke('delete-user-account', body: {'uid': uid});
                if (mounted) {
                  Navigator.pop(context); 
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Siswa berhasil dihapus."), backgroundColor: Colors.green));
                }
              } catch (e) {
                 if (mounted) {
                   String errorMessage = "Gagal menghapus siswa.";
                   if (e is FunctionException) {
                     final details = e.details as Map<String, dynamic>?;
                     errorMessage = details?['error'] ?? e.message;
                   } else {
                     errorMessage = e.toString();
                   }
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
                 }
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}

extension on FunctionException {
  get message => null;
}