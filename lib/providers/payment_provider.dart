import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/main.dart';

class PaymentProvider with ChangeNotifier {
  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  double get totalPaidAmount => _payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0.0, (sum, item) => sum + item.amount + item.denda);

  Future<void> fetchPayments() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await supabase
          .from('payments')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      _payments = data.map((item) => Payment.fromSupabase(item)).toList();
    } catch (e) {
      print("Error fetching payments: $e");
      _payments = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitMultiplePayments({
    required List<Payment> selectedPayments,
    required File proofImage,
    required String paymentMethod,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null || selectedPayments.isEmpty) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final fileName = 'proofs/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('proofs').upload(fileName, proofImage);
      final proofImageUrl = supabase.storage.from('proofs').getPublicUrl(fileName);

      final updates = selectedPayments.map((p) {
        return {
          'id': p.id,
          'status': 'pending',
          'proof_of_payment_url': proofImageUrl,
          'payment_method': paymentMethod,
          'paid_date': DateTime.now().toIso8601String(),
          'is_verified': false,
        };
      }).toList();

      await supabase.from('payments').upsert(updates);
      await fetchPayments();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error submitting multiple payments: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}