// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Station Dashboard, Admin Price Screen & Profile Screen

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
//  CUSTOMER FEEDBACK SCREEN
// ─────────────────────────────────────────────
class CustomerFeedbackScreen extends StatefulWidget {
  const CustomerFeedbackScreen({super.key});

  @override
  State<CustomerFeedbackScreen> createState() =>
      _CustomerFeedbackScreenState();
}

class _CustomerFeedbackScreenState extends State<CustomerFeedbackScreen> {
  final _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _stationName = '';
  String _stationBrand = '';

  @override
  void initState() {
    super.initState();
    if (_uid.isNotEmpty) _loadStationInfo();
  }

  // ── LOGIC PRESERVED ──
  Future<void> _loadStationInfo() async {
    try {
      final doc = await _db.collection('stations').doc(_uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _stationName = data?['stationName'] as String? ?? data?['name'] as String? ?? 'My Station';
        _stationBrand = data?['brand'] as String? ?? '';
      });
    } catch (e) {
      debugPrint('_loadStationInfo error: $e');
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF16A34A), // Green
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFEA580C), // Orange
      const Color(0xFF0D9488), // Teal
      const Color(0xFFDB2777), // Pink
    ];
    if (name.isEmpty) return Colors.grey;
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Customer Feedback', style: _T.h2.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: _uid.isEmpty
          ? Center(child: Text('Not logged in', style: _T.body))
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('stations')
                  .doc(_uid)
                  .collection('ratings')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                }

                final docs = snapshot.data?.docs ?? [];

                // Calculate average rating
                double avgRating = 0;
                if (docs.isNotEmpty) {
                  double total = 0;
                  for (final doc in docs) {
                    total += ((doc.data() as Map)['rating'] as num?)?.toDouble() ?? 0;
                  }
                  avgRating = total / docs.length;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── STATION SUMMARY HEADER ──
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_T.primary, _T.dark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _T.primary.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _stationBrand.isNotEmpty ? '$_stationBrand $_stationName' : _stationName,
                                    style: _T.h2.copyWith(color: Colors.white, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        avgRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 28),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Average Station Rating',
                                    style: _T.label.copyWith(color: Colors.white.withOpacity(0.6), letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    docs.length.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'REVIEWS',
                                    style: _T.label.copyWith(fontSize: 9, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text('Recent Feedback', style: _T.h1.copyWith(fontSize: 18)),
                      const SizedBox(height: 12),

                      // ── REVIEWS LIST ──
                      if (docs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: _T.card(),
                          child: Column(
                            children: [
                              Icon(Icons.forum_outlined, color: _T.textSecondary.withOpacity(0.2), size: 48),
                              const SizedBox(height: 16),
                              Text('No reviews yet', style: _T.h2.copyWith(color: _T.textSecondary)),
                              Text('Customer feedback will appear here.', style: _T.body, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      else
                        ...docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['userName'] as String? ?? data['userId'] as String? ?? 'Anonymous';
                          final rating = (data['rating'] as num?)?.toDouble() ?? 0;
                          final comment = data['comment'] as String? ?? '';
                          final ts = data['timestamp'] as Timestamp?;
                          final timeStr = ts != null ? _formatTime(ts.toDate()) : '';
                          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: _T.card(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _avatarColor(name).withOpacity(0.15),
                                      radius: 20,
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          color: _avatarColor(name),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: _T.h2.copyWith(fontSize: 13)),
                                          Text(timeStr, style: _T.label.copyWith(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _T.bg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      comment,
                                      style: _T.body.copyWith(
                                        color: _T.textPrimary,
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}