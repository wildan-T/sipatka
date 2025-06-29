// lib/screens/admin/laporan_keuangan_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/utils/app_theme.dart';

class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({super.key});
  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen> {
  // Atur tanggal default untuk filter, misal awal bulan ini hingga hari ini
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  // Future untuk menampung daftar transaksi
  Future<List<Payment>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    // Langsung panggil saat layar pertama kali dibuka
    _getReportData();
  }

  // --- LOGIKA PENGAMBILAN DATA DIUBAH ---
  void _getReportData() {
    // Ambil akhir hari untuk memastikan semua transaksi di tanggal akhir terhitung
    final endOfDay = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
    );
    setState(() {
      // Query langsung ke Supabase untuk mendapatkan transaksi lunas dalam rentang tanggal
      // dan langsung digabungkan (JOIN) dengan data profil siswa
      _reportFuture = supabase
          .from('payments')
          .select(
            '*, profiles!inner(student_name, parent_name)',
          ) // Lakukan JOIN
          .eq('status', 'paid')
          .gte('paid_date', _startDate.toIso8601String())
          .lte('paid_date', endOfDay.toIso8601String())
          .order('paid_date', ascending: false) // Urutkan dari yang terbaru
          .then(
            (data) => data.map((item) => Payment.fromSupabase(item)).toList(),
          );
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      // Otomatis refresh data setelah tanggal diubah dan filter diterapkan
      _getReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateFilter(),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Payment>>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi error: ${snapshot.error}\nPastikan Anda sudah membuat index di Supabase jika diminta.",
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak ada transaksi lunas pada rentang tanggal ini.",
                      ),
                    );
                  }

                  final transactions = snapshot.data!;
                  // Hitung total pendapatan dari daftar transaksi yang didapat
                  final double totalIncome = transactions.fold(
                    0.0,
                    (sum, item) => sum + item.amount,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        title: 'Total Pendapatan (Sesuai Filter)',
                        value: NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                        ).format(totalIncome),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Daftar Transaksi Lunas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionTile(transactions[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildDatePickerField(
                    "Dari Tanggal",
                    _startDate,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePickerField(
                    "Sampai Tanggal",
                    _endDate,
                    false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy', 'id_ID').format(date)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Payment payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final studentName = payment.studentProfile?.studentName ?? 'Siswa Dihapus';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
        title: Text(studentName),
        subtitle: Text(
          "Pembayaran: ${payment.month} ${payment.year}\nDibayar pada: ${DateFormat('dd MMM yyyy').format(payment.paidDate!)}",
        ),
        isThreeLine: true,
        trailing: Text(
          currencyFormat.format(payment.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
