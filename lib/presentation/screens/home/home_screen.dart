import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/user_provider.dart';
import '../prices/price_screen.dart';
import '../stations/stations_screen.dart';
import '../alerts/alerts_screen.dart';
import '../help/help_screen.dart';
import '../help/chatbot_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/auth_screen.dart';
import '../../widgets/home/crowd_chart_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.firstName;

    final now = DateTime.now();
    final days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayName = days[now.weekday - 1];
    final dateStr =
        '$dayName ${now.day}${_daySuffix(now.day)} ${months[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Home',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B0000),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ChatbotScreen()),
        ),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label:
            const Text("AI", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── WELCOME ──
            Text(
              'Welcome $firstName,',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              dateStr,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Text(
              'Colombo, Sri Lanka',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── CROWD CHART (REAL-TIME) ──
            const CrowdChartWidget(),
            const SizedBox(height: 16),

            // ── FUEL PRICES ──
            _buildFuelPrices(context),
            const SizedBox(height: 16),

            // ── NEARBY STATIONS ──
            _buildNearbyStations(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // ───────── DRAWER ─────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF8B0000),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const SizedBox(height: 20),
            _drawerItem(context, Icons.home, 'Home',
                () => Navigator.pop(context)),
            _drawerItem(context, Icons.label, 'Price', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PriceScreen()));
            }),
            _drawerItem(context, Icons.location_on, 'Stations',
                () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const StationsScreen()));
            }),
            _drawerItem(context, Icons.notifications, 'Alerts',
                () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AlertsScreen()));
            }),
            _drawerItem(context, Icons.help_outline, 'Help', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HelpScreen()));
            }),
            _drawerItem(context, Icons.settings, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
            }),
            const SizedBox(height: 20),
            _drawerItem(context, Icons.logout, 'Log out', () async {
              final provider =
                  Provider.of<UserProvider>(context, listen: false);
              await provider.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AuthScreen()),
                (route) => false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon,
      String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  // ───────── FUEL PRICES ─────────
  Widget _buildFuelPrices(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _fuelCard('Petrol', 'Rs.298'),
              const SizedBox(width: 8),
              _fuelCard('Diesel', 'Rs.246'),
              const SizedBox(width: 8),
              _fuelCard('Super\nDiesel', 'Rs.281',
                  highlight: true),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PriceScreen()),
              ),
              child: const Text('View more>>',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelCard(String name, String price,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                color: highlight
                    ? Colors.red
                    : const Color(0xFF8B0000),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── NEARBY STATIONS ─────────
  Widget _buildNearbyStations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find nearby stations',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 12),
          _stationCard(context, 'Laugfs station'),
          const SizedBox(height: 8),
          _stationCard(context, 'Ceypetco station'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StationsScreen()),
              ),
              child: const Text('See all>>',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationCard(BuildContext context, String name) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const StationsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500)),
            ),
            const Text('View on map>>',
                style: TextStyle(
                    color: Color(0xFF8B0000), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}