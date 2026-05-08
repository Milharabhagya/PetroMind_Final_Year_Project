// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Station Dashboard, Admin Price Screen & Stock Management

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
//  STATION PROFILE SCREEN
// ─────────────────────────────────────────────
class StationProfileScreen extends StatefulWidget {
  const StationProfileScreen({super.key});

  @override
  State<StationProfileScreen> createState() => _StationProfileScreenState();
}

class _StationProfileScreenState extends State<StationProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final _stationNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _brandController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_uid.isNotEmpty) {
      _loadProfile();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── LOGIC PRESERVED ──
  Future<void> _loadProfile() async {
    try {
      final stationDoc = await _db.collection('stations').doc(_uid).get();
      final data = stationDoc.data() as Map<String, dynamic>?;
      final authEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      if (!mounted) return;
      setState(() {
        _stationNameController.text = data?['stationName'] as String? ?? data?['name'] as String? ?? '';
        _cityController.text = data?['city'] as String? ?? data?['address'] as String? ?? '';
        _brandController.text = data?['brand'] as String? ?? '';
        _emailController.text = data?['email'] as String? ?? authEmail;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('_loadProfile error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_uid.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _db.collection('stations').doc(_uid).update({
        'stationName': _stationNameController.text.trim(),
        'city': _cityController.text.trim(),
        'brand': _brandController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Profile updated successfully!', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: _T.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getAvatar(String brand, String stationName) {
    if (brand.isNotEmpty) {
      return brand.substring(0, brand.length > 3 ? 3 : brand.length).toUpperCase();
    }
    if (stationName.isNotEmpty) {
      return stationName.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    }
    return 'PM';
  }

  @override
  void dispose() {
    _stationNameController.dispose();
    _cityController.dispose();
    _brandController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Station Profile', style: _T.h2.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: _T.primary),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3))
          : _uid.isEmpty
              ? Center(child: Text('Not logged in', style: _T.body))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── STATION HEADER ──
                      StreamBuilder<DocumentSnapshot>(
                        stream: _db.collection('stations').doc(_uid).snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          final brand = data?['brand'] as String? ?? _brandController.text;
                          final stationName = data?['stationName'] as String? ?? data?['name'] as String? ?? _stationNameController.text;
                          final avatar = _getAvatar(brand, stationName);

                          return Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_T.primary, _T.dark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _T.primary.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: Center(
                                  child: Text(
                                    avatar,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(brand.isNotEmpty ? brand : stationName, style: _T.h1),
                              Text('Enterprise Partner', style: _T.label.copyWith(letterSpacing: 1.5, color: _T.primary)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── RATINGS OVERVIEW CARD ──
                      StreamBuilder<QuerySnapshot>(
                        stream: _db.collection('stations').doc(_uid).collection('ratings').snapshots(),
                        builder: (context, snapshot) {
                          double avg = 0;
                          int count = 0;
                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                            double total = 0;
                            count = snapshot.data!.docs.length;
                            for (final doc in snapshot.data!.docs) {
                              total += ((doc.data() as Map)['rating'] as num?)?.toDouble() ?? 0;
                            }
                            avg = total / count;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: _T.card(),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('STATION RATING', style: _T.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(avg.toStringAsFixed(1), style: _T.h1.copyWith(fontSize: 28)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(width: 1, height: 40, color: _T.border),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('TOTAL REVIEWS', style: _T.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('$count', style: _T.h1.copyWith(fontSize: 28, color: _T.primary)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── PROFILE FIELDS ──
                      _buildField(
                        label: 'STATION NAME',
                        controller: _stationNameController,
                        hint: 'e.g. Ceypetco - Colombo 07',
                        icon: Icons.store_rounded,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'CITY / AREA',
                              controller: _cityController,
                              hint: 'City',
                              icon: Icons.location_city_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'BRAND',
                              controller: _brandController,
                              hint: 'Brand',
                              icon: Icons.branding_watermark_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildField(
                        label: 'CONTACT EMAIL',
                        controller: _emailController,
                        hint: 'Email address',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 40),

                      // ── SAVE BUTTON ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isSaving || !_isEditing) ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _T.primary,
                            disabledBackgroundColor: _T.muted,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isEditing ? 'Save Changes' : 'Select Edit to Update',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _T.label.copyWith(fontWeight: FontWeight.bold, color: _isEditing ? _T.primary : _T.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? _T.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isEditing ? _T.primary.withOpacity(0.3) : _T.border),
            boxShadow: _isEditing ? [
              BoxShadow(color: _T.dark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
            ] : null,
          ),
          child: TextField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            style: _T.h2.copyWith(fontSize: 14, color: _isEditing ? _T.textPrimary : _T.textSecondary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.4)),
              prefixIcon: Icon(icon, size: 18, color: _isEditing ? _T.primary : _T.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}