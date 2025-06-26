// lib/screens/admin/admin_register_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase
import 'package:sipatka/utils/app_theme.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});
  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _classController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentNameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase.functions.invoke('register-new-user', body: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'parentName': _nameController.text.trim(),
        'studentName': _studentNameController.text.trim(),
        'className': _classController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Pendaftaran berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    // --- PERBAIKAN LOGIKA TRY-CATCH DI SINI ---
    } catch (e) {
       if (!mounted) return;
       String errorMessage = 'Terjadi kesalahan tidak diketahui.';
       // Cek apakah errornya adalah FunctionsException secara dinamis
       if (e is FunctionException) {
          final details = e.details as Map<String, dynamic>?;
          errorMessage = 'Error dari Server: ${details?['error'] ?? e.message}';
       } else {
         errorMessage = e.toString();
       }
       
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
    // --- AKHIR PERBAIKAN ---

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun oleh Admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap Orang Tua', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _studentNameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap Anak', border: OutlineInputBorder(), prefixIcon: Icon(Icons.child_care_outlined)),
                   validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classController,
                  decoration: const InputDecoration(labelText: 'Kelas (contoh: TK A1)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.class_outlined)),
                   validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : const Text('Daftarkan Siswa', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on FunctionException {
  get message => null;
}