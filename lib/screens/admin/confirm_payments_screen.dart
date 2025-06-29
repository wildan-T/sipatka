// lib/screens/admin/confirm_payments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmPaymentsScreen extends StatelessWidget {
  const ConfirmPaymentsScreen({super.key});

  // --- QUERY DIPERBAIKI DENGAN URUTAN YANG BENAR ---
  Stream<List<Payment>> _getPendingPaymentsStream() {
    return supabase
        .from('payments')
        // select() dipanggil sebelum stream()
        .select('*, profiles!inner(student_name, parent_name)')
        .eq('status', 'pending')
        .order('created_at', ascending: true)
        .stream(primaryKey: ['id']) // stream() dipanggil terakhir
        .map((maps) => maps.map((map) => Payment.fromSupabase(map)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: StreamBuilder<List<Payment>>(
        stream: _getPendingPaymentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Tidak ada pembayaran untuk dikonfirmasi.'),
            );
          }
          final payments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(context, payment);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final studentName = payment.studentProfile?.studentName ?? 'Siswa Dihapus';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(studentName.isNotEmpty ? studentName[0] : 'S'),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Tagihan: ${payment.month} ${payment.year}'),
        trailing: Text(
          currencyFormat.format(payment.amount),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showConfirmationDialog(context, payment),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmationDialog(payment: payment),
    );
  }
}

extension on PostgrestTransformBuilder<PostgrestList> {
  stream({required List<String> primaryKey}) {}
}

// Pisahkan Dialog menjadi widget tersendiri agar lebih rapi dan bisa punya state
class ConfirmationDialog extends StatefulWidget {
  final Payment payment;
  const ConfirmationDialog({super.key, required this.payment});

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final _amountController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.payment.amount).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    try {
      final message = await context.read<AdminProvider>().confirmPayment(
        widget.payment.userId,
        widget.payment.id,
        double.parse(_amountController.text),
      );
      if (mounted) {
        Navigator.pop(context); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _onReject() async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alasan penolakan wajib diisi."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final message = await context.read<AdminProvider>().rejectPayment(
        widget.payment.userId,
        widget.payment.id,
        _rejectionReasonController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Konfirmasi: ${widget.payment.month}'),
      content:
          _isProcessing
              ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Siswa: ${widget.payment.studentProfile?.studentName ?? '...'}",
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bukti Pembayaran:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (widget.payment.proofOfPaymentUrl != null &&
                          widget.payment.proofOfPaymentUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.payment.proofOfPaymentUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (ctx, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                            errorBuilder:
                                (ctx, err, st) => const Center(
                                  child: Text(
                                    'Gagal muat gambar.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                          ),
                        )
                      else
                        const Text('Tidak ada bukti pembayaran.'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Diterima (Rp)',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                (v == null ||
                                        v.isEmpty ||
                                        double.tryParse(v) == null)
                                    ? 'Jumlah tidak valid'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rejectionReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Alasan Penolakan (jika ditolak)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _isProcessing ? null : _onReject,
          child: const Text('Tolak', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _onConfirm,
          child: const Text('Konfirmasi'),
        ),
      ],
    );
  }
}
