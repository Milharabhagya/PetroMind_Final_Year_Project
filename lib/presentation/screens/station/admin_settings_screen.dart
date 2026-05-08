// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Station Dashboard, Price Screen & Profile Screen

import 'package:flutter/material.dart';
import '../settings/change_password_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS (Shared across the app)
// ─────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFFAD2831);
  static const dark       = Color(0xFF38040E);
  static const accent     = Color(0xFF250902);
  static const bg         = Color(0xFFF8F4F1);
  static const surface    = Color(0xFFFFFFFF);
  static const muted      = Color(0xFFF2EBE7);
  static const textPrimary   = Color(0xFF1A0A0C);
  static const textSecondary = Color(0xFF7A5C60);
  static const border     = Color(0xFFEADDDA);

  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.6,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static BoxDecoration card({Color? color, bool hasBorder = true}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: border, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: dark.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─────────────────────────────────────────────
//  ADMIN SETTINGS SCREEN
// ─────────────────────────────────────────────
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _useFingerprint = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false, // Prevents burger menu
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Admin Settings', style: _T.h2.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account & Privacy', style: _T.h1.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Manage your station security and access preferences.',
              style: _T.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 32),

            // ── CHANGE PASSWORD TILE ──
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _T.card(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _T.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_person_rounded, color: _T.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Password', style: _T.h2.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Update your admin credentials', style: _T.label.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: _T.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── BIOMETRICS TILE ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: _T.card(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: _T.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Biometric Access', style: _T.h2.copyWith(fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Use fingerprint to unlock dashboard', style: _T.label.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useFingerprint,
                    onChanged: (val) => setState(() => _useFingerprint = val),
                    activeColor: Colors.white,
                    activeTrackColor: _T.primary,
                    inactiveThumbColor: _T.textSecondary,
                    inactiveTrackColor: _T.muted,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // ── SECURITY FOOTER ──
            Center(
              child: Column(
                children: [
                  Icon(Icons.verified_user_rounded, color: _T.textSecondary.withOpacity(0.2), size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Your station admin data is protected with\nindustry-standard AES encryption.',
                    textAlign: TextAlign.center,
                    style: _T.body.copyWith(fontSize: 11, color: _T.textSecondary.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}