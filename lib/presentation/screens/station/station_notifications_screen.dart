import 'package:flutter/material.dart';

class StationNotificationsScreen extends StatelessWidget {
  const StationNotificationsScreen({super.key});

  final List<Map<String, String>> notifications = const [
    {
      'type': 'Priority',
      'msg': 'Low Stock Alert: Diesel - 120L remaining',
      'date': '22/03/2026  12:09:09'
    },
    {
      'type': 'Priority',
      'msg': 'Fuel delivery received: 4,500L added',
      'date': '22/03/2026  12:09:09'
    },
    {
      'type': 'Priority',
      'msg': 'New customer review received',
      'date': '22/03/2026  12:09:09'
    },
    {
      'type': 'Priority',
      'msg': 'Petrol 92 stock successfully updated',
      'date': '22/03/2026  12:09:09'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B0000),
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
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        // ✅ removed right-side icons
        actions: const [],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6B0000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        n['type'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      n['date'] ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  n['msg'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}