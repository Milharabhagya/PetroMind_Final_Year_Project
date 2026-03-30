import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockHistoryWidget extends StatelessWidget {
  final String uid;
  const StockHistoryWidget({super.key, required this.uid});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stations')
          .doc(uid)
          .collection('stock_logs')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final logs = snapshot.data!.docs;
        if (logs.isEmpty) {
          return const Center(
            child: Text(
              'No stock history yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final data = logs[index].data() as Map<String, dynamic>;
            final fuel = data['fuelType'] as String? ?? '';
            final type = data['type'] as String? ?? '';
            final amount = (data['amount'] as num?)?.toDouble();
            final revenue = (data['revenue'] as num?)?.toDouble();
            final available = data['available'] as bool?;
            final ts = data['timestamp'] as Timestamp?;
            final timeStr = ts != null ? _formatTime(ts.toDate()) : '';

            // ✅ Air Pump shows Available/Unavailable
            final isAirPump = fuel == 'Air Pump';

            IconData icon;
            Color color;
            String changeLabel;

            if (isAirPump) {
              icon = Icons.air;
              color = available == true ? Colors.green : Colors.red;
              changeLabel =
                  available == true ? 'Available' : 'Unavailable';
            } else if (type == 'inflow') {
              icon = Icons.arrow_upward;
              color = Colors.green;
              changeLabel = '+${amount?.toStringAsFixed(0) ?? '0'}L';
            } else if (type == 'outflow') {
              icon = Icons.arrow_downward;
              color = Colors.red;
              changeLabel = '-${amount?.toStringAsFixed(0) ?? '0'}L';
            } else {
              icon = Icons.edit;
              color = Colors.orange;
              changeLabel = '=${amount?.toStringAsFixed(0) ?? '0'}L';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fuel,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        if (revenue != null && type == 'outflow')
                          Text(
                            'Revenue: Rs.${revenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    changeLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}