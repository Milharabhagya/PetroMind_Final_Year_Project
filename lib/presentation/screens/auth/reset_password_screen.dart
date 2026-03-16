import 'package:flutter/material.dart';
import 'password_changed_screen.dart';

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
                  Image.asset('assets/images/logo.png', height: 35,
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
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(
                  _newPasswordController,
                  'must be 8 characters',
                  _showNew,
                  () => setState(() => _showNew = !_showNew)),
              const SizedBox(height: 20),
              const Text('Confirm new password',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              _buildField(
                  _confirmPasswordController,
                  'repeat password',
                  _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PasswordChangedScreen(
                              isStation: widget.isStation)),
                      (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Reset password',
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
      bool obscure, VoidCallback onToggle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: !obscure,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
