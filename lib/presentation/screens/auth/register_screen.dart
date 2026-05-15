import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../home/home_screen.dart';
import '../station/station_dashboard_screen.dart';
import '../../../services/auth_service.dart';
import '../../../data/services/user_provider.dart';
import '../../../services/auto_crowd_service.dart';

class RegisterScreen extends StatefulWidget {
  final bool isStation;
  const RegisterScreen({super.key, this.isStation = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _stationNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _stationNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ================= REGISTER LOGIC =================
  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ── Validation ──
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty ||
        password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (widget.isStation &&
        (_stationNameController.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty)) {
      _showError('Please fill in station name and address.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (widget.isStation) {
        // ── Get location for station registration ──
        double lat = 0.0;
        double lng = 0.0;

        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        } catch (_) {
          // Location optional for station — continue without it
        }

        result = await AuthService.registerStation(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          stationName: _stationNameController.text.trim(),
          address: _addressController.text.trim(),
          latitude: lat,
          longitude: lng,
        );
      } else {
        result = await AuthService.registerCustomer(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // ── Navigate to appropriate home screen ──
        if (widget.isStation) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StationDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _showError(result['error'] ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_add_alt_1, color: Colors.white, size: 60),
                    SizedBox(height: 10),
                    Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Join PetroMind",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // FORM CARD
            Expanded(
              flex: 6,
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
                        widget.isStation ? "Station Account" : "User Account",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _input(_firstNameController, "First name"),
                      const SizedBox(height: 12),

                      _input(_lastNameController, "Last name"),
                      const SizedBox(height: 12),

                      if (widget.isStation) ...[
                        _input(_stationNameController, "Station name"),
                        const SizedBox(height: 12),
                        _input(_addressController, "Station address"),
                        const SizedBox(height: 12),
                      ],

                      _input(_emailController, "Email",
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),

                      _input(_passwordController, "Password",
                          isPassword: true, isConfirm: false),
                      const SizedBox(height: 12),

                      _input(_confirmPasswordController, "Confirm password",
                          isPassword: true, isConfirm: true),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          // ✅ FIX: was () {} — now calls _handleRegister
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B0000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Already have an account? Login",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
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

  // ================= INPUT WIDGET =================
  Widget _input(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final showText = isConfirm ? _showConfirmPassword : _showPassword;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !showText : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(showText
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(() {
                    if (isConfirm) {
                      _showConfirmPassword = !_showConfirmPassword;
                    } else {
                      _showPassword = !_showPassword;
                    }
                  }),
                )
              : null,
        ),
      ),
    );
  }
}