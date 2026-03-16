import 'package:flutter/material.dart';

class FuelPriceManagementScreen extends StatefulWidget {
  const FuelPriceManagementScreen({super.key});

  @override
  State<FuelPriceManagementScreen> createState() =>
      _FuelPriceManagementScreenState();
}

class _FuelPriceManagementScreenState extends State<FuelPriceManagementScreen> {
  final List<Map<String, dynamic>> _fuels = [
    {'name': 'Petrol 92 Octane', 'price': 292.00, 'changed': true, 'up': false},
    {'name': 'Petrol 95 Octane', 'price': 340.00, 'changed': true, 'up': false},
    {'name': 'Auto Diesel', 'price': 277.00, 'changed': true, 'up': true},
    {'name': 'Super Diesel', 'price': 322.00, 'changed': true, 'up': true},
    {'name': 'Lanka Kerosense', 'price': 182.00, 'changed': false, 'up': false},
    {'name': 'Industrial Kerosense', 'price': 193.00, 'changed': false, 'up': false},
    {'name': 'Lanka Fuel Oil Super', 'price': 1200.00, 'changed': false, 'up': false},
    {'name': 'Lanka Fuel Oil 1500 Super', 'price': 1650.00, 'changed': false, 'up': false},
  ];

  int? _editingIndex;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _fuels
        .map((f) => TextEditingController(text: f['price'].toStringAsFixed(2)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

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
          'Fuel price\nManagement',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,

        // ✅ removed notification + IOC logo
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── FUEL PRICE LIST ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ..._fuels.asMap().entries.map((entry) {
                    final i = entry.key;
                    final fuel = entry.value;
                    final isLast = i == _fuels.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  fuel['name'],
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: _editingIndex == i
                                    ? TextField(
                                        controller: _controllers[i],
                                        autofocus: true,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(
                                            color: Color(0xFF8B0000),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          prefixText: 'Rs. ',
                                          prefixStyle: TextStyle(
                                              color: Color(0xFF8B0000),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      )
                                    : Text(
                                        'Rs. ${fuel['price'].toStringAsFixed(2)} per liter',
                                        style: const TextStyle(
                                            color: Color(0xFF8B0000),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_editingIndex == i) {
                                      final val = double.tryParse(_controllers[i].text);
                                      if (val != null) {
                                        _fuels[i]['price'] = val;
                                        _fuels[i]['changed'] = true;
                                      }
                                      _editingIndex = null;
                                    } else {
                                      _editingIndex = i;
                                    }
                                  });
                                },
                                child: Text(
                                  _editingIndex == i ? 'Done' : 'Edit',
                                  style: TextStyle(
                                    color: _editingIndex == i ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ],
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _editingIndex = null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Prices updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── PRICE CHANGED FUELS ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Price Changed Fuels',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ..._fuels.where((f) => f['changed'] == true).map((f) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    f['name'],
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Rs. ${f['price'].toStringAsFixed(2)} per liter',
                                    style: const TextStyle(
                                        color: Color(0xFF8B0000),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                                Icon(
                                  f['up'] ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: f['up'] ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        ],
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}