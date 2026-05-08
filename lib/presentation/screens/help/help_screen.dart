// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches HomeScreen, PriceScreen, AlertsScreen & ProfileScreen Design System

import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'complaint_screen.dart';
import 'rate_us_screen.dart';
import 'chatbot_screen.dart'; // ✅ Petra uses your existing chatbot screen

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
//  HELP SCREEN
// ─────────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Support Center', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          children: [
            // ✅ Premium Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [_T.primary, _T.dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we\nhelp you?',
                          style: _T.h1.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose an option below to get started',
                          style: _T.body.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Help Items
            _helpItem(
              context,
              Icons.smart_toy_rounded,
              'Get Support with Petra',
              'Get in touch with our AI chatbot instantly',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
              isPrimary: true,
            ),
            _helpItem(
              context,
              Icons.help_outline_rounded,
              'FAQ',
              'Find answers to frequently asked questions',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            _helpItem(
              context,
              Icons.feedback_rounded,
              'Raise a Complaint',
              'Report an issue or share detailed feedback',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen())),
            ),
            _helpItem(
              context,
              Icons.star_rounded,
              'Rate Us',
              'Share your experience and rate the app',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RateUsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE HELP ITEM WIDGET ──
  Widget _helpItem(
    BuildContext context, 
    IconData icon, 
    String title, 
    String subtitle, 
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _T.card(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? _T.primary.withOpacity(0.12) : _T.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: isPrimary ? _T.primary : _T.textSecondary, 
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _T.h2.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _T.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _T.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}