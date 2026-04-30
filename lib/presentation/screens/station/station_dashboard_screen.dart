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
import 'registration_report_screen.dart';
import '../auth/auth_screen.dart';
import '../prices/admin_price_screen.dart';

class StationDashboardScreen extends StatefulWidget {
  const StationDashboardScreen({super.key});

  @override
  State<StationDashboardScreen> createState() =>
      _StationDashboardScreenState();
}

class _StationDashboardScreenState
    extends State<StationDashboardScreen> {

  // ── Price change listener cancel function ──
  Function()? _cancelPriceListener;

  @override
  void initState() {
    super.initState();
    Future.delayed(
        const Duration(seconds: 2), _checkStockAlerts);

    // ── Start listening to government fuel price changes ──
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _cancelPriceListener =
          NotificationService.listenToGlobalPriceChanges(
        stationId: uid,
      );
    }
  }

  @override
  void dispose() {
    // ── Cancel listener when dashboard is disposed ──
    _cancelPriceListener?.call();
    super.dispose();
  }

  Future<void> _checkStockAlerts() async {
    try {
      final provider =
          Provider.of<UserProvider>(context, listen: false);
      final stationName = provider.firstName.isNotEmpty
          ? provider.firstName
          : 'PetroMind Station';
      final uid =
          FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final stockSnap = await FirebaseFirestore.instance
          .collection('stations')
          .doc(uid)
          .collection('stock')
          .get();
      for (final doc in stockSnap.docs) {
        final data = doc.data();
        final fuelType =
            data['fuelType'] as String? ?? doc.id;
        final stockLiters =
            (data['stockLitres'] as num?)?.toDouble() ?? 0;
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
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    final stationName = provider.firstName.isNotEmpty
        ? provider.firstName
        : 'PetroMind Station';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: _buildAppBar(context, uid),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome Back, $stationName!',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(_getTodayDate(),
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),

            // ── UPDATE FUEL PRICES BUTTON ──
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const AdminPriceScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          Colors.orange.withOpacity(0.5)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.orange,
                        size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Update Fuel Prices',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 14)),
                        Text(
                            'Tap to update CPC fuel prices for all customers',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white54, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 8),

            _alertCard('Recent Activity',
                'Air Pump Welcomed', '2 hrs ago'),
            const SizedBox(height: 8),
            _alertCard('Price Update',
                'Prices updated today', '4 hrs ago'),
            const SizedBox(height: 16),

            // ── STATS ROW ──
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data()
                    as Map<String, dynamic>?;
                final revenue =
                    (data?['totalRevenue'] as num?)
                            ?.toDouble() ??
                        0;
                final isOpen =
                    data?['isOpen'] as bool? ?? false;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stations')
                      .doc(uid)
                      .collection('stock')
                      .snapshots(),
                  builder: (context, stockSnap) {
                    double totalStock = 0;
                    if (stockSnap.hasData) {
                      for (final doc
                          in stockSnap.data!.docs) {
                        final d = doc.data()
                            as Map<String, dynamic>;
                        totalStock +=
                            (d['stockLitres'] as num?)
                                    ?.toDouble() ??
                                0;
                      }
                    }
                    return Row(children: [
                      _statCard(
                        'LKR ${NumberFormat('#,##0').format(revenue)}',
                        'Total Revenue',
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        '${totalStock.toStringAsFixed(0)}L',
                        'Stock Level',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        isOpen ? 'Open' : 'Closed',
                        'Status',
                        isOpen
                            ? Colors.green
                            : Colors.red,
                      ),
                    ]);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // ── REGISTRATION REPORT BANNER ──
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const RegistrationReportScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF8B0000)
                          .withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.04),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart,
                        color: Color(0xFF8B0000),
                        size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Registration Report',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF8B0000)),
                        ),
                        Text(
                          'View monthly registration trends',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF8B0000),
                      size: 14),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── 7 DAY SALES ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('7 Day Sales Overview',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const StockManagementScreen(),
                          ),
                        ),
                        child: const Text(
                            'View Report >',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(children: [
                    Text('1,450 L - Petrol 92',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 11)),
                    SizedBox(width: 8),
                    Text('1,450 L - Petrol 95',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11)),
                    SizedBox(width: 8),
                    Text('Diesel >',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        _miniBar(0.4, Colors.green),
                        _miniBar(0.6, Colors.green),
                        _miniBar(0.5, Colors.orange),
                        _miniBar(0.8, Colors.orange),
                        _miniBar(0.7, Colors.green),
                        _miniBar(1.0, Colors.orange),
                        _miniBar(0.6, Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── LOW STOCK ALERTS ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Low Stock Alerts',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const StationNotificationsScreen(),
                          ),
                        ),
                        child: const Text(
                            'Manage Alerts >',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await AlertRepository.publishAlert(
                        type: 'low_stock',
                        title: '⚠️ Low Stock Alert',
                        message:
                            'Petrol 92 is running LOW at $stationName — only 120L remaining.',
                        stationId: uid,
                        stationName: stationName,
                        extraData: {
                          'fuelType': 'Petrol 92',
                          'stockLiters': 120,
                        },
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              '⚠️ Low stock alert sent!'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ));
                      }
                    },
                    child: _stockAlertRow('Petrol 92',
                        '120L remaining', Colors.red),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await AlertRepository.publishAlert(
                        type: 'peak_hour',
                        title:
                            '🕐 Peak Hour at $stationName',
                        message:
                            'High crowd at $stationName Air Pump — consider visiting later.',
                        stationId: uid,
                        stationName: stationName,
                        extraData: {'crowdCount': 15},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              '🕐 Peak hour alert sent!'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ));
                      }
                    },
                    child: _stockAlertRow(
                        'Air Pump', 'Busy', Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── MAINTENANCE / REOPEN BUTTONS ──
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await AlertRepository
                        .alertMaintenance(
                      stationId: uid,
                      stationName: stationName,
                      isClosed: true,
                      reason: 'Scheduled maintenance',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text(
                            '🔧 Maintenance alert sent!'),
                        backgroundColor: Colors.purple,
                        duration: Duration(seconds: 2),
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Colors.purple.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.purple
                              .withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build,
                            color: Colors.purple,
                            size: 16),
                        SizedBox(width: 6),
                        Text('Send Closure Alert',
                            style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await AlertRepository
                        .alertMaintenance(
                      stationId: uid,
                      stationName: stationName,
                      isClosed: false,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content:
                            Text('✅ Reopen alert sent!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Colors.green.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.green
                              .withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green,
                            size: 16),
                        SizedBox(width: 6),
                        Text('Send Reopen Alert',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── RECENT ACTIVITY (live from notifications) ──
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
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text('Recent Activity',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StationNotificationsScreen(),
                              ),
                            ),
                            child: const Text(
                                'See All >',
                                style: TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (docs.isEmpty)
                        const Text(
                          'No recent activity yet',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12),
                        )
                      else
                        ...docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          final msg =
                              data['message'] as String? ??
                                  '';
                          final ts = data['timestamp']
                              as Timestamp?;
                          final timeStr = ts != null
                              ? _formatTime(
                                  ts.toDate())
                              : '';
                          return _activityRow(
                              msg, timeStr);
                        }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, String uid) {
    return AppBar(
      backgroundColor: const Color(0xFF8B0000),
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu,
              color: Colors.white),
          onPressed: () =>
              Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Image.asset(
        'assets/images/logo.png',
        height: 32,
        errorBuilder: (c, e, s) => const Text(
          'PetroMind',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        // ── Notification bell with unread badge ──
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stations')
              .doc(uid)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unread =
                snapshot.data?.docs.length ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications,
                      color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StationNotificationsScreen(),
                    ),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const StationProfileScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(Icons.person,
                  color: Color(0xFF8B0000), size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF8B0000),
      child: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.symmetric(vertical: 20),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/logo.png',
                height: 40,
                errorBuilder: (c, e, s) => const Text(
                  'PetroMind',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(color: Colors.white24),
            _drawerItem(context, Icons.dashboard,
                'Dashboard',
                () => Navigator.pop(context)),
            _drawerItem(context, Icons.price_change,
                'Update Fuel Prices', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminPriceScreen()));
            }),
            _drawerItem(context, Icons.inventory,
                'Stock Management', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const StockManagementScreen()));
            }),
            _drawerItem(context, Icons.receipt_long,
                'Sales & Transactions', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const SalesTransactionsScreen()));
            }),
            _drawerItem(context, Icons.bar_chart,
                'Registration Report', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const RegistrationReportScreen()));
            }),
            _drawerItem(context, Icons.notifications,
                'Notifications', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const StationNotificationsScreen()));
            }),
            _drawerItem(context, Icons.store,
                'Station Profile', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const StationProfileScreen()));
            }),
            _drawerItem(context, Icons.feedback,
                'Customer Feedback', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const CustomerFeedbackScreen()));
            }),
            _drawerItem(
                context,
                Icons.admin_panel_settings,
                'Admin Settings', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminSettingsScreen()));
            }),
            const Divider(color: Colors.white24),
            _drawerItem(context, Icons.logout, 'Log Out',
                () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AuthScreen()),
                      (route) => false,
                    )),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon,
      String title, VoidCallback onTap) {
    return ListTile(
      leading:
          Icon(icon, color: Colors.white, size: 22),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }

  Widget _alertCard(
      String title, String sub, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.notifications,
            color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text(sub,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12)),
            ],
          ),
        ),
        Text(time,
            style: const TextStyle(
                color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  Widget _statCard(
      String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B0000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 9),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _miniBar(double h, Color color) {
    return Container(
      width: 24,
      height: 80 * h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _stockAlertRow(
      String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(Icons.warning, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13)),
        ),
        Text(status,
            style:
                TextStyle(color: color, fontSize: 12)),
      ]),
    );
  }

  Widget _activityRow(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        const Icon(Icons.circle,
            color: Colors.amber, size: 8),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(time,
            style: const TextStyle(
                color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}