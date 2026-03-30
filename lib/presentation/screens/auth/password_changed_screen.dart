import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (newPass.length < 8) {
      _showError('New password must be at least 8 characters.');
      return;
    }
    if (newPass != confirm) {
      _showError('New passwords do not match.');
      return;
    }
    if (current == newPass) {
      _showError('New password must be different from current password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showError('No logged in user found.');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Re-authenticate with current password first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);

      // ✅ Now update the password
      await user.updatePassword(newPass);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showError('Current password is incorrect.');
      } else if (e.code == 'requires-recent-login') {
        _showError('Please log out and log back in before changing your password.');
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
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // ✅ Prevents drawer icon from appearing
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your current password and choose a new one.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),

            const Text('Enter your password',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildField(_currentPasswordController,
                'Current password', _showCurrent,
                () => setState(() => _showCurrent = !_showCurrent)),

            const SizedBox(height: 16),
            const Text('Create a new password',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildField(_newPasswordController,
                'Must be 8 characters', _showNew,
                () => setState(() => _showNew = !_showNew)),

            const SizedBox(height: 16),
            const Text('Confirm password',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildField(_confirmPasswordController,
                'Repeat new password', _showConfirm,
                () => setState(() => _showConfirm = !_showConfirm)),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Change password',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      bool visible, VoidCallback onToggle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
                visible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}