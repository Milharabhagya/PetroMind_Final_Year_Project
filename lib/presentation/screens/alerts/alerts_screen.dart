// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches HomeScreen Design System

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/alert_repository.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS (Shared from Home)
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
}

// ─────────────────────────────────────────────
//  ALERTS SCREEN
// ─────────────────────────────────────────────
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  // ── LOGIC PRESERVED ──
  IconData _getIcon(String type) {
    switch (type) {
      case 'price_update': return Icons.price_change_rounded;
      case 'low_stock': return Icons.warning_amber_rounded;
      case 'out_of_stock': return Icons.remove_shopping_cart_rounded;
      case 'stock_restored': return Icons.check_circle_rounded;
      case 'peak_hour': return Icons.people_rounded;
      case 'maintenance': return Icons.build_rounded;
      case 'new_station': return Icons.add_location_alt_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  // Refined palette to match premium feel
  Color _getColor(String type) {
    switch (type) {
      case 'price_update': return const Color(0xFFD97706); // Rich Amber
      case 'low_stock': return const Color(0xFFEA580C);    // Deep Orange
      case 'out_of_stock': return const Color(0xFFDC2626); // Strong Red
      case 'stock_restored': return const Color(0xFF16A34A); // Emerald
      case 'peak_hour': return const Color(0xFF2563EB);    // Royal Blue
      case 'maintenance': return const Color(0xFF7C3AED);  // Deep Purple
      case 'new_station': return const Color(0xFF0D9488);  // Rich Teal
      default: return const Color(0xFFD97706);
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Live Alerts',
            style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: AlertRepository.streamNotifications(),
            builder: (context, snap) {
              final unread = snap.hasData
                  ? snap.data!.docs
                      .where((d) =>
                          (d.data() as Map<String, dynamic>)['isRead'] != true)
                      .length
                  : 0;
              return unread > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _T.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _T.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$unread New',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: _T.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3),
            );
          }

          // ── ERROR ──
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: _T.muted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded,
                        size: 32, color: _T.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('Unable to load alerts', style: _T.h2),
                  const SizedBox(height: 4),
                  Text('Check your internet connection', style: _T.body),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: _T.muted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_rounded,
                        size: 40, color: _T.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('No alerts yet', style: _T.h2),
                  const SizedBox(height: 4),
                  Text('Live alerts will appear here', style: _T.body),
                ],
              ),
            );
          }

          // ── ALERTS LIST ──
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'info';
              final title = data['title'] as String? ?? 'PetroMind Alert';
              final message = data['message'] as String? ?? '';
              final isRead = data['isRead'] as bool? ?? false;
              final ts = data['createdAt'] as Timestamp?;

              final alertColor = _getColor(type);

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    AlertRepository.markRead(doc.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? _T.border : _T.primary.withOpacity(0.3), 
                      width: isRead ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _T.dark.withOpacity(isRead ? 0.03 : 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: alertColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIcon(type),
                              color: alertColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: _T.h2.copyWith(
                                          fontSize: 14,
                                          color: isRead ? _T.textPrimary.withOpacity(0.8) : _T.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!isRead) ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: _T.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      _formatTime(ts),
                                      style: _T.label.copyWith(
                                        fontSize: 10,
                                        color: isRead ? _T.textSecondary.withOpacity(0.7) : _T.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  style: _T.body.copyWith(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isRead ? _T.textSecondary.withOpacity(0.8) : _T.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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