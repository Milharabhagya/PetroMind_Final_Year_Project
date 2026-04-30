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
  // isStation = true only when coming from the hidden
  // "Station owner? Sign in here" link
  final bool isStation;
  const LoginScreen({super.key, this.isStation = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _emailValid = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ── Validation ──
    if (email.isEmpty && password.isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter your email and password.');
      return;
    }
    if (email.isEmpty) {
      setState(
          () => _errorMessage = 'Please enter your email.');
      return;
    }
    if (password.isEmpty) {
      setState(
          () => _errorMessage = 'Please enter your password.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage =
          'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage =
          'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ── If station owner link used, go direct ──
    if (widget.isStation) {
      final result = await AuthService.loginStation(
          email: email, password: password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success']) {
        final provider =
            Provider.of<UserProvider>(context, listen: false);
        await provider.loadStationData();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const StationDashboardScreen()),
            (route) => false);
      } else {
        setState(() => _errorMessage = result['error']);
      }
      return;
    }

    // ── Auto role detection for normal login ──
    try {
      // Step 1: Firebase Auth sign in
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: email, password: password);
      if (!mounted) return;

      final uid = credential.user?.uid ?? '';
      if (uid.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed. Please try again.';
        });
        return;
      }

      final db = FirebaseFirestore.instance;

      // Step 2: Check users collection (customer)
      final userDoc =
          await db.collection('users').doc(uid).get();
      if (!mounted) return;

      if (userDoc.exists) {
        final role =
            userDoc.data()?['role'] as String? ?? '';
        if (role == 'customer' || role.isEmpty) {
          final provider = Provider.of<UserProvider>(
              context,
              listen: false);
          await provider.loadUserData();
          if (!mounted) return;
          AutoCrowdService.autoLogCrowdOnLogin();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomeScreen()),
              (route) => false);
          return;
        }
      }

      // Step 3: Check stations collection (station owner)
      final stationDoc =
          await db.collection('stations').doc(uid).get();
      if (!mounted) return;

      if (stationDoc.exists) {
        final role =
            stationDoc.data()?['role'] as String? ?? '';
        if (role == 'station' || role.isEmpty) {
          final provider = Provider.of<UserProvider>(
              context,
              listen: false);
          await provider.loadStationData();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const StationDashboardScreen()),
              (route) => false);
          return;
        }
      }

      // Step 4: Check admin collection
      final adminDoc =
          await db.collection('admins').doc(uid).get();
      if (!mounted) return;

      if (adminDoc.exists) {
        // Navigate to admin dashboard if you have one
        // For now redirect to station dashboard
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const StationDashboardScreen()),
            (route) => false);
        return;
      }

      // Step 5: No role found
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Account not found. Please register first.';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Try again.';
      });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B0000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP BAR ──
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16),
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 38,
                    errorBuilder: (c, e, s) => Row(
                      children: const [
                        Icon(Icons.local_gas_station,
                            color: Colors.amber, size: 28),
                        SizedBox(width: 6),
                        Text('PetroMind',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── TITLE ──
              Text(
                widget.isStation
                    ? 'Station Owner Login'
                    : 'Welcome back',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isStation
                    ? 'Sign in to manage your station'
                    : 'Sign in to your account',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // ── EMAIL ──
              const Text('Email address',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius:
                        BorderRadius.circular(10)),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 15),
                  onChanged: (val) => setState(() {
                    _emailValid = val.contains('@') &&
                        val.split('@').length == 2 &&
                        val.split('@')[1].isNotEmpty;
                    _errorMessage = null;
                  }),
                  decoration: InputDecoration(
                    hintText: 'helloworld@gmail.com',
                    hintStyle: const TextStyle(
                        color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                    suffixIcon: _emailValid
                        ? Container(
                            margin:
                                const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                color: Colors.white,
                                size: 16))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── PASSWORD ──
              const Text('Password',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius:
                        BorderRadius.circular(10)),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 15),
                  onChanged: (_) =>
                      setState(() => _errorMessage = null),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(
                        color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black54,
                          size: 22),
                      onPressed: () => setState(() =>
                          _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── ERROR MESSAGE ──
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              Colors.red.withOpacity(0.5))),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13)),
                    ),
                  ]),
                ),

              // ── FORGOT PASSWORD ──
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ForgotPasswordScreen(
                                  isStation:
                                      widget.isStation))),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8),
                    child: Text('Forgot password?',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── LOGIN BUTTON ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B0000)))
                      : const Text('Log in',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                ),
              ),
              const SizedBox(height: 60),

              // ── SIGN UP ──
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RegisterScreen(
                              isStation:
                                  widget.isStation))),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}