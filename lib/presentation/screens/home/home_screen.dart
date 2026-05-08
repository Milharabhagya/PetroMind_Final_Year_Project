// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Industrial SaaS · Dark Red + Cream · Poppins
// Colors: Primary #AD2831 · Dark #38040E · Accent #250902

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Added for reverse geocoding
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
import 'package:http/http.dart' as http;
import 'dart:convert'; 

// ─────────────────────────────────────────────
//  DESIGN TOKENS
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
  static const price = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: primary,
    letterSpacing: -0.5,
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

  static BoxDecoration pill() => BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
      );
}

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Position? _userPosition;
  String _locationLabel = 'Locating...';
  bool _locationLoaded = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchLocation();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── LOGIC PRESERVED & ENHANCED ──
  Future<void> _fetchLocation() async {
  final position = await LocationService.getCurrentLocation();
  String resolvedLocation = 'Location unavailable';

  if (position != null) {
    try {
      // 1. Prepare the OpenStreetMap Nominatim URL
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10&addressdetails=1'
      );

      // 2. Make the request
      // IMPORTANT: Nominatim requires a User-Agent header to identify your app
      final response = await http.get(url, headers: {
        'User-Agent': 'PetroMind_App_v1.0', 
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        // 3. Extract the best possible area name
        String? city = address['city'] ?? 
                       address['town'] ?? 
                       address['village'] ?? 
                       address['suburb'] ?? 
                       address['county'];
        
        String? country = address['country'];

        if (city != null && country != null) {
          resolvedLocation = '$city, $country';
        } else if (city != null) {
          resolvedLocation = city;
        } else {
          resolvedLocation = '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
        }
      }
    } catch (e) {
      debugPrint('🔴 Free Geocoding Error: $e');
      // Fallback to coordinates if the network call fails
      resolvedLocation = '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
    }
  }

  if (mounted) {
    setState(() {
      _userPosition = position;
      _locationLoaded = true;
      _locationLabel = resolvedLocation;
    });
    _fadeCtrl.forward();
  }
}

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.firstName;

    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['January','February','March','April','May','June','July',
        'August','September','October','November','December'];
    final dateStr =
        '${days[now.weekday - 1]}, ${now.day}${_daySuffix(now.day)} ${months[now.month - 1]}';

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      floatingActionButton: _buildFAB(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(firstName, dateStr),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildSectionHeader('Live Activity', Icons.radio_button_checked),
              const SizedBox(height: 12),
              _buildNearbyChatTile(context),
              const SizedBox(height: 12),
              if (!_locationLoaded) _buildSkeletonCard(200)
              else CrowdChartWidget(
                userLat: _userPosition?.latitude ?? 6.9271,
                userLng: _userPosition?.longitude ?? 79.8612,
                radiusKm: 5.0,
              ),
              const SizedBox(height: 12),
              if (_locationLoaded)
                FuelStockWidget(
                  userLat: _userPosition?.latitude ?? 6.9271,
                  userLng: _userPosition?.longitude ?? 79.8612,
                  radiusKm: 5.0,
                ),
              const SizedBox(height: 20),
              _buildSectionHeader('Market Rates', Icons.trending_up_rounded),
              const SizedBox(height: 12),
              _buildFuelPrices(context),
              const SizedBox(height: 20),
              _buildSectionHeader('Nearby Stations', Icons.location_on_rounded),
              const SizedBox(height: 12),
              _buildNearbyStations(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Container(
            // Top and bottom margins ensure the button height is constrained
            // resulting in a perfect, clean square button.
            margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            decoration: _T.card(hasBorder: true),
            child: const Icon(Icons.menu_rounded,
                color: _T.dark, size: 20),
          ),
        ),
      ),
      title: Image.asset(
        'assets/logo_wordmark.png',
        height: 22,
        errorBuilder: (_, __, ___) => Text(
          'PETROMIND', // Updated App Name
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _T.primary,
            letterSpacing: 1.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: _T.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            // Replaced icon slightly if user wants exact square, 
            // but aspect ratio fits the 40x40 dimension perfectly.
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  HERO CARD
  // ─────────────────────────────────────────────
  Widget _buildHeroCard(String firstName, String dateStr) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_T.accent, _T.dark, _T.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -16,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: _T.label.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: _T.body.copyWith(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Welcome back,',
                  style: _T.body.copyWith(
                      color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '$firstName 👋',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationLabel,
                        style: _T.body.copyWith(
                            color: Colors.white54, fontSize: 12), // slightly increased readability
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK ACTIONS ROW
  // ─────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final items = [
      _QuickAction(Icons.label_rounded,     'Prices',   () => _push(context, const PriceScreen())),
      _QuickAction(Icons.location_on_rounded,'Stations', () => _push(context, const StationsScreen())),
      _QuickAction(Icons.notifications_rounded,'Alerts', () => _push(context, const AlertsScreen())),
      _QuickAction(Icons.help_outline_rounded,'Help',   () => _push(context, const HelpScreen())),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: item.onTap,
            child: Container(
              margin: EdgeInsets.only(
                  right: item == items.last ? 0 : 10),
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 6),
              decoration: _T.card(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _T.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon,
                        color: _T.primary, size: 18),
                  ),
                  const SizedBox(height: 7),
                  Text(item.label,
                      style: _T.label.copyWith(
                          color: _T.textPrimary,
                          fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION HEADER
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _T.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: _T.h2),
        const Spacer(),
        Icon(icon, color: _T.textSecondary, size: 15),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  NEARBY CHAT TILE — LOGIC PRESERVED
  // ─────────────────────────────────────────────
  Widget _buildNearbyChatTile(BuildContext context) {
    return GestureDetector(
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
      child: Container(
        decoration: _T.card(),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_T.primary, _T.dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ask Nearby Drivers', style: _T.h2),
                  const SizedBox(height: 2),
                  Text('Real-time fuel availability in your area',
                      style: _T.body.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _T.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: _T.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FUEL PRICES — LOGIC PRESERVED
  // ─────────────────────────────────────────────
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

        final petrol92   = prices['petrol_92'];
        final diesel     = prices['auto_diesel'];
        final superDiesel = prices['super_diesel'];

        return Container(
          decoration: _T.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _PriceTile(
                    label: 'Petrol 92',
                    icon: Icons.local_gas_station_rounded,
                    price: petrol92 != null
                        ? 'Rs.${petrol92.toStringAsFixed(0)}'
                        : '—',
                    loading: petrol92 == null,
                  ),
                  _divider(),
                  _PriceTile(
                    label: 'Auto Diesel',
                    icon: Icons.local_gas_station_rounded,
                    price: diesel != null
                        ? 'Rs.${diesel.toStringAsFixed(0)}'
                        : '—',
                    loading: diesel == null,
                  ),
                  _divider(),
                  _PriceTile(
                    label: 'Super Diesel',
                    icon: Icons.local_gas_station_rounded,
                    price: superDiesel != null
                        ? 'Rs.${superDiesel.toStringAsFixed(0)}'
                        : '—',
                    loading: superDiesel == null,
                    highlighted: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: _T.border, height: 1),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _push(context, const PriceScreen()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View all fuel rates',
                      style: _T.body.copyWith(
                          color: _T.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: _T.primary),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        width: 1, height: 50,
        color: _T.border,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ─────────────────────────────────────────────
  //  NEARBY STATIONS — LOGIC PRESERVED
  // ─────────────────────────────────────────────
  Widget _buildNearbyStations(BuildContext context) {
    return Column(
      children: [
        _StationTile(
          name: 'Laugfs Station',
          subtitle: 'Petrol · Diesel',
          onTap: () => _push(context, const StationsScreen()),
        ),
        const SizedBox(height: 10),
        _StationTile(
          name: 'Ceypetco Station',
          subtitle: 'Petrol · Diesel · Super Diesel',
          onTap: () => _push(context, const StationsScreen()),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _push(context, const StationsScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: _T.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('See all stations',
                    style: _T.body.copyWith(
                        color: _T.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: _T.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SKELETON / LOADING
  // ─────────────────────────────────────────────
  Widget _buildSkeletonCard(double height) {
    return Container(
      height: height,
      decoration: _T.card(color: _T.muted),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: _T.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FAB — LOGIC PRESERVED
  // ─────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: _T.dark,
      elevation: 6,
      onPressed: () =>
          _push(context, const ChatbotScreen()),
      icon: const Icon(Icons.smart_toy_rounded,
          color: Colors.white, size: 18),
      label: const Text(
        'AI Assistant',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  DRAWER — LOGIC PRESERVED
  // ─────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final items = [
      _DrawerEntry(Icons.home_rounded,       'Home',        () => Navigator.pop(context)),
      _DrawerEntry(Icons.label_rounded,      'Fuel Prices', () { Navigator.pop(context); _push(context, const PriceScreen()); }),
      _DrawerEntry(Icons.location_on_rounded,'Stations',    () { Navigator.pop(context); _push(context, const StationsScreen()); }),
      _DrawerEntry(Icons.notifications_rounded,'Alerts',   () { Navigator.pop(context); _push(context, const AlertsScreen()); }),
      _DrawerEntry(Icons.people_rounded,     'Nearby Chat', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => AreaChatScreen(
          userLat: _userPosition?.latitude ?? 6.9271,
          userLng: _userPosition?.longitude ?? 79.8612,
          locationLabel: _locationLabel,
        )));
      }),
      _DrawerEntry(Icons.help_outline_rounded,'Help',       () { Navigator.pop(context); _push(context, const HelpScreen()); }),
      _DrawerEntry(Icons.settings_rounded,   'Settings',    () { Navigator.pop(context); _push(context, const SettingsScreen()); }),
    ];

    return Drawer(
      width: 270,
      backgroundColor: _T.accent,
      child: SafeArea(
        child: Column(
          children: [
            // Brand header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _T.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_gas_station_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PETROMIND', // Updated App Name
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Enterprise Platform',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          letterSpacing: 0.5,
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
                children: items.map((e) => _buildDrawerTile(e)).toList(),
              ),
            ),

            // Logout
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: ListTile(
                onTap: () async {
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
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: _T.primary, size: 18),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _T.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(_DrawerEntry entry) {
    return ListTile(
      onTap: entry.onTap,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(entry.icon, color: Colors.white70, size: 18),
      ),
      title: Text(
        entry.label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.white.withOpacity(0.25), size: 18),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.white.withOpacity(0.04),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  void _push(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _PriceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String price;
  final bool loading;
  final bool highlighted;

  const _PriceTile({
    required this.label,
    required this.icon,
    required this.price,
    this.loading = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: highlighted
                  ? _T.primary.withOpacity(0.12)
                  : _T.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: highlighted ? _T.primary : _T.textSecondary,
                size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: _T.label.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          loading
              ? SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _T.primary.withOpacity(0.4)))
              : Text(
                  price,
                  style: _T.price.copyWith(
                    fontSize: highlighted ? 17 : 15,
                    color: highlighted
                        ? _T.primary
                        : _T.dark,
                  ),
                ),
        ],
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _StationTile({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _T.card(),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _T.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: _T.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _T.h2.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: _T.body.copyWith(fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'OPEN',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: _T.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.onTap);
}

class _DrawerEntry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerEntry(this.icon, this.label, this.onTap);
}