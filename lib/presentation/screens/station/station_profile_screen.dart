import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StationProfileScreen extends StatefulWidget {
  const StationProfileScreen({super.key});

  @override
  State<StationProfileScreen> createState() =>
      _StationProfileScreenState();
}

class _StationProfileScreenState
    extends State<StationProfileScreen> {
  final _db = FirebaseFirestore.instance;

  // Store uid once at creation — avoids repeated null-checks
  final String _uid =
      FirebaseAuth.instance.currentUser?.uid ?? '';

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

  Future<void> _loadProfile() async {
    try {
      final stationDoc =
          await _db.collection('stations').doc(_uid).get();
      final data =
          stationDoc.data() as Map<String, dynamic>?;

      final authEmail =
          FirebaseAuth.instance.currentUser?.email ?? '';

      if (!mounted) return;
      setState(() {
        _stationNameController.text =
            data?['stationName'] as String? ??
                data?['name'] as String? ??
                '';
        _cityController.text =
            data?['city'] as String? ??
                data?['address'] as String? ??
                '';
        _brandController.text =
            data?['brand'] as String? ?? '';
        _emailController.text =
            data?['email'] as String? ?? authEmail;
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
      await _db
          .collection('stations')
          .doc(_uid)
          .update({
        'stationName':
            _stationNameController.text.trim(),
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
        const SnackBar(
          content: Text('✅ Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getAvatar(String brand, String stationName) {
    if (brand.isNotEmpty) {
      return brand
          .substring(
              0, brand.length > 3 ? 3 : brand.length)
          .toUpperCase();
    }
    if (stationName.isNotEmpty) {
      return stationName
          .split(' ')
          .take(2)
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .toUpperCase();
    }
    return '??';
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
      backgroundColor: const Color(0xFF8B0000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Station Profile',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white),
            )
          : _uid.isEmpty
              ? const Center(
                  child: Text(
                    'Not logged in',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ── LIVE AVATAR ──
                      StreamBuilder<DocumentSnapshot>(
                        stream: _db
                            .collection('stations')
                            .doc(_uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final data =
                              snapshot.data?.data()
                                  as Map<String,
                                      dynamic>?;
                          final brand =
                              data?['brand'] as String? ??
                                  _brandController.text;
                          final stationName =
                              data?['stationName']
                                  as String? ??
                              data?['name'] as String? ??
                              _stationNameController.text;
                          final avatar = _getAvatar(
                              brand, stationName);
                          final displayName =
                              brand.isNotEmpty
                                  ? brand
                                  : stationName;

                          return Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration:
                                    const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    avatar,
                                    style:
                                        const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // ── LIVE RATING ──
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('stations')
                            .doc(_uid)
                            .collection('ratings')
                            .snapshots(),
                        builder: (context, snapshot) {
                          double avg = 0;
                          int count = 0;
                          if (snapshot.hasData &&
                              snapshot.data!.docs
                                  .isNotEmpty) {
                            double total = 0;
                            count = snapshot
                                .data!.docs.length;
                            for (final doc
                                in snapshot.data!.docs) {
                              total += ((doc.data()
                                      as Map)['rating']
                                  as num?)
                                  ?.toDouble() ??
                                  0;
                            }
                            avg = total / count;
                          }

                          return Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              ...List.generate(5, (i) {
                                if (i < avg.floor()) {
                                  return const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20);
                                } else if (i < avg &&
                                    avg - avg.floor() >=
                                        0.5) {
                                  return const Icon(
                                      Icons.star_half,
                                      color: Colors.amber,
                                      size: 20);
                                } else {
                                  return const Icon(
                                      Icons.star_border,
                                      color: Colors.amber,
                                      size: 20);
                                }
                              }),
                              const SizedBox(width: 8),
                              Text(
                                count > 0
                                    ? '${avg.toStringAsFixed(1)} ($count reviews)'
                                    : 'No ratings yet',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── STATION NAME ──
                      _buildField(
                        controller:
                            _stationNameController,
                        showPencil: true,
                        hint: 'Station name',
                      ),
                      const SizedBox(height: 12),

                      // ── CITY ──
                      _buildField(
                        controller: _cityController,
                        hint: 'City',
                      ),
                      const SizedBox(height: 12),

                      // ── BRAND ──
                      _buildField(
                        controller: _brandController,
                        hint: 'Brand (e.g. IOC, CPC)',
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Enter your station name and brand',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── EMAIL ──
                      _buildField(
                        controller: _emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        hint: 'Email address',
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Enter your Email address',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── SAVE BUTTON ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : _saveProfile,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      30),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        Color(0xFF8B0000),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save edits',
                                  style: TextStyle(
                                    color:
                                        Color(0xFF8B0000),
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 16,
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
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool showPencil = false,
    String hint = '',
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6B0000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    child: Text(
                      controller.text.isNotEmpty
                          ? controller.text
                          : hint,
                      style: TextStyle(
                        color: controller.text.isNotEmpty
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
          if (showPencil)
            GestureDetector(
              onTap: () =>
                  setState(() => _isEditing = !_isEditing),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  color: _isEditing
                      ? Colors.greenAccent
                      : Colors.white54,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}