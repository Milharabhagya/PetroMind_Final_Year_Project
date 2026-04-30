import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isStation;
  const ForgotPasswordScreen(
      {super.key, this.isStation = false});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (e.code) {
        case 'user-not-found':
          _showError('No account found.');
          break;
        default:
          _showError('Failed to send email.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Something went wrong.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // TITLE
                const Text(
                  "PetroMind",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // CARD
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Forgot Password",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Enter your email to reset password",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 20),

                          if (_emailSent) ...[
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 50),
                            const SizedBox(height: 10),
                            Text(
                              "Email sent to\n${_emailController.text}",
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text("Back to Login"),
                            ),
                          ] else ...[
                            // EMAIL FIELD
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _emailController,
                                style: const TextStyle(
                                    color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Email",
                                  hintStyle: TextStyle(
                                      color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _sendResetEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(
                                    double.infinity, 50),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                      "Send Reset Email"),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // BACK LINK
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Back to login",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}