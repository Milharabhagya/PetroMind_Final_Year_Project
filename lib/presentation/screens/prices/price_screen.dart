import 'package:flutter/material.dart';

class PriceScreen extends StatelessWidget {
  const PriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Price',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fuel Prices',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('(Effective Midnight, Jan 31/Feb 1, 2026)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
              children: [
                _priceCard('Petrol 92 octane', 'Rs. 292.00 per liter'),
                _priceCard('Petrol 95 octane', 'Rs. 340.00 per liter'),
                _priceCard('Auto Diesel', 'Rs. 277.00 per liter'),
                _priceCard('Super Diesel', 'Rs. 323.00 per liter'),
                _priceCard('Lanka Kerosene', 'Rs. 182.00 per liter'),
                _priceCard('Industrial Kerosene', 'Rs. 193.00 per liter'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Industrial Fuel',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('(Effective Midnight, Jan 31/Feb 1, 2026)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            _industrialCard('Lanka Fuel Oil Super', 'Rs. 194.00 per liter'),
            const SizedBox(height: 8),
            _industrialCard(
                'Lanka Fuel Oil 1500 Sec (High/Low Sulphur)',
                'Rs. 250.00 per liter'),
          ],
        ),
      ),
    );
  }

  Widget _priceCard(String name, String price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(price,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _industrialCard(String name, String price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}