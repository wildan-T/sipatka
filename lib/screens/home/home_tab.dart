import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PaymentProvider>(
      builder: (context, auth, paymentProvider, _) {
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
        );

        if (paymentProvider.isLoading && paymentProvider.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final currentMonthName = DateFormat('MMMM', 'id_ID').format(now);
        final currentYear = now.year;
        Payment? currentMonthPayment;
        try {
          currentMonthPayment = paymentProvider.payments.firstWhere(
            (p) =>
                p.month.toLowerCase() == currentMonthName.toLowerCase() &&
                p.year == currentYear,
          );
        } catch (e) {
          currentMonthPayment = null;
        }

        return RefreshIndicator(
          onRefresh: () => paymentProvider.fetchPayments(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang, ${auth.userName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Siswa: ${auth.studentName} (${auth.className})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tagihan Bulan Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (currentMonthPayment != null)
                  _buildPaymentItem(currentMonthPayment, currencyFormat)
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 40.0,
                        horizontal: 20.0,
                      ),
                      child: Center(
                        child: Text("Tidak ada tagihan untuk bulan ini."),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentItem(Payment payment, NumberFormat currencyFormat) {
    final statusInfo = payment.getStatusInfo();
    final totalAmount = payment.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(statusInfo['icon'], color: statusInfo['color']),
        title: Text(
          '${payment.month} ${payment.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              statusInfo['text'],
              style: TextStyle(color: statusInfo['color'], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
