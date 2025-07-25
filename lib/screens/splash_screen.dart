import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // TUNGGU PROSES LOADING DI AUTHPROVIDER SELESAI
    final authProvider = context.read<AuthProvider>();

    // Looping untuk menunggu hingga isLoading menjadi false
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;

    // Setelah loading selesai, data user (termasuk role) sudah pasti tersedia
    if (authProvider.isLoggedIn) {
      if (authProvider.userRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo-nobg.png", width: 80, fit: BoxFit.contain),
            // const Icon(Icons.school, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'SIPATKA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
