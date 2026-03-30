import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/alert_repository.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  // ✅ Alert type → icon + color
  IconData _getIcon(String type) {
    switch (type) {
      case 'price_update': return Icons.price_change;
      case 'low_stock': return Icons.warning_amber;
      case 'out_of_stock': return Icons.remove_shopping_cart;
      case 'stock_restored': return Icons.check_circle;
      case 'peak_hour': return Icons.people;
      case 'maintenance': return Icons.build;
      case 'new_station': return Icons.add_location_alt;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'price_update': return Colors.amber;
      case 'low_stock': return Colors.orange;
      case 'out_of_stock': return Colors.red;
      case 'stock_restored': return Colors.green;
      case 'peak_hour': return Colors.blue;
      case 'maintenance': return Colors.purple;
      case 'new_station': return Colors.teal;
      default: return Colors.amber;
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live Alerts',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
        actions: [
          // ✅ Unread count badge
          StreamBuilder<QuerySnapshot>(
            stream:
                AlertRepository.streamNotifications(),
            builder: (context, snap) {
              final unread = snap.hasData
                  ? snap.data!.docs
                      .where((d) =>
                          (d.data() as Map<String,
                              dynamic>)['isRead'] !=
                          true)
                      .length
                  : 0;
              return unread > 0
                  ? Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.notifications,
                              color: Color(0xFF8B0000)),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            padding:
                                const EdgeInsets.all(3),
                            decoration:
                                const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AlertRepository.streamNotifications(),
        builder: (context, snapshot) {
          // ── LOADING ──
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF8B0000)),
            );
          }

          // ── ERROR ──
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Unable to load alerts',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                      'Check your internet connection',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12)),
                ],
              ),
            );
          }

          // ── EMPTY ──
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No alerts yet',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      'Live alerts will appear here',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12)),
                ],
              ),
            );
          }

          // ── ALERTS LIST ──
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data =
                  doc.data() as Map<String, dynamic>;
              final type =
                  data['type'] as String? ?? 'info';
              final title =
                  data['title'] as String? ??
                      'PetroMind Alert';
              final message =
                  data['message'] as String? ?? '';
              final isRead =
                  data['isRead'] as bool? ?? false;
              final ts =
                  data['createdAt'] as Timestamp?;

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    AlertRepository.markRead(doc.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(
                      bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: !isRead
                        ? Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.3),
                            width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding:
                              const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getColor(type)
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              _getIcon(type),
                              color: _getColor(type),
                              size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 13)),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(ts),
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(message,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}