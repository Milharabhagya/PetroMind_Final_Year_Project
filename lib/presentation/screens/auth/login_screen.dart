import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/home_screen.dart';
import '../station/station_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

import '../../../services/auth_service.dart';
import '../../../data/services/user_provider.dart';
import '../../../services/auto_crowd_service.dart';

class LoginScreen extends StatefulWidget {
  final bool isStation;
  const LoginScreen({super.key, this.isStation = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= LOGIN LOGIC (UNCHANGED) =================
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      setState(() => _errorMessage = 'Enter email & password');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Enter password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.isStation) {
      final result = await AuthService.loginStation(
          email: email, password: password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        final provider =
            Provider.of<UserProvider>(context, listen: false);
        await provider.loadStationData();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const StationDashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() => _errorMessage = result['error']);
      }
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: email, password: password);

      final uid = credential.user!.uid;

      final db = FirebaseFirestore.instance;

      final userDoc = await db.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final provider =
            Provider.of<UserProvider>(context, listen: false);
        await provider.loadUserData();

        AutoCrowdService.autoLogCrowdOnLogin();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        return;
      }

      final stationDoc =
          await db.collection('stations').doc(uid).get();

      if (stationDoc.exists) {
        final provider =
            Provider.of<UserProvider>(context, listen: false);
        await provider.loadStationData();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const StationDashboardScreen()),
          (route) => false,
        );
        return;
      }

      await FirebaseAuth.instance.signOut();

      setState(() {
        _isLoading = false;
        _errorMessage = "Account not found";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Login failed";
      });
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B0000), Color(0xFFB30000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // TOP SECTION
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.local_gas_station,
                        color: Colors.white, size: 70),
                    SizedBox(height: 10),
                    Text(
                      "PetroMind",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM CARD
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isStation
                            ? "Station Login"
                            : "Welcome Back",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _field(
                          controller: _emailController,
                          hint: "Email",
                          icon: Icons.email),

                      const SizedBox(height: 12),

                      _field(
                        controller: _passwordController,
                        hint: "Password",
                        icon: Icons.lock,
                        isPassword: true,
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        )
                      ],

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6B0000),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                      color: Colors.white),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ForgotPasswordScreen()),
                            ),
                            child:
                                const Text("Forgot Password"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      RegisterScreen()),
                            ),
                            child: const Text("Sign Up"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText:
            isPassword ? !_showPassword : false,
        decoration: InputDecoration(
          icon: Icon(icon),
          hintText: hint,
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_showPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(
                      () => _showPassword = !_showPassword),
                )
              : null,
        ),
      ),
    );
  }
}