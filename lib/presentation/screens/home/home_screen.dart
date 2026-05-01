// ✅ SAME LOGIC — ONLY UI POLISHED

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/user_provider.dart';
import '../../../services/location_service.dart';
import '../prices/price_screen.dart';
import '../stations/stations_screen.dart';
import '../alerts/alerts_screen.dart';
import '../help/help_screen.dart';
import '../help/chatbot_screen.dart';
import '../help/area_chat_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/auth_screen.dart';
import '../../widgets/home/crowd_chart_widget.dart';
import '../../widgets/home/fuel_stock_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _userPosition;
  String _locationLabel = 'Locating...';
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = position;
        _locationLoaded = true;
        _locationLabel = position != null
            ? '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}'
            : 'Colombo, Sri Lanka (default)';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.firstName;

    final now = DateTime.now();
    final days = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    final months = [
      'January','February','March','April','May','June','July','August',
      'September','October','November','December'
    ];

    final dateStr =
        '${days[now.weekday - 1]} ${now.day}${_daySuffix(now.day)} ${months[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: _iconBox(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Home',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _iconBox(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),

      drawer: _buildDrawer(context),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B0000),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text("AI", style: TextStyle(color: Colors.white)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 HEADER CARD (UI ONLY)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFB22222)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome $firstName 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(dateStr,
                      style: const TextStyle(color: Colors.white70)),
                  Text(_locationLabel,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ NEARBY CHAT (LOGIC SAME)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AreaChatScreen(
                    userLat: _userPosition?.latitude ?? 6.9271,
                    userLng: _userPosition?.longitude ?? 79.8612,
                    locationLabel: _locationLabel,
                  ),
                ),
              ),
              child: _cardWrapper(
                child: Row(children: [
                  _circleIcon(Icons.people),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ask Nearby Drivers',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Check fuel availability nearby',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 CROWD CHART (UNCHANGED LOGIC)
            if (!_locationLoaded)
              _loadingCard()
            else
              CrowdChartWidget(
                userLat: _userPosition?.latitude ?? 6.9271,
                userLng: _userPosition?.longitude ?? 79.8612,
                radiusKm: 5.0,
              ),

            const SizedBox(height: 16),

            if (_locationLoaded)
              FuelStockWidget(
                userLat: _userPosition?.latitude ?? 6.9271,
                userLng: _userPosition?.longitude ?? 79.8612,
                radiusKm: 5.0,
              ),

            const SizedBox(height: 16),

            _buildFuelPrices(context),

            const SizedBox(height: 16),

            _buildNearbyStations(context),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 🔥 SMALL UI HELPERS
  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: child,
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF8B0000)),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // 🔥 DRAWER — FULLY PRESERVED
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF8B0000),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _drawerItem(context, Icons.home, 'Home',
                () => Navigator.pop(context)),

            _drawerItem(context, Icons.label, 'Price', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PriceScreen()));
            }),

            _drawerItem(context, Icons.location_on, 'Stations', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StationsScreen()));
            }),

            _drawerItem(context, Icons.notifications, 'Alerts', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()));
            }),

            _drawerItem(context, Icons.people, 'Nearby Chat', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AreaChatScreen(
                    userLat: _userPosition?.latitude ?? 6.9271,
                    userLng: _userPosition?.longitude ?? 79.8612,
                    locationLabel: _locationLabel,
                  ),
                ),
              );
            }),

            _drawerItem(context, Icons.help_outline, 'Help', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()));
            }),

            _drawerItem(context, Icons.settings, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),

            const SizedBox(height: 20),

            // ✅ LOGOUT RESTORED
            _drawerItem(context, Icons.logout, 'Log out', () async {
              final provider =
                  Provider.of<UserProvider>(context, listen: false);
              await provider.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  // 🔥 KEEP YOUR ORIGINAL METHODS BELOW (NO CHANGE)
  // ================== FUEL PRICES ==================

Widget _buildFuelPrices(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('fuel_prices_ceypetco')
        .where('category', isEqualTo: 'retail')
        .snapshots(),
    builder: (context, snapshot) {
      Map<String, double> prices = {};
      if (snapshot.hasData) {
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          prices[doc.id] =
              (data['price'] as num?)?.toDouble() ?? 0;
        }
      }

      final petrol92 = prices['petrol_92'];
      final diesel = prices['auto_diesel'];
      final superDiesel = prices['super_diesel'];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFFB22222)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Prices',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _fuelCard(
                  'Petrol',
                  petrol92 != null
                      ? 'Rs.${petrol92.toStringAsFixed(0)}'
                      : 'Loading...',
                ),
                const SizedBox(width: 10),
                _fuelCard(
                  'Diesel',
                  diesel != null
                      ? 'Rs.${diesel.toStringAsFixed(0)}'
                      : 'Loading...',
                ),
                const SizedBox(width: 10),
                _fuelCard(
                  'Super\nDiesel',
                  superDiesel != null
                      ? 'Rs.${superDiesel.toStringAsFixed(0)}'
                      : 'Loading...',
                  highlight: true,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PriceScreen()),
                ),
                child: const Text(
                  'View more →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ================== FUEL CARD ==================

Widget _fuelCard(String name, String price,
    {bool highlight = false}) {
  return Expanded(
    child: Container(
      height: 90, // ✅ FORCE SAME HEIGHT
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: Colors.red, width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTER EVERYTHING
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name.replaceAll('\n', ' '), // ✅ REMOVE WEIRD WRAP
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_gas_station,
                size: 14,
                color: highlight
                    ? Colors.red
                    : const Color(0xFF8B0000),
              ),
              const SizedBox(width: 4),
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
        ],
      ),
    ),
  );
}

// ================== NEARBY STATIONS ==================

Widget _buildNearbyStations(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF8B0000), Color(0xFFB22222)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Stations',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),

        const SizedBox(height: 12),

        _stationCard('Laugfs station'),
        const SizedBox(height: 10),
        _stationCard('Ceypetco station'),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StationsScreen()),
            ),
            child: const Text(
              'See all →',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
  );
}

// ================== STATION CARD ==================

Widget _stationCard(String name) {
  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const StationsScreen()),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: Color(0xFF8B0000),
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600),
            ),
          ),

          const Icon(Icons.arrow_forward_ios,
              size: 14, color: Color(0xFF8B0000)),
        ],
      ),
    ),
  );
}
}