import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/main.dart';

class AdminProvider with ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Stream<List<UserModel>> getStudents() {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'user')
        .order('student_name', ascending: true)
        .map((maps) => maps.map((map) => UserModel.fromSupabase(map)).toList());
  }

  Stream<List<Payment>> getPendingPayments() {
    return supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: true)
        .map((maps) => maps.map((map) => Payment.fromSupabase(map)).toList());
  }

  Future<Map<String, dynamic>>? getFinancialReport(DateTime startDate, DateTime endDate) {}

  confirmPayment(String userId, String id, double parse) {}

  rejectPayment(String userId, String id, String trim) {}
}