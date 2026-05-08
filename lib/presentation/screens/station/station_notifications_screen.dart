// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Station Dashboard, Admin Price Screen & Stock Management

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS (Shared across the app)
// ─────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFFAD2831);
  static const dark       = Color(0xFF38040E);
  static const accent     = Color(0xFF250902);
  static const bg         = Color(0xFFF8F4F1);
  static const surface    = Color(0xFFFFFFFF);
  static const muted      = Color(0xFFF2EBE7);
  static const textPrimary   = Color(0xFF1A0A0C);
  static const textSecondary = Color(0xFF7A5C60);
  static const border     = Color(0xFFEADDDA);

  // Functional Colors
  static const success    = Color(0xFF16A34A);
  static const warning    = Color(0xFFF59E0B);
  static const danger     = Color(0xFFDC2626);
  static const info       = Color(0xFF2563EB);

  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.6,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static BoxDecoration card({Color? color, bool hasBorder = true}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: border, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: dark.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─────────────────────────────────────────────
//  STATION NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────
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

  // ── STYLE HELPER ──
  _NotifStyle _styleFor(String type) {
    switch (type) {
      case 'price_change':
        return _NotifStyle(
          icon: Icons.attach_money_rounded,
          color: _T.warning,
          label: 'Price Update',
        );
      case 'low_stock':
        return _NotifStyle(
          icon: Icons.warning_amber_rounded,
          color: _T.danger,
          label: 'Low Stock',
        );
      case 'new_review':
        return _NotifStyle(
          icon: Icons.star_rounded,
          color: _T.info,
          label: 'Customer Review',
        );
      case 'stock_update':
        return _NotifStyle(
          icon: Icons.inventory_2_rounded,
          color: _T.success,
          label: 'Inventory',
        );
      case 'fuel_news':
        return _NotifStyle(
          icon: Icons.newspaper_rounded,
          color: Colors.purple,
          label: 'Market News',
        );
      default:
        return _NotifStyle(
          icon: Icons.notifications_rounded,
          color: _T.textSecondary,
          label: 'Notification',
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
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── LOGIC PRESERVED ──
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
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Notifications', style: _T.h2.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Mark all read',
              style: _T.label.copyWith(color: _T.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _uid.isEmpty
          ? Center(child: Text('Not logged in', style: _T.body))
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('stations')
                  .doc(_uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: _T.muted, shape: BoxShape.circle),
                          child: const Icon(Icons.notifications_off_rounded, color: _T.textSecondary, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text('No notifications yet', style: _T.h2),
                        const SizedBox(height: 4),
                        Text('We\'ll notify you about station activity.', style: _T.body),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] as String? ?? 'general';
                    final msg = data['message'] as String? ?? '';
                    final isRead = data['read'] as bool? ?? false;
                    final ts = data['timestamp'] as Timestamp?;
                    final timeStr = ts != null ? _formatTime(ts.toDate()) : '';
                    final style = _styleFor(type);

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _T.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_sweep_rounded, color: _T.danger),
                      ),
                      onDismissed: (_) => _deleteNotification(doc.id),
                      child: GestureDetector(
                        onTap: () {
                          if (!isRead) _markRead(doc.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _T.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: isRead ? null : Border.all(color: _T.primary.withOpacity(0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _T.dark.withOpacity(isRead ? 0.03 : 0.06),
                                blurRadius: isRead ? 8 : 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: style.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(style.icon, color: style.color, size: 12),
                                        const SizedBox(width: 6),
                                        Text(
                                          style.label.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: style.color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Unread Dot
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(
                                        color: _T.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(timeStr, style: _T.label.copyWith(fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                msg,
                                style: _T.body.copyWith(
                                  color: isRead ? _T.textSecondary : _T.textPrimary,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
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

class _NotifStyle {
  final IconData icon;
  final Color color;
  final String label;
  _NotifStyle({required this.icon, required this.color, required this.label});
}