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
import '../station/registration_report_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final _db = FirebaseFirestore.instance;

  String _getTodayDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, dd MMM yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: Colors.amber.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'ADMIN',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PetroMind',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                color: Colors.white70),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── WELCOME ──
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _getTodayDate(),
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // ── LIVE STATS ROW ──
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .where('role', isEqualTo: 'customer')
                  .snapshots(),
              builder: (context, userSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream:
                      _db.collection('stations').snapshots(),
                  builder: (context, stationSnap) {
                    final totalUsers =
                        userSnap.data?.docs.length ?? 0;
                    final totalStations =
                        stationSnap.data?.docs.length ?? 0;

                    // Count open stations
                    int openStations = 0;
                    double totalRevenue = 0;
                    if (stationSnap.hasData) {
                      for (final doc
                          in stationSnap.data!.docs) {
                        final d = doc.data()
                            as Map<String, dynamic>;
                        if (d['isOpen'] == true)
                          openStations++;
                        totalRevenue +=
                            (d['totalRevenue'] as num?)
                                    ?.toDouble() ??
                                0;
                      }
                    }

                    return Column(
                      children: [
                        Row(children: [
                          _statCard(
                            '$totalUsers',
                            'Total Users',
                            Icons.people_rounded,
                            Colors.blueAccent,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            '$totalStations',
                            'Stations',
                            Icons.local_gas_station,
                            Colors.greenAccent,
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          _statCard(
                            '$openStations',
                            'Open Now',
                            Icons.check_circle_rounded,
                            Colors.orangeAccent,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            'Rs.${NumberFormat('#,##0').format(totalRevenue)}',
                            'Total Revenue',
                            Icons.attach_money,
                            Colors.purpleAccent,
                          ),
                        ]),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── QUICK ACTIONS GRID ──
            const Text(
              'Quick Actions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _actionCard(
                  icon: Icons.people_rounded,
                  label: 'User\nManagement',
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminUsersScreen()),
                  ),
                ),
                _actionCard(
                  icon: Icons.local_gas_station,
                  label: 'Station\nManagement',
                  color: Colors.greenAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminStationsScreen()),
                  ),
                ),
                _actionCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Stock\nAnalysis',
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminStockAnalysisScreen()),
                  ),
                ),
                _actionCard(
                  icon: Icons.price_change_rounded,
                  label: 'Fuel\nPrices',
                  color: Colors.amberAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminPriceScreen()),
                  ),
                ),
                _actionCard(
                  icon: Icons.campaign_rounded,
                  label: 'Broadcast\nMessage',
                  color: Colors.purpleAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminBroadcastScreen()),
                  ),
                ),
                _actionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Registration\nReport',
                  color: Colors.tealAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const RegistrationReportScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── RECENT STATIONS ──
            const Text(
              'All Stations Overview',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('stations')
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.amber));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _emptyCard(
                      'No stations registered yet');
                }
                return Column(
                  children: docs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final name =
                        data['stationName'] as String? ??
                            data['name'] as String? ??
                            'Unknown Station';
                    final brand =
                        data['brand'] as String? ?? '';
                    final isOpen =
                        data['isOpen'] as bool? ?? false;
                    final revenue =
                        (data['totalRevenue'] as num?)
                                ?.toDouble() ??
                            0;
                    return _stationRow(
                        name, brand, isOpen, revenue);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── RECENT USERS ──
            const Text(
              'Recent Registrations',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
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
                      child: CircularProgressIndicator(
                          color: Colors.amber));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _emptyCard('No users yet');
                }
                return Column(
                  children: docs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final name =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                            .trim();
                    final email =
                        data['email'] as String? ?? '';
                    final ts =
                        data['createdAt'] as Timestamp?;
                    final timeStr = ts != null
                        ? DateFormat('dd MMM yyyy')
                            .format(ts.toDate())
                        : '';
                    return _userRow(
                        name.isNotEmpty ? name : email,
                        email,
                        timeStr);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationRow(String name, String brand,
      bool isOpen, double revenue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_gas_station,
                color: Colors.greenAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                    brand.isNotEmpty
                        ? brand
                        : 'Rs.${NumberFormat('#,##0').format(revenue)}',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOpen
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOpen ? 'Open' : 'Closed',
              style: TextStyle(
                  color: isOpen ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(
      String name, String email, String date) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                Colors.blueAccent.withOpacity(0.2),
            radius: 18,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(email,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(date,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white38, fontSize: 13)),
    );
  }
}