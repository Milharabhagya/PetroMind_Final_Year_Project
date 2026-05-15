// ✅ REDESIGNED — Matches App-Wide Design System
// Design: Minimalist Industrial SaaS · Poppins
// Colors: Warm red/cream palette matching station & customer screens

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../auth/auth_screen.dart';
import 'admin_users_screen.dart';
import 'admin_stations_screen.dart';
import 'admin_stock_analysis_screen.dart';
import 'admin_broadcast_screen.dart';
import '../prices/admin_price_screen.dart';
import '../admin/registration_report_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS — matches station & customer screens
// ─────────────────────────────────────────────
class _T {
  static const primary       = Color(0xFFAD2831);
  static const dark          = Color(0xFF38040E);
  static const accent        = Color(0xFF250902);
  static const bg            = Color(0xFFF8F4F1);
  static const surface       = Color(0xFFFFFFFF);
  static const muted         = Color(0xFFF2EBE7);
  static const textPrimary   = Color(0xFF1A0A0C);
  static const textSecondary = Color(0xFF7A5C60);
  static const border        = Color(0xFFEADDDA);

  static const h1 = TextStyle(
    fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.4,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: -0.2,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500,
    color: textSecondary, letterSpacing: 0.6,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static BoxDecoration card({Color? color, bool hasBorder = true}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: border, width: 1) : null,
        boxShadow: [
          BoxShadow(color: dark.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      );
}

// ─────────────────────────────────────────────
//  ADMIN DASHBOARD SCREEN
// ─────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = FirebaseFirestore.instance;

  String _getTodayDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, dd MMM yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Dashboard', style: _T.h1.copyWith(fontSize: 24, height: 1.1)),
                      const SizedBox(height: 4),
                      Text(_getTodayDate(), style: _T.label),
                    ],
                  ),
                ),
                // Admin badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _T.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded,
                          color: _T.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('ADMIN',
                          style: _T.label.copyWith(
                              color: _T.primary, fontWeight: FontWeight.w700, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── LIVE STATS ──
            Text('Overview', style: _T.h2),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('users').where('role', isEqualTo: 'customer').snapshots(),
              builder: (context, userSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('stations').snapshots(),
                  builder: (context, stationSnap) {
                    final totalUsers    = userSnap.data?.docs.length ?? 0;
                    final totalStations = stationSnap.data?.docs.length ?? 0;
                    int openStations    = 0;
                    double totalRevenue = 0;

                    if (stationSnap.hasData) {
                      for (final doc in stationSnap.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        if (d['isOpen'] == true) openStations++;
                        totalRevenue += (d['totalRevenue'] as num?)?.toDouble() ?? 0;
                      }
                    }

                    return Column(
                      children: [
                        Row(children: [
                          _statCard('$totalUsers', 'Total Users',
                              Icons.people_rounded, const Color(0xFF2563EB)),
                          const SizedBox(width: 12),
                          _statCard('$totalStations', 'Stations',
                              Icons.local_gas_station_rounded, const Color(0xFF16A34A)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _statCard('$openStations', 'Open Now',
                              Icons.check_circle_rounded, _T.primary),
                          const SizedBox(width: 12),
                          _statCard(
                            'Rs.${NumberFormat('#,##0').format(totalRevenue)}',
                            'Total Revenue',
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF7C3AED),
                          ),
                        ]),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── QUICK ACTIONS ──
            Text('Quick Actions', style: _T.h2),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _actionCard(
                  icon: Icons.people_rounded,
                  label: 'User\nManagement',
                  color: const Color(0xFF2563EB),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
                ),
                _actionCard(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Station\nManagement',
                  color: const Color(0xFF16A34A),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminStationsScreen())),
                ),
                _actionCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Stock\nAnalysis',
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminStockAnalysisScreen())),
                ),
                _actionCard(
                  icon: Icons.price_change_rounded,
                  label: 'Fuel\nPrices',
                  color: _T.primary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminPriceScreen())),
                ),
                _actionCard(
                  icon: Icons.campaign_rounded,
                  label: 'Broadcast\nMessage',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminBroadcastScreen())),
                ),
                _actionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Registration\nReport',
                  color: const Color(0xFF0891B2),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegistrationReportScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── ALL STATIONS OVERVIEW ──
            Text('All Stations Overview', style: _T.h2),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('stations').limit(10).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _emptyCard('No stations registered yet');
                }
                return Container(
                  decoration: _T.card(),
                  child: Column(
                    children: docs.asMap().entries.map((entry) {
                      final isLast = entry.key == docs.length - 1;
                      final data = entry.value.data() as Map<String, dynamic>;
                      final name = data['stationName'] as String? ??
                          data['name'] as String? ?? 'Unknown Station';
                      final brand   = data['brand'] as String? ?? '';
                      final isOpen  = data['isOpen'] as bool? ?? false;
                      final revenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
                      return _stationRow(name, brand, isOpen, revenue, isLast: isLast);
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── RECENT REGISTRATIONS ──
            Text('Recent Registrations', style: _T.h2),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _emptyCard('No users yet');
                return Container(
                  decoration: _T.card(),
                  child: Column(
                    children: docs.asMap().entries.map((entry) {
                      final isLast = entry.key == docs.length - 1;
                      final data = entry.value.data() as Map<String, dynamic>;
                      final name =
                          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                      final email   = data['email'] as String? ?? '';
                      final ts      = data['createdAt'] as Timestamp?;
                      final timeStr = ts != null
                          ? DateFormat('dd MMM yyyy').format(ts.toDate())
                          : '';
                      return _userRow(
                          name.isNotEmpty ? name : email, email, timeStr,
                          isLast: isLast);
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ──
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Image.asset(
        'assets/logo_wordmark.png',
        height: 22,
        errorBuilder: (_, __, ___) => Text(
          'PETROMIND',
          style: TextStyle(
            fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800,
            color: _T.primary, letterSpacing: 1.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _T.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, color: _T.primary, size: 16),
                  const SizedBox(width: 4),
                  Text('Logout',
                      style: _T.label.copyWith(
                          color: _T.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STAT CARD ──
  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _T.card(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: _T.h2.copyWith(fontSize: 15, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(label, style: _T.label.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTION CARD ──
  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _T.card(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: _T.h2.copyWith(fontSize: 13, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATION ROW ──
  Widget _stationRow(String name, String brand, bool isOpen, double revenue,
      {required bool isLast}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.local_gas_station_rounded,
                    color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: _T.h2.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      brand.isNotEmpty
                          ? brand
                          : 'Rs.${NumberFormat('#,##0').format(revenue)}',
                      style: _T.body.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFF16A34A).withOpacity(0.1)
                      : const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: _T.label.copyWith(
                    color: isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: _T.border, indent: 52),
      ],
    );
  }

  // ── USER ROW ──
  Widget _userRow(String name, String email, String date, {required bool isLast}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _T.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: _T.h2.copyWith(
                        fontSize: 14, color: _T.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: _T.h2.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(email,
                        style: _T.body.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(date, style: _T.label.copyWith(fontSize: 10)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: _T.border, indent: 64),
      ],
    );
  }

  // ── EMPTY STATE ──
  Widget _emptyCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _T.card(),
      child: Center(
        child: Text(msg, style: _T.body),
      ),
    );
  }
}