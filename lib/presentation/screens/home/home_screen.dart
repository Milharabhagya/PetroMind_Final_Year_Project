import 'package:flutter/material.dart';
import '../prices/price_screen.dart';
import '../stations/stations_screen.dart';
import '../alerts/alerts_screen.dart';
import '../help/help_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: Builder(builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        title: const Text('Home',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Mark,',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Monday 25th February 2026',
                style: TextStyle(color: Colors.grey)),
            const Text('Colombo Sri Lanka',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _buildCrowdChart(),
            const SizedBox(height: 16),
            _buildFuelPrices(context),
            const SizedBox(height: 16),
            _buildNearbyStations(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF8B0000)),
            child: Text('PetroMind',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _drawerItem(context, Icons.home, 'Home', () => Navigator.pop(context)),
          _drawerItem(context, Icons.attach_money, 'Prices',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceScreen()))),
          _drawerItem(context, Icons.location_on, 'Stations',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StationsScreen()))),
          _drawerItem(context, Icons.notifications, 'Alerts',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()))),
          _drawerItem(context, Icons.help, 'Help',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
          _drawerItem(context, Icons.settings, 'Settings',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8B0000)),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildCrowdChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('When to Fill Your Tank?',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Text('Plan your visit to avoid the crowds.',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, 'Best Time  8 AM - 10 AM'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Worst Time  6 PM - 8 PM'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bar(0.3, Colors.green),
                _bar(0.2, Colors.green),
                _bar(0.4, Colors.green),
                _bar(0.5, Colors.orange),
                _bar(0.6, Colors.orange),
                _bar(0.7, Colors.red),
                _bar(0.9, Colors.red),
                _bar(1.0, Colors.red),
                _bar(0.8, Colors.red),
                _bar(0.6, Colors.orange),
                _bar(0.4, Colors.orange),
                _bar(0.3, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 18,
      height: 80 * height,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4)),
    );
  }

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
              _fuelCard('Super\nDiesel', 'Rs.281', highlight: true),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PriceScreen())),
              child: const Text('View more>>',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelCard(String name, String price, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    color: highlight ? Colors.red : const Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

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
          const Text('Find nearby stations',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _stationCard('Laugfs station'),
          const SizedBox(height: 8),
          _stationCard('Ceypetco station'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StationsScreen())),
              child: const Text('See all>>',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationCard(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_gas_station,
              color: Color(0xFF8B0000), size: 24),
          const SizedBox(width: 8),
          Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          const Text('View on map>>',
              style: TextStyle(color: Color(0xFF8B0000), fontSize: 12)),
        ],
      ),
    );
  }
}