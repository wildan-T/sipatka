import 'package:flutter/material.dart';
import 'package:sipatka/models/user_model.dart'; // Import UserModel

enum PaymentStatus { paid, pending, unpaid, overdue }

class Payment {
  final String id;
  final String userId;
  final String month;
  final int year;
  final double amount;
  final DateTime dueDate;
  PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? proofOfPaymentUrl;
  final bool isVerified;
  final double denda;
  final UserModel? studentProfile; // <-- TAMBAHAN: untuk menyimpan data profil siswa

  Payment({
    required this.id, required this.userId, required this.month,
    required this.year, required this.amount, required this.dueDate,
    required this.status, required this.createdAt, this.paidDate,
    this.paymentMethod, this.proofOfPaymentUrl, this.isVerified = false,
    this.denda = 0.0, this.studentProfile, // <-- Tambahkan di constructor
  });

  factory Payment.fromSupabase(Map<String, dynamic> data) {
    PaymentStatus status = PaymentStatus.values.firstWhere(
      (e) => e.name == data['status'], orElse: () => PaymentStatus.unpaid);
    final dueDate = DateTime.parse(data['due_date']);
    if (status == PaymentStatus.unpaid && dueDate.isBefore(DateTime.now())) {
      status = PaymentStatus.overdue;
    }
    return Payment(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      month: data['month'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: dueDate,
      status: status,
      createdAt: DateTime.parse(data['created_at']),
      paidDate: data['paid_date'] != null ? DateTime.parse(data['paid_date']) : null,
      paymentMethod: data['payment_method'],
      proofOfPaymentUrl: data['proof_of_payment_url'],
      isVerified: data['is_verified'] ?? false,
      denda: (data['denda'] as num?)?.toDouble() ?? 0.0,
      // Jika ada data 'profiles' yang di-join, buat objek UserModel darinya
      studentProfile: data['profiles'] != null ? UserModel.fromSupabase(data['profiles']) : null,
    );
  }
}

extension PaymentStatusInfo on Payment {
  Map<String, dynamic> getStatusInfo() {
    switch (status) {
      case PaymentStatus.paid: return {'text': 'Lunas', 'color': Colors.green, 'icon': Icons.check_circle};
      case PaymentStatus.pending: return {'text': 'Menunggu Verifikasi', 'color': Colors.orange, 'icon': Icons.pending};
      case PaymentStatus.unpaid: return {'text': 'Belum Bayar', 'color': Colors.red, 'icon': Icons.error};
      case PaymentStatus.overdue: return {'text': 'Terlambat', 'color': Colors.red.shade800, 'icon': Icons.warning};
    }
  }
}