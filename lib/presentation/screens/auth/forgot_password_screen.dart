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
          _showError(
              'No account found with this email address.');
          break;
        case 'invalid-email':
          _showError(
              'Please enter a valid email address.');
          break;
        case 'too-many-requests':
          _showError(
              'Too many attempts. Please try again later.');
          break;
        default:
          _showError(
              'Failed to send reset email. Please try again.');
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
        backgroundColor: Colors.red[700],
      ),
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
              // ── TOP BAR ──
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16),
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
              const SizedBox(height: 40),

              const Text('Forgot password?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                  "Don't worry! Please enter the email associated with your account.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14)),
              const SizedBox(height: 32),

              // ✅ Success state
              if (_emailSent) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            Colors.green.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Reset email sent!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a password reset link to:\n${_emailController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Spam warning
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber
                              .withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.amber
                                  .withOpacity(0.5)),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.amber,
                                size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The email may land in your Spam or Junk folder. Please check there and mark it as "Not spam".',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(
                            () => _emailSent = false),
                        child: const Text(
                          'Didn\'t receive it? Send again',
                          style: TextStyle(
                              color: Colors.white,
                              decoration:
                                  TextDecoration.underline,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30)),
                    ),
                    child: const Text('Back to Login',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold)),
                  ),
                ),

              ] else ...[
                // ✅ Email input state
                const Text('Email address',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    style: const TextStyle(
                        color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText:
                          'Enter your email address',
                      hintStyle: TextStyle(
                          color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
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
                            child:
                                CircularProgressIndicator(
                                    strokeWidth: 2),
                          )
                        : const Text(
                            'Send reset email',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                  ),
                ),
              ],

              const Spacer(),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Remember password? ',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}