// lib/providers/admin_provider.dart

import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/models/payment_model.dart'; // Pastikan import ini ada jika digunakan di fungsi lain

class AdminProvider with ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- FUNGSI getStudents() DIPERBAIKI DI SINI ---
  Stream<List<UserModel>> getStudents() {
    // Memanggil RPC function yang sudah kita buat
    return supabase.rpc('get_all_students_with_parents').asStream().map((
      response,
    ) {
      return (response as List).map((item) {
        return UserModel(
          uid: item['student_id'],
          studentName: item['student_name'],
          className: item['class_name'],
          parentName: item['parent_name'],
          // Isi field lain dengan nilai default jika diperlukan
          email: '',
          role: 'user',
          saldo: 0,
        );
      }).toList();
    });
  }

  // --- KODE LAINNYA DI DALAM CLASS TETAP SAMA ---
  // Pastikan fungsi-fungsi lain yang mungkin Anda miliki di sini tetap ada.
  Stream<List<Payment>> getPendingPayments() {
    return supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: true)
        .map((maps) => maps.map((map) => Payment.fromSupabase(map)).toList());
  }

  Future<Map<String, dynamic>>? getFinancialReport(
    DateTime startDate,
    DateTime endDate,
  ) {}

  confirmPayment(String userId, String id, double parse) {}

  rejectPayment(String userId, String id, String trim) {}
}
