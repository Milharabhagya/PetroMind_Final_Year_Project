import 'package:flutter/material.dart';
import 'stock_management_screen.dart';
import 'sales_transactions_screen.dart';
import 'station_notifications_screen.dart';
import 'station_profile_screen.dart';
import 'customer_feedback_screen.dart';
import 'admin_settings_screen.dart';
import 'fuel_price_management_screen.dart';
import '../auth/auth_screen.dart';
import '../prices/admin_price_screen.dart';

class StationDashboardScreen extends StatelessWidget {
  const StationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back, Kaduwela IOC!',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('25/12/2016',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),

            // ── UPDATE FUEL PRICES BUTTON ──
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminPriceScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_gas_station,
                          color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Update Fuel Prices',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(
                              'Tap to update CPC fuel prices for all customers',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── ALERTS ──
            _alertCard(
                'Recent Activity', 'Air Pump Welcomed', '2 hrs ago'),
            const SizedBox(height: 8),
            _alertCard(
                'Price Update', 'Prices updated today', '4 hrs ago'),
            const SizedBox(height: 16),

            // ── STATS ROW ──
            Row(
              children: [
                _statCard('452,600', 'Total Sales (LKR)', Colors.green),
                const SizedBox(width: 8),
                _statCard('6,200L', 'Stock Level', Colors.blue),
                const SizedBox(width: 8),
                _statCard('3,488', 'Customers', Colors.orange),
                const SizedBox(width: 8),
                _statCard('Closed', 'Current Status', Colors.red),
              ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('7 Day Sales Overview',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const StockManagementScreen(),
                          ),
                        ),
                        child: const Text('View Report >',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text('1,450 L - Petrol 92',
                          style: TextStyle(
                              color: Colors.green, fontSize: 11)),
                      SizedBox(width: 8),
                      Text('1,450 L - Petrol 95',
                          style: TextStyle(
                              color: Colors.orange, fontSize: 11)),
                      SizedBox(width: 8),
                      Text('Diesel >',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Low Stock Alerts',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const StationNotificationsScreen(),
                          ),
                        ),
                        child: const Text('Manage Alerts >',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _stockAlertRow(
                      'Petrol 92', '120L remaining', Colors.red),
                  _stockAlertRow('Air Pump', 'Busy', Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── RECENT ACTIVITY ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("Today's Top Alerts",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _activityRow('Air Pump Notified', '2 hrs ago'),
                  _activityRow('Air Pump Down', '3 hrs ago'),
                  _activityRow(
                      'Lank Stock Diesel Oil', '4 hrs ago'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF8B0000),
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Image.asset(
        'assets/images/logo.png',
        height: 32,
        errorBuilder: (c, e, s) => const Text(
          'PetroMind',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StationNotificationsScreen(),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const StationProfileScreen()),
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
          padding: const EdgeInsets.symmetric(vertical: 20),
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
            _drawerItem(context, Icons.dashboard, 'Dashboard',
                () => Navigator.pop(context)),

            // ── UPDATE FUEL PRICES IN DRAWER ──
            _drawerItem(
                context, Icons.price_change, 'Update Fuel Prices',
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminPriceScreen()),
              );
            }),

            _drawerItem(
                context,
                Icons.local_gas_station,
                'Fuel Price Management',
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const FuelPriceManagementScreen()),
              );
            }),
            _drawerItem(context, Icons.inventory, 'Stock Management',
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StockManagementScreen()),
              );
            }),
            _drawerItem(
                context, Icons.receipt_long, 'Sales & Transactions',
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const SalesTransactionsScreen()),
              );
            }),
            _drawerItem(
                context, Icons.notifications, 'Notifications', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const StationNotificationsScreen()),
              );
            }),
            _drawerItem(context, Icons.store, 'Station Profile', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StationProfileScreen()),
              );
            }),
            _drawerItem(
                context, Icons.feedback, 'Customer Feedback', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const CustomerFeedbackScreen()),
              );
            }),
            _drawerItem(
                context,
                Icons.admin_panel_settings,
                'Admin Settings',
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminSettingsScreen()),
              );
            }),
            const Divider(color: Colors.white24),
            _drawerItem(
                context,
                Icons.logout,
                'Log Out',
                () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AuthScreen()),
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
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }

  Widget _alertCard(String title, String sub, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications,
              color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(sub,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B0000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
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
      child: Row(
        children: [
          Icon(Icons.warning, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13)),
          ),
          Text(status,
              style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _activityRow(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle,
              color: Colors.amber, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13)),
          ),
          Text(time,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}