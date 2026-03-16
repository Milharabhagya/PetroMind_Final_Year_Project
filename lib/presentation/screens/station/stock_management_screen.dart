import 'package:flutter/material.dart';

class StockManagementScreen extends StatelessWidget {
  const StockManagementScreen({super.key});

  static const List<Map<String, dynamic>> stocks = [
    {'name': 'Air Pump', 'amount': '', 'color': 'green'},
    {'name': 'Petrol 92 Octane', 'amount': '1000 Litres', 'color': 'green'},
    {'name': 'Petrol 95 Octane', 'amount': '1000 Litres', 'color': 'green'},
    {'name': 'Auto Diesel', 'amount': '1000 Litres', 'color': 'green'},
    {'name': 'Super Diesel', 'amount': '1000 Litres', 'color': 'green'},
    {'name': 'Lanka Kerosene', 'amount': '480 Litres', 'color': 'orange'},
    {'name': 'Industrial Kerosene', 'amount': '284 Litres', 'color': 'orange'},
    {'name': 'Lanka Fuel Oil Super', 'amount': '40 Litres', 'color': 'red'},
    {'name': 'Lanka Fuel Oil 1500 Super', 'amount': '317m', 'color': 'red'},
  ];

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
        title: const Text(
          'Stock Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        // ✅ removed right-side icons
        actions: const [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Fuel Inventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Last Updated: Today at 9:00 A.m',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        itemCount: stocks.length,
                        itemBuilder: (context, index) {
                          final s = stocks[index];
                          return _stockRow(
                            s['name'] as String,
                            s['amount'] as String,
                            s['color'] as String,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _legend(Colors.green, 'High Stock'),
                const SizedBox(width: 16),
                _legend(Colors.orange, 'Medium Stock'),
                const SizedBox(width: 16),
                _legend(Colors.red, 'Low Stock'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockRow(String name, String amount, String colorStr) {
    final Color color = colorStr == 'green'
        ? Colors.green
        : colorStr == 'orange'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(amount, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}