import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B0000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ── LOGO ──
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                errorBuilder: (c, e, s) => Column(
                  children: const [
                    Icon(Icons.local_gas_station,
                        color: Colors.amber, size: 72),
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
              const SizedBox(height: 16),
              const Text(
                'Your fuel, your way.',
                style: TextStyle(
                    color: Colors.white60, fontSize: 14),
              ),

              const Spacer(),

              // ── SINGLE LOGIN BUTTON ──
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
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── SIGN UP BUTTON ──
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
                    side: const BorderSide(
                        color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Create account',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── STATION OWNER SUBTLE LINK ──
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(
                              isStation: true)),
                ),
                child: const Text(
                  'Station owner? Sign in here',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      decoration:
                          TextDecoration.underline,
                      decorationColor: Colors.white38),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}