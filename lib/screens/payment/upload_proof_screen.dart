// lib/screens/payment/upload_proof_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/utils/app_theme.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';

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
    'Transfer Bank (BCA)': {
      'bank': 'BCA',
      'rekening': '7295237082',
      'nama': 'YAYASAN AN-NAAFI\'NUR',
    },
    'Transfer Bank (Mandiri)': {
      'bank': 'Bank Mandiri',
      'rekening': '1760005209604',
      'nama': 'YAYASAN AN-NAAFI\'NUR',
    },
    'E-Wallet (OVO/GoPay/DANA)': {
      'bank': 'OVO/GoPay/DANA',
      'rekening': '081290589185',
      'nama': 'TK AN-NAAFI\'NUR',
    },
  };

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    ); // Menambahkan kompresi gambar
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah bukti pembayaran terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final success = await context
        .read<PaymentProvider>()
        .submitMultiplePayments(
          selectedPayments: widget.selectedPayments,
          proofImage: _imageFile!,
          paymentMethod: _selectedMethod!,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      widget.onPaymentSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bukti pembayaran berhasil diunggah! Menunggu verifikasi admin.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengunggah bukti pembayaran. Silakan coba lagi.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran'),
      // --- KONTEN DI-UPDATE AGAR LEBIH RAPI ---
      content:
          _isUploading
              ? const SizedBox(
                height: 150,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Mengunggah bukti..."),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text(
                      'Anda akan membayar tagihan untuk:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    // Tampilkan daftar bulan yang akan dibayar
                    ...widget.selectedPayments.map(
                      (p) => Text(
                        '- ${p.month} ${p.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 24),

                    // Dropdown metode pembayaran
                    DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      hint: const Text('Pilih metode pembayaran'),
                      isExpanded: true,
                      items:
                          paymentDetails.keys
                              .map(
                                (method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => _selectedMethod = value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail rekening (muncul setelah metode dipilih)
                    if (paymentDetails[_selectedMethod] != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Silakan transfer sejumlah:',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              currencyFormat.format(widget.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ke rekening ${paymentDetails[_selectedMethod]!['bank']}:',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${paymentDetails[_selectedMethod]!['rekening']} a/n ${paymentDetails[_selectedMethod]!['nama']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Tombol dan preview unggah bukti
                    const Text(
                      'Unggah Bukti Pembayaran:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        // Gunakan Stack untuk menumpuk widget
                        alignment: Alignment.center,
                        children: [
                          // Widget 1: Latar belakang (Container dengan gambar atau ikon)
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _imageFile == null
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          color: Colors.grey.shade600,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Ketuk untuk memilih gambar",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    )
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                          ),

                          // Widget 2: Tombol "Lihat Lebih Besar" (hanya muncul jika gambar ada)
                          if (_imageFile != null)
                            Positioned(
                              // Gunakan Positioned untuk menempatkan tombol di pojok
                              bottom: 8,
                              right: 8,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.black.withOpacity(
                                    0.5,
                                  ), // Latar belakang agar terbaca
                                  side: const BorderSide(color: Colors.white),
                                ),
                                icon: const Icon(
                                  Icons.zoom_out_map,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Lihat Lebih Besar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () {
                                  // Dialog untuk menampilkan gambar secara penuh
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => Dialog(
                                          child: Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              InteractiveViewer(
                                                // Widget agar bisa di-zoom
                                                child: Image.file(_imageFile!),
                                              ),
                                              IconButton(
                                                icon: const CircleAvatar(
                                                  backgroundColor:
                                                      Colors.black54,
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submitPayment,
          child: const Text('Kirim Bukti Bayar'),
        ),
      ],
    );
  }
}
