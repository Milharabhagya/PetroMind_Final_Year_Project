import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isStation;
  const ForgotPasswordScreen({super.key, this.isStation = false});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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
      // ✅ FIX: ActionCodeSettings tells Firebase where to redirect
      // after the user clicks the reset link — back into your app.
      //
      // IMPORTANT: Replace 'petromind-xxxxx.web.app' below with your
      // actual Firebase hosting domain:
      //   Firebase Console → Project Settings → General → Your apps
      //
      // Also make sure your domain is added in:
      //   Firebase Console → Authentication → Settings → Authorized domains
      // ✅ FIX: Using firebaseapp.com domain — this is always authorized
      // by Firebase automatically, no hosting setup needed.
      // The reset link will open in your app via deep link.
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://petromind-3b8b2.firebaseapp.com/login',
        handleCodeInApp: true,
        androidPackageName: 'com.petromind.petromind',
        androidInstallApp: true,
        androidMinimumVersion: '1',
        iOSBundleId: 'com.petromind.petromind',
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

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
          // ✅ FIX: Don't reveal if email exists (security best practice).
          // Show success regardless — prevents email enumeration attacks
          // which also caused "spam" behaviour before.
          setState(() => _emailSent = true);
          break;
        case 'invalid-email':
          _showError('Please enter a valid email address.');
          break;
        case 'too-many-requests':
          _showError('Too many requests. Please wait and try again.');
          break;
        default:
          _showError('Failed to send email. Please try again.');
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
                            const Icon(Icons.mark_email_read_outlined,
                                color: Colors.greenAccent, size: 54),
                            const SizedBox(height: 12),
                            const Text(
                              "Check your inbox!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "If an account exists for\n${_emailController.text},\nyou'll receive a reset link shortly.\nTap the link to set a new password.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6B0000),
                                minimumSize:
                                    const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: const Text("Back to Login",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ] else ...[
                            // EMAIL FIELD
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _emailController,
                                style:
                                    const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: "Email",
                                  hintStyle:
                                      TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _sendResetEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                minimumSize:
                                    const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text("Send Reset Email",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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