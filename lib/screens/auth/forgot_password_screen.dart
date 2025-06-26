// lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase jika perlu (untuk AuthException)

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- FUNGSI RESET PASSWORD DISESUAIKAN UNTUK SUPABASE ---
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    
    // Panggil fungsi dari provider (yang sekarang tidak mengembalikan bool)
    await authProvider.resetPassword(email: _emailController.text.trim());

    if (!mounted) return;

    // Cek apakah ada pesan error setelah fungsi dijalankan
    if (authProvider.errorMessage == null) {
      // Jika tidak ada error, berarti sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email reset password telah dikirim. Silakan cek inbox Anda.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      // Jika ada error, tampilkan pesan dari provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI tidak perlu diubah, hanya logikanya saja
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Masukkan alamat email yang terhubung dengan akun Anda, dan kami akan mengirimkan link untuk mereset password Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Masukkan format email yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : const Text('Kirim Email Reset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}