// lib/screens/payment/payment_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/utils/app_theme.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // State untuk menyimpan daftar tagihan yang di-checklist
  final List<Payment> _selectedPayments = [];
  double _totalSelectedAmount = 0.0;

  void _onPaymentSelected(bool? isSelected, Payment payment) {
    setState(() {
      if (isSelected == true) {
        _selectedPayments.add(payment);
      } else {
        _selectedPayments.remove(payment);
      }
      // Hitung ulang total setiap kali ada perubahan
      _totalSelectedAmount = _selectedPayments.fold(
          0.0, (sum, item) => sum + item.amount + item.denda);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading && paymentProvider.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final unpaidPayments = paymentProvider.payments
              .where((p) =>
                  p.status == PaymentStatus.unpaid ||
                  p.status == PaymentStatus.overdue)
              .toList();

          return Column(
            children: [
              Expanded(
                child: unpaidPayments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(Icons.check_circle, size: 80, color: Colors.green),
                             SizedBox(height: 16),
                             Text(
                              'Semua tagihan sudah lunas!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => paymentProvider.fetchPayments(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Padding bawah untuk tombol
                          itemCount: unpaidPayments.length,
                          itemBuilder: (context, index) {
                            final payment = unpaidPayments[index];
                            final isSelected = _selectedPayments.contains(payment);
                            return _buildPaymentCard(context, payment, isSelected);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      // Tombol bayar dibuat 'mengambang' di bawah dan hanya muncul jika ada yang dipilih
      bottomSheet: _selectedPayments.isNotEmpty ? _buildPaymentButton(context) : null,
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment, bool isSelected) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final isOverdue = payment.status == PaymentStatus.overdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) => _onPaymentSelected(value, payment),
        title: Text('${payment.month} ${payment.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Jatuh tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}'),
             if (payment.denda > 0)
              Text("Denda: ${currencyFormat.format(payment.denda)}",
                  style: const TextStyle(color: Colors.red)),
          ],
        ),
        secondary: Text(
          currencyFormat.format(payment.amount + payment.denda),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isOverdue ? Colors.red : AppTheme.textPrimary),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Dipilih (${_selectedPayments.length} bulan)', style: const TextStyle(fontSize: 16)),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(_totalSelectedAmount),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showPaymentDialog(context),
              child: const Text('Lanjutkan Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDialog(
        selectedPayments: _selectedPayments,
        totalAmount: _totalSelectedAmount,
        onPaymentSuccess: () {
          setState(() {
            _selectedPayments.clear();
            _totalSelectedAmount = 0.0;
          });
        },
      ),
    );
  }
}


// Pisahkan Dialog menjadi widget tersendiri
class PaymentDialog extends StatefulWidget {
  final List<Payment> selectedPayments;
  final double totalAmount;
  final VoidCallback onPaymentSuccess;

  const PaymentDialog({
    super.key,
    required this.selectedPayments,
    required this.totalAmount,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _selectedMethod;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  final Map<String, Map<String, String>> paymentDetails = {
    'Transfer Bank (BCA)': {'bank': 'BCA', 'rekening': '7295237082', 'nama': 'YAYASAN AN-NAAFI\'NUR'},
    'Transfer Bank (Mandiri)': {'bank': 'Bank Mandiri', 'rekening': '1760005209604', 'nama': 'YAYASAN AN-NAAFI\'NUR'},
    'E-Wallet (OVO/GoPay/DANA)': {'bank': 'OVO/GoPay/DANA', 'rekening': '081290589185', 'nama': 'TK AN-NAAFI\'NUR'},
  };

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih metode pembayaran.')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unggah bukti pembayaran.')));
      return;
    }

    setState(() => _isUploading = true);
    
    // Panggil FUNGSI BARU di provider
    final success = await context.read<PaymentProvider>().submitMultiplePayments(
        selectedPayments: widget.selectedPayments,
        proofImage: _imageFile!,
        paymentMethod: _selectedMethod!);
    
    if (!mounted) return;

    if (success) {
      Navigator.pop(context); 
      widget.onPaymentSuccess();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bukti pembayaran berhasil diunggah!'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal mengunggah bukti pembayaran.'),
        backgroundColor: Colors.red,
      ));
    }
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final details = paymentDetails[_selectedMethod];
    return AlertDialog(
      title: const Text('Detail Pembayaran'),
      content: _isUploading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Pembayaran untuk:', style: TextStyle(color: Colors.grey.shade700)),
                  ...widget.selectedPayments.map((p) => Text('- ${p.month} ${p.year}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  const Divider(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    hint: const Text('Pilih metode pembayaran'),
                    isExpanded: true,
                    items: paymentDetails.keys.map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                    onChanged: (value) => setState(() => _selectedMethod = value),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 16),
                    Text('Silakan transfer ke:', style: TextStyle(color: AppTheme.textSecondary)),
                    Text('${details['bank']}: ${details['rekening']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('a/n: ${details['nama']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 16),
                   Text('Total Bayar: ${currencyFormat.format(widget.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8)),
                      child: _imageFile == null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600), const SizedBox(height: 4), Text("Unggah Bukti Bayar", style: TextStyle(color: Colors.grey.shade600))])
                          : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, fit: BoxFit.cover)),
                    ),
                  )
                ],
              ),
            ),
      actions: [
        TextButton(onPressed: _isUploading ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: _isUploading ? null : _submitPayment, child: const Text('Kirim Bukti Bayar')),
      ],
    );
  }
}