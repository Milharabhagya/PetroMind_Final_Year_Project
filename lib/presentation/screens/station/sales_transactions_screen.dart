import 'package:flutter/material.dart';

class SalesTransactionsScreen extends StatelessWidget {
  const SalesTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        // ✅ Optional: Title in the AppBar
        title: const Text(
          'Sales & Transactions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        // ✅ removed right-side icons
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales & Transactions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Today's Sales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Sales",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('279,400 LKR',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('+4.7%',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text('3,450 Litres  ',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('1899 Transactions  ',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('32 Receipts',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Transactions List',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Filter >',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _txHeader(),
                  _txRow('11:00 AM', 'Vis', '120 L', 'LKR 2,200', '✓'),
                  _txRow('11:30 AM', 'Dies', '94 L', 'LKR 4,500', '✓'),
                  _txRow('12:00 PM', 'Petrol', '---', 'LKR 4,500', '✓'),
                  _txRow('12:30 PM', '---', '---', 'LKR 4,500', 'Comp...'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions Log
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Transactions Log',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Filter >',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _logRow('Today', 'Receipt', 'LKR 2,500'),
                  _logRow('22-05-2023', 'BC-1023', 'LKR 4,875'),
                  _logRow('22-05-2023', 'BC-2023', 'LKR 1950'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _txHeader() {
    return Row(
      children: const [
        Expanded(child: Text('Time', style: TextStyle(color: Colors.white54, fontSize: 11))),
        Expanded(child: Text('Fuel', style: TextStyle(color: Colors.white54, fontSize: 11))),
        Expanded(child: Text('Litres', style: TextStyle(color: Colors.white54, fontSize: 11))),
        Expanded(child: Text('Amount', style: TextStyle(color: Colors.white54, fontSize: 11))),
        Expanded(child: Text('Status', style: TextStyle(color: Colors.white54, fontSize: 11))),
      ],
    );
  }

  Widget _txRow(String time, String fuel, String litres, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 11))),
          Expanded(child: Text(fuel, style: const TextStyle(color: Colors.white, fontSize: 11))),
          Expanded(child: Text(litres, style: const TextStyle(color: Colors.white, fontSize: 11))),
          Expanded(child: Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11))),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                color: status == '✓' ? Colors.green : Colors.orange,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logRow(String date, String receipt, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(date, style: const TextStyle(color: Colors.white70, fontSize: 11))),
          Expanded(child: Text(receipt, style: const TextStyle(color: Colors.white, fontSize: 11))),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}