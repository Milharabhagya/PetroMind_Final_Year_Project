import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../home/home_screen.dart';
import '../station/station_dashboard_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_provider.dart';
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

  // ✅ Station-only fields
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

  // ✅ Get GPS location with permission handling
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Please enable GPS/location services.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied. Enable in settings.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showError('Could not get location: $e');
      return null;
    }
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // ✅ Extra validation for station fields
    if (widget.isStation) {
      if (_stationNameController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty) {
        _showError('Please fill in station name and address.');
        return;
      }
    }

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
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

    Map<String, dynamic> result;

    if (widget.isStation) {
      // ✅ Get GPS location before registering station
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      result = await AuthService.registerStation(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        stationName: _stationNameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
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

    if (result['success']) {
      final provider = Provider.of<UserProvider>(context, listen: false);

      if (widget.isStation) {
        await provider.loadStationData();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StationDashboardScreen()),
          (route) => false,
        );
      } else {
        await provider.loadUserData();
        if (!mounted) return;
        AutoCrowdService.autoLogCrowdOnLogin();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      _showError(result['error']);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B0000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 35,
                    errorBuilder: (c, e, s) => const Icon(
                        Icons.local_gas_station,
                        color: Colors.amber,
                        size: 35),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                widget.isStation ? 'Create Station Account' : 'Create Account',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              const Text('First name',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(_firstNameController, 'Enter your first name'),
              const SizedBox(height: 16),

              const Text('Last name',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(_lastNameController, 'Enter your last name'),
              const SizedBox(height: 16),

              // ✅ Station-only fields shown conditionally
              if (widget.isStation) ...[
                const Text('Station name',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                _buildField(_stationNameController, 'e.g. Ceypetco Homagama'),
                const SizedBox(height: 16),

                const Text('Station address',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                _buildField(_addressController, 'e.g. Homagama, Colombo'),
                const SizedBox(height: 8),

                // ✅ GPS notice for station owners
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your current GPS location will be saved to help customers find your station.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text('Email',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(_emailController, 'Enter your email address',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              const Text('Password',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildPasswordField(
                _passwordController,
                'Create new password',
                _showPassword,
                onToggle: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
              const SizedBox(height: 16),

              const Text('Confirm password',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildPasswordField(
                _confirmPasswordController,
                'Confirm password',
                _showConfirmPassword,
                onToggle: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller, String hint, bool obscure,
      {required VoidCallback onToggle}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54),
          onPressed: onToggle,
        ),
      ),
    );
  }
}