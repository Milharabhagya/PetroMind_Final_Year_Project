import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  final List<Map<String, String>> alerts = const [
    {
      'date': '22/02/2026  12:00:02',
      'message': 'Today price updates !',
    },
    {
      'date': '21/02/2026  16:01:11',
      'message': 'Kandy Station Closed for Maintenance',
    },
    {
      'date': '21/02/2026  14:10:05',
      'message': 'New SHELL Fuel Station Opened Near You!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Alerts',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_gas_station,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Text('PetroMind',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(alerts[index]['date']!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(alerts[index]['message']!,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }
}