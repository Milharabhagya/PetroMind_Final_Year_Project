import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StationNotificationsScreen extends StatefulWidget {
  const StationNotificationsScreen({super.key});

  @override
  State<StationNotificationsScreen> createState() =>
      _StationNotificationsScreenState();
}

class _StationNotificationsScreenState
    extends State<StationNotificationsScreen> {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  _NotifStyle _styleFor(String type) {
    switch (type) {
      case 'price_change':
        return _NotifStyle(
          icon: Icons.attach_money,
          color: Colors.amberAccent,
          label: 'Price Update',
        );
      case 'low_stock':
        return _NotifStyle(
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          label: 'Low Stock',
        );
      case 'new_review':
        return _NotifStyle(
          icon: Icons.star_rounded,
          color: Colors.lightBlueAccent,
          label: 'New Review',
        );
      case 'stock_update':
        return _NotifStyle(
          icon: Icons.inventory_2_rounded,
          color: Colors.greenAccent,
          label: 'Stock Updated',
        );
      case 'fuel_news':
        return _NotifStyle(
          icon: Icons.newspaper_rounded,
          color: Colors.purpleAccent,
          label: 'Fuel News',
        );
      default:
        return _NotifStyle(
          icon: Icons.notifications_rounded,
          color: Colors.white70,
          label: 'Alert',
        );
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markAllRead() async {
    if (_uid.isEmpty) return;
    final snap = await _db
        .collection('stations')
        .doc(_uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> _markRead(String docId) async {
    if (_uid.isEmpty) return;
    await _db
        .collection('stations')
        .doc(_uid)
        .collection('notifications')
        .doc(docId)
        .update({'read': true});
  }

  Future<void> _deleteNotification(String docId) async {
    if (_uid.isEmpty) return;
    await _db
        .collection('stations')
        .doc(_uid)
        .collection('notifications')
        .doc(docId)
        .delete();
  }

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
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
      body: _uid.isEmpty
          ? const Center(
              child: Text('Not logged in',
                  style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('stations')
                  .doc(_uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: Colors.white),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_off_rounded,
                            color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Count unread
                final unreadCount =
                    docs.where((d) => (d.data() as Map)['read'] == false).length;

                return Column(
                  children: [
                    if (unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final type =
                              data['type'] as String? ?? 'general';
                          final msg = data['message'] as String? ?? '';
                          final isRead = data['read'] as bool? ?? false;
                          final ts = data['timestamp'] as Timestamp?;
                          final timeStr = ts != null
                              ? _formatTime(ts.toDate())
                              : '';
                          final style = _styleFor(type);

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red[900],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) =>
                                _deleteNotification(doc.id),
                            child: GestureDetector(
                              onTap: () {
                                if (!isRead) _markRead(doc.id);
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? const Color(0xFF5A0000)
                                      : const Color(0xFF6B0000),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: isRead
                                      ? null
                                      : Border.all(
                                          color: style.color
                                              .withOpacity(0.4),
                                          width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: style.color
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    4),
                                            border: Border.all(
                                                color: style.color
                                                    .withOpacity(0.6),
                                                width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(style.icon,
                                                  color: style.color,
                                                  size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                style.label,
                                                style: TextStyle(
                                                    color: style.color,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets
                                                .only(right: 8),
                                            decoration: BoxDecoration(
                                              color: style.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      msg,
                                      style: TextStyle(
                                        color: isRead
                                            ? Colors.white60
                                            : Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  final String label;
  _NotifStyle(
      {required this.icon, required this.color, required this.label});
}