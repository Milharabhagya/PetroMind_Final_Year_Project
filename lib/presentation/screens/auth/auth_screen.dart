import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _logoTapCount = 0;
  DateTime? _firstTapTime;

  void _onLogoTap() {
    final now = DateTime.now();

    // Reset counter if more than 3 seconds have passed
    if (_firstTapTime != null &&
        now.difference(_firstTapTime!).inSeconds > 3) {
      _logoTapCount = 0;
      _firstTapTime = null;
    }

    if (_logoTapCount == 0) _firstTapTime = now;
    _logoTapCount++;

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _firstTapTime = null;
      // Navigate to admin login with fade transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              const AdminLoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B0000), Color(0xFFB30000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 28),
            child: Column(
              children: [
                const Spacer(),

                // ── LOGO + TITLE (tap 5x fast = admin) ──
                Column(
                  children: [
                    GestureDetector(
                      onTap: _onLogoTap,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        errorBuilder: (c, e, s) =>
                            GestureDetector(
                          onTap: _onLogoTap,
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Colors.amber,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PetroMind',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smart fuel management made simple',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ── GLASS CARD FOR BUTTONS ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(25),
                    border: Border.all(
                        color:
                            Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // ── LOGIN BUTTON ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const LoginScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── CREATE ACCOUNT BUTTON ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white
                                    .withOpacity(0.5)),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ── STATION OWNER SUBTLE LINK ──
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(
                          isStation: true),
                    ),
                  ),
                  child: Text(
                    'Station owner? Sign in here',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}