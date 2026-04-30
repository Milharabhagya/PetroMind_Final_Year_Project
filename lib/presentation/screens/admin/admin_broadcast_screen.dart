import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/notification_service.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState
    extends State<AdminBroadcastScreen> {
  final _db = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _selectedType = 'fuel_news';

  final List<Map<String, dynamic>> _types = [
    {
      'value': 'fuel_news',
      'label': 'Fuel News',
      'icon': Icons.newspaper_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'value': 'price_change',
      'label': 'Price Update',
      'icon': Icons.attach_money,
      'color': Colors.amberAccent,
    },
    {
      'value': 'general',
      'label': 'General Alert',
      'icon': Icons.notifications_rounded,
      'color': Colors.blueAccent,
    },
  ];

  Future<void> _broadcast() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Get all station IDs
      final stationsSnap =
          await _db.collection('stations').get();
      final stationIds =
          stationsSnap.docs.map((d) => d.id).toList();

      if (stationIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No stations to broadcast to'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      // Send to all stations
      await NotificationService.broadcastFuelNews(
        stationIds: stationIds,
        message: msg,
      );

      if (!mounted) return;
      _messageController.clear();
      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Broadcast sent to ${stationIds.length} stations!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Broadcast Message',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── INFO BANNER ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded,
                      color: Colors.purpleAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This message will be sent to ALL registered station owners as a notification.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── TYPE SELECTOR ──
            const Text('Message Type',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: _types.map((t) {
                final isSelected =
                    _selectedType == t['value'];
                final color = t['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedType = t['value']),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: t != _types.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.2)
                            : const Color(0xFF1A1A2E),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.6)
                                : Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Icon(t['icon'] as IconData,
                              color: isSelected
                                  ? color
                                  : Colors.white38,
                              size: 18),
                          const SizedBox(height: 4),
                          Text(
                            t['label'] as String,
                            style: TextStyle(
                                color: isSelected
                                    ? color
                                    : Colors.white38,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── MESSAGE INPUT ──
            const Text('Message',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 5,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Government has updated Petrol 92 price to Rs.317.00 effective immediately.',
                  hintStyle:
                      TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── SEND BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _broadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30)),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(
                        Icons.send_rounded,
                        size: 18,
                      ),
                label: Text(
                  _isSending
                      ? 'Sending...'
                      : 'Broadcast to All Stations',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── RECENT BROADCASTS ──
            const Text('Recent Broadcasts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('broadcasts')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No broadcasts sent yet',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final msg =
                        data['message'] as String? ?? '';
                    final ts =
                        data['timestamp'] as Timestamp?;
                    final timeStr = ts != null
                        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                        : '';
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                              Icons.campaign_rounded,
                              color: Colors.purpleAccent,
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(msg,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12),
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis),
                          ),
                          Text(timeStr,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}