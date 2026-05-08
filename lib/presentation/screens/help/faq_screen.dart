// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches HomeScreen, PriceScreen, AlertsScreen, ProfileScreen & Chat Screens

import 'package:flutter/material.dart';

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
//  FAQ SCREEN
// ─────────────────────────────────────────────
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  // ── LOGIC PRESERVED ──
  final List<Map<String, String>> faqs = const [
    {
      'question': 'How do I set up a price alert?',
      'answer':
          'Go to the Alerts tab, tap "Add Alert", select your fuel type and target price, then tap Save. You will be notified when the price drops to your target.',
    },
    {
      'question': 'How do I reset my password?',
      'answer':
          'On the login screen, tap "Forgot Password", enter your registered email address, and follow the instructions sent to your inbox.',
    },
    {
      'question': 'Can I use the app without registering?',
      'answer':
          'Some features like viewing fuel prices are available without an account. However, alerts, complaints, and personalised features require registration.',
    },
    {
      'question': 'How do I find the nearest fuel station?',
      'answer':
          'Open the Map tab and allow location access. Nearby stations will be shown with real-time fuel prices and availability.',
    },
    {
      'question': 'How do I raise a complaint?',
      'answer':
          'Go to Help > Raise a Complaint, select a station, fill in the subject and description, and tap Submit Complaint.',
    },
  ];

  // Track which index is expanded (-1 = none)
  int _expandedIndex = -1;

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
        title: Text('FAQ', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER SECTION ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _T.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: _T.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Frequently Asked', style: _T.h1.copyWith(fontSize: 20, height: 1.2)),
                          Text('Questions (FAQ)', style: _T.h1.copyWith(fontSize: 20, color: _T.primary, height: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Find quick answers to common questions about PetroMind.',
                  style: _T.body.copyWith(fontSize: 13, color: _T.textSecondary),
                ),
              ],
            ),
          ),
          
          // ── FAQ LIST ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              physics: const BouncingScrollPhysics(),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final isExpanded = _expandedIndex == index;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded ? _T.primary.withOpacity(0.3) : _T.border,
                      width: isExpanded ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _T.dark.withOpacity(isExpanded ? 0.08 : 0.03),
                        blurRadius: isExpanded ? 16 : 8,
                        offset: Offset(0, isExpanded ? 6 : 2),
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        // Tap same item to collapse, else expand new one
                        _expandedIndex = isExpanded ? -1 : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faqs[index]['question']!,
                                  style: _T.h2.copyWith(
                                    fontSize: 14, 
                                    color: isExpanded ? _T.primary : _T.textPrimary
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isExpanded ? _T.primary.withOpacity(0.1) : _T.muted,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: isExpanded ? _T.primary : _T.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          
                          // ── EXPANDED ANSWER SECTION ──
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: isExpanded
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(color: _T.border, height: 1),
                                      ),
                                      Text(
                                        faqs[index]['answer']!,
                                        style: _T.body.copyWith(
                                          color: _T.textSecondary,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}