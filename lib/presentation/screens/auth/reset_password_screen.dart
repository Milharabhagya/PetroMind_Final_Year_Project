import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  final bool isStation;
  const ResetPasswordScreen({super.key, this.isStation = false});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in both fields.');
      return;
    }
    if (newPassword.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('No logged in user found. Please log in again.');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Actually updates password in Firebase Auth
      await user.updatePassword(newPassword);

      if (!mounted) return;

      // ✅ Show success screen inline instead of importing PasswordChangedScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => _PasswordSuccessScreen(
              isStation: widget.isStation),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showError(
            'For security, please log out and log back in before changing your password.');
      } else {
        _showError('Failed to change password: ${e.message}');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B0000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  Image.asset('assets/images/logo.png',
                      height: 35,
                      errorBuilder: (c, e, s) => const Icon(
                          Icons.local_gas_station,
                          color: Colors.amber,
                          size: 35)),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Reset password',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Please type something you'll remember",
                  style: TextStyle(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 40),
              const Text('New password',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(
                  _newPasswordController,
                  'Must be 8 characters',
                  _showNew,
                  () => setState(() => _showNew = !_showNew)),
              const SizedBox(height: 20),
              const Text('Confirm new password',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(
                  _confirmPasswordController,
                  'Repeat password',
                  _showConfirm,
                  () => setState(
                      () => _showConfirm = !_showConfirm)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Text('Reset password',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String hint,
      bool visible,
      VoidCallback onToggle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
                visible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.black54),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

// ✅ Success screen built into the same file — no import needed
class _PasswordSuccessScreen extends StatelessWidget {
  final bool isStation;
  const _PasswordSuccessScreen({this.isStation = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B0000),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png',
                    height: 80,
                    errorBuilder: (c, e, s) => const Icon(
                        Icons.local_gas_station,
                        color: Colors.amber,
                        size: 60)),
                const SizedBox(height: 48),
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 64),
                const SizedBox(height: 24),
                const Text('Password changed',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                    'Your password has been changed\nsuccessfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (route) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30)),
                    ),
                    child: const Text('Back to login',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}