import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:petromind/data/services/user_provider.dart';
import 'package:petromind/data/services/road_alert_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/fuel_price_provider.dart';
import 'presentation/providers/station_provider.dart';
import 'presentation/providers/alert_provider.dart';
import 'presentation/providers/complaint_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/station/station_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: true,
    );
  }

  if (!kIsWeb) {
    await RoadAlertService().init();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => FuelPriceProvider()),
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      // ✅ builder gives a new context INSIDE MultiProvider
      // so every route pushed via navigatorKey inherits providers
      builder: (context, child) {
        return MaterialApp(
          title: 'PetroMind',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF8B0000)),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const OnboardingScreen()));
      return;
    }

    try {
      final db = FirebaseFirestore.instance;

      final userDoc =
          await db.collection('users').doc(user.uid).get();

      if (userDoc.exists &&
          userDoc.data()?['role'] == 'customer') {
        if (!mounted) return;
        final provider =
            Provider.of<UserProvider>(context, listen: false);
        await provider.loadUserData();
        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const HomeScreen()));
        return;
      }

      final stationDoc =
          await db.collection('stations').doc(user.uid).get();

      if (stationDoc.exists &&
          stationDoc.data()?['role'] == 'station') {
        if (!mounted) return;
        final provider =
            Provider.of<UserProvider>(context, listen: false);
        await provider.loadStationData();
        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const StationDashboardScreen()));
        return;
      }
    } catch (e) {
      print('Firestore auth check error: $e');
    }

    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B0000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 120,
              errorBuilder: (c, e, s) => Column(
                children: const [
                  Icon(Icons.local_gas_station,
                      color: Colors.amber, size: 80),
                  SizedBox(height: 12),
                  Text(
                    'PetroMind',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
                color: Colors.white),
          ],
        ),
      ),
    );
  }
}