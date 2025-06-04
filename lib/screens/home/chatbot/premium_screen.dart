import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_webview.dart'; // Halaman WebView untuk redirect ke pembayaran

class PremiumScreen extends StatefulWidget {
  final String username;

  const PremiumScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final double premiumCost = 100000;
  final double serviceFee = 2000;
  final double discountAmount = 10000;
  final double totalPayment = 92000;
  String selectedPaymentMethod = "";

  void _showPaymentMethods() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildPaymentOption('GoPay', 'assets/gopay.png'),
              _buildPaymentOption('OVO', 'assets/ovo.png'),
              _buildPaymentOption('DANA', 'assets/dana.png'),
              _buildPaymentOption('Bank Transfer', 'assets/bank.png'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String name, String iconPath) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 40,
        height: 40,
        errorBuilder:
            (context, error, stackTrace) => const Icon(Icons.payment, size: 40),
      ),
      title: Text(name),
      onTap: () {
        setState(() {
          selectedPaymentMethod = name;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod.isEmpty) {
      _showPaymentMethods();
      return;
    }

    final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
    final serverKey = dotenv.env['MIDTRANS_SERVER_KEY'] ?? '';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    final body = {
      "payment_type": _mapPaymentType(selectedPaymentMethod),
      "transaction_details": {
        "order_id": orderId,
        "gross_amount": totalPayment.toInt(),
      },
      "customer_details": {
        "first_name": 'username',
        "email": "customer@example.com",
        "phone": "08123456789",
      },
      "item_details": [
        {
          "id": "premium-3day",
          "price": premiumCost.toInt(),
          "quantity": 1,
          "name": "Biaya Premium 3 Hari",
        },
        {
          "id": "service-fee",
          "price": serviceFee.toInt(),
          "quantity": 1,
          "name": "Biaya Layanan",
        },
        {
          "id": "discount",
          "price": -discountAmount.toInt(),
          "quantity": 1,
          "name": "Kupon (DISKONDOKTER)",
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['MIDTRANS_BASE_URL']}/v2/charge'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['redirect_url'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentWebViewScreen(
                  paymentUrl: responseData['redirect_url'],
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan URL pembayaran.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
    }
  }

  String _mapPaymentType(String selectedMethod) {
    switch (selectedMethod.toLowerCase()) {
      case 'gopay':
        return 'gopay';
      case 'ovo':
      case 'dana':
        return 'qris'; // fallback untuk OVO/DANA via QRIS
      case 'bank transfer':
        return 'bank_transfer';
      default:
        return 'bank_transfer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3978B8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Go Premium',
          style: TextStyle(
            color: Color(0xFF3978B8),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konsultasi untuk',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  'username',
                  style: const TextStyle(
                    color: Color(0xFF3978B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentDetailsTable(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Voucher',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3978B8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.percent,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '1 Voucher Digunakan',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _showPaymentMethods,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedPaymentMethod.isEmpty
                          ? 'Pilih Metode Pembayaran'
                          : selectedPaymentMethod,
                      style: TextStyle(
                        color:
                            selectedPaymentMethod.isEmpty
                                ? Colors.grey
                                : Colors.black,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3978B8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsTable() {
    return Table(
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2)},
      children: [
        _buildTableRow('Biaya Premium 3 Hari', 'Rp${premiumCost.toInt()}'),
        _buildTableRow('Biaya Layanan', 'Rp${serviceFee.toInt()}'),
        _buildTableRow('Kupon (DISKONDOKTER)', '-Rp${discountAmount.toInt()}'),
        _buildTableRow(
          'Pembayaranmu',
          'Rp${totalPayment.toInt()}',
          isTotal: true,
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, {bool isTotal = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
