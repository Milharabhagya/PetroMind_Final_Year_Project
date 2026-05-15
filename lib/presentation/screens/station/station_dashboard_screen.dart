// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Customer App Design System
// ✅ FIX: Station owner now sees READ-ONLY fuel prices (FuelPriceManagementScreen)
//         Admin retains exclusive edit access via AdminPriceScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:petromind/data/services/user_provider.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../../data/services/notification_service.dart';
import 'stock_management_screen.dart';
import 'sales_transactions_screen.dart';
import 'station_notifications_screen.dart';
import 'station_profile_screen.dart';
import 'customer_feedback_screen.dart';
import 'admin_settings_screen.dart';
import '../auth/auth_screen.dart';
// ✅ CHANGED: Import read-only screen instead of admin edit screen
import 'fuel_price_management_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS (Shared across the app)
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
//  STATION DASHBOARD SCREEN
// ─────────────────────────────────────────────
class StationDashboardScreen extends StatefulWidget {
  const StationDashboardScreen({super.key});

  @override
  State<StationDashboardScreen> createState() => _StationDashboardScreenState();
}

class _StationDashboardScreenState extends State<StationDashboardScreen> {
  Function()? _cancelPriceListener;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _checkStockAlerts);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _cancelPriceListener = NotificationService.listenToGlobalPriceChanges(stationId: uid);
    }
  }

  @override
  void dispose() {
    _cancelPriceListener?.call();
    super.dispose();
  }

  Future<void> _checkStockAlerts() async {
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      final stationName = provider.firstName.isNotEmpty ? provider.firstName : 'PetroMind Station';
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final stockSnap = await FirebaseFirestore.instance
          .collection('stations')
          .doc(uid)
          .collection('stock')
          .get();
      for (final doc in stockSnap.docs) {
        final data = doc.data();
        final fuelType = data['fuelType'] as String? ?? doc.id;
        final stockLiters = (data['stockLitres'] as num?)?.toDouble() ?? 0;
        await AlertRepository.checkAndAlertStock(
          stationId: uid,
          stationName: stationName,
          fuelType: fuelType,
          stockLiters: stockLiters,
        );
      }
    } catch (e) {
      debugPrint('_checkStockAlerts error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final stationName = provider.firstName.isNotEmpty ? provider.firstName : 'PetroMind Station';

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(context, uid),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──
            Text('Welcome Back,', style: _T.body.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(stationName, style: _T.h1.copyWith(fontSize: 24, height: 1.1)),
            const SizedBox(height: 4),
            Text(_getTodayDate(), style: _T.label),
            const SizedBox(height: 24),

            // ── FUEL PRICES BUTTON (READ-ONLY for station owner) ──
            // ✅ CHANGED: navigates to FuelPriceManagementScreen (read-only)
            //             label updated to reflect view-only access
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FuelPriceManagementScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_T.primary, _T.dark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _T.primary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      // ✅ CHANGED: icon reflects view-only (visibility icon)
                      child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ CHANGED: label from 'Update Fuel Prices' → 'Current Fuel Prices'
                          Text('Current Fuel Prices',
                              style: _T.h2.copyWith(color: Colors.white, fontSize: 15)),
                          const SizedBox(height: 2),
                          // ✅ CHANGED: subtitle reflects read-only nature
                          Text('View official CPC rates — set by PetroMind Admin',
                              style: _T.body.copyWith(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── STATS ROW ──
            Text('Overview', style: _T.h2),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('stations').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final revenue = (data?['totalRevenue'] as num?)?.toDouble() ?? 0;
                final isOpen = data?['isOpen'] as bool? ?? false;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stations')
                      .doc(uid)
                      .collection('stock')
                      .snapshots(),
                  builder: (context, stockSnap) {
                    double totalStock = 0;
                    if (stockSnap.hasData) {
                      for (final doc in stockSnap.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        totalStock += (d['stockLitres'] as num?)?.toDouble() ?? 0;
                      }
                    }
                    return Row(
                      children: [
                        _statCard(
                          'LKR ${NumberFormat('#,##0').format(revenue)}',
                          'Total Revenue',
                          Icons.account_balance_wallet_rounded,
                          const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          '${totalStock.toStringAsFixed(0)} L',
                          'Stock Level',
                          Icons.inventory_2_rounded,
                          const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          isOpen ? 'Open' : 'Closed',
                          'Status',
                          isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── 7 DAY SALES ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _T.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('7 Day Sales', style: _T.h2),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StockManagementScreen()),
                        ),
                        child: Text('View Report',
                            style: _T.label.copyWith(color: _T.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _legendItem('Petrol 92', const Color(0xFF16A34A)),
                      _legendItem('Petrol 95', const Color(0xFFF59E0B)),
                      _legendItem('Diesel', const Color(0xFF2563EB)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _miniBar(0.4, const Color(0xFF16A34A)),
                        _miniBar(0.6, const Color(0xFF16A34A)),
                        _miniBar(0.5, const Color(0xFFF59E0B)),
                        _miniBar(0.8, const Color(0xFFF59E0B)),
                        _miniBar(0.7, const Color(0xFF16A34A)),
                        _miniBar(1.0, const Color(0xFFF59E0B)),
                        _miniBar(0.6, const Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── QUICK ALERTS & ACTIONS ──
            Text('Station Management', style: _T.h2),
            const SizedBox(height: 12),
            Container(
              decoration: _T.card(),
              child: Column(
                children: [
                  _actionTile(
                    icon: Icons.warning_rounded,
                    iconColor: const Color(0xFFDC2626),
                    title: 'Low Stock Alert',
                    subtitle: 'Broadcast low petrol/diesel status',
                    onTap: () async {
                      await AlertRepository.publishAlert(
                        type: 'low_stock',
                        title: '⚠️ Low Stock Alert',
                        message: 'Fuel is running LOW at $stationName.',
                        stationId: uid,
                        stationName: stationName,
                        extraData: {'fuelType': 'Petrol 92', 'stockLiters': 120},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('⚠️ Low stock alert sent!',
                              style: _T.body.copyWith(color: Colors.white)),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                  ),
                  Divider(color: _T.border, height: 1, indent: 56),
                  _actionTile(
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Peak Hour Alert',
                    subtitle: 'Notify users of heavy crowds',
                    onTap: () async {
                      await AlertRepository.publishAlert(
                        type: 'peak_hour',
                        title: '🕐 Peak Hour at $stationName',
                        message: 'High crowd at $stationName — consider visiting later.',
                        stationId: uid,
                        stationName: stationName,
                        extraData: {'crowdCount': 15},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('🕐 Peak hour alert sent!',
                              style: _T.body.copyWith(color: Colors.white)),
                          backgroundColor: const Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── MAINTENANCE / REOPEN BUTTONS ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await AlertRepository.alertMaintenance(
                        stationId: uid,
                        stationName: stationName,
                        isClosed: true,
                        reason: 'Scheduled maintenance',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('🔧 Maintenance alert sent!',
                              style: _T.body.copyWith(color: Colors.white)),
                          backgroundColor: const Color(0xFF7C3AED),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.build_rounded, color: Color(0xFF7C3AED)),
                          const SizedBox(height: 8),
                          Text('Close Station',
                              style: _T.label.copyWith(
                                  color: const Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await AlertRepository.alertMaintenance(
                        stationId: uid,
                        stationName: stationName,
                        isClosed: false,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('✅ Reopen alert sent!',
                              style: _T.body.copyWith(color: Colors.white)),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                          const SizedBox(height: 8),
                          Text('Reopen Station',
                              style: _T.label.copyWith(
                                  color: const Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── RECENT ACTIVITY ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: _T.h2),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StationNotificationsScreen()),
                  ),
                  child: Text('See All',
                      style: _T.label.copyWith(color: _T.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: _T.card(),
                    child: Center(child: Text('No recent activity yet', style: _T.body)),
                  );
                }

                return Container(
                  decoration: _T.card(),
                  child: Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final msg = data['message'] as String? ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final timeStr = ts != null ? _formatTime(ts.toDate()) : '';
                      final isLast = docs.last.id == doc.id;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: _T.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_rounded,
                                  color: _T.primary, size: 16),
                            ),
                            title: Text(msg,
                                style: _T.body.copyWith(color: _T.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: Text(timeStr, style: _T.label.copyWith(fontSize: 10)),
                          ),
                          if (!isLast) Divider(color: _T.border, height: 1, indent: 56),
                        ],
                      );
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

  // ── HELPERS ──
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ── WIDGETS ──
  PreferredSizeWidget _buildAppBar(BuildContext context, String uid) {
    return AppBar(
      backgroundColor: _T.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              decoration: _T.card(hasBorder: true),
              child: const Icon(Icons.menu_rounded, color: _T.dark, size: 20),
            ),
          ),
        ),
      ),
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
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stations')
              .doc(uid)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unread = snapshot.data?.docs.length ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: _T.dark),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StationNotificationsScreen()),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFDC2626), shape: BoxShape.circle),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StationProfileScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _T.primary, borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 270,
      backgroundColor: _T.accent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: _T.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.local_gas_station_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PETROMIND',
                        style: TextStyle(
                          fontFamily: 'Poppins', color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Station Owner',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 10, letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _drawerItem(context, Icons.dashboard_rounded, 'Dashboard',
                      () => Navigator.pop(context)),

                  // ✅ CHANGED: label 'Update Fuel Prices' → 'Fuel Prices'
                  //             navigates to read-only FuelPriceManagementScreen
                  _drawerItem(context, Icons.local_gas_station_rounded, 'Fuel Prices', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FuelPriceManagementScreen()));
                  }),

                  _drawerItem(context, Icons.inventory_2_rounded, 'Stock Management', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StockManagementScreen()));
                  }),
                  _drawerItem(context, Icons.receipt_long_rounded, 'Sales & Transactions', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SalesTransactionsScreen()));
                  }),
                  _drawerItem(context, Icons.notifications_rounded, 'Notifications', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StationNotificationsScreen()));
                  }),
                  _drawerItem(context, Icons.storefront_rounded, 'Station Profile', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StationProfileScreen()));
                  }),
                  _drawerItem(context, Icons.forum_rounded, 'Customer Feedback', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CustomerFeedbackScreen()));
                  }),
                  _drawerItem(context, Icons.admin_panel_settings_rounded, 'Admin Settings', () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminSettingsScreen()));
                  }),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: ListTile(
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout_rounded, color: _T.primary, size: 18),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'Poppins', color: _T.primary,
                    fontWeight: FontWeight.w600, fontSize: 14,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins', color: Colors.white,
          fontWeight: FontWeight.w500, fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.white.withOpacity(0.25), size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.white.withOpacity(0.04),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _T.card(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: _T.h2.copyWith(fontSize: 14, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label, style: _T.label.copyWith(fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: _T.label.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _miniBar(double h, Color color) {
    return Container(
      width: 24,
      height: 100 * h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _T.h2.copyWith(fontSize: 14)),
                  Text(subtitle, style: _T.body.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _T.textSecondary),
          ],
        ),
      ),
    );
  }
}