// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches HomeScreen, PriceScreen, AlertsScreen, ProfileScreen & Chat Screens

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

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
//  COMPLAINT SCREEN
// ─────────────────────────────────────────────
class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // Selected station state
  String _selectedStationName = 'Select a nearby station';
  String _selectedStationId = '';
  bool _loadingStations = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── LOGIC PRESERVED ──
  // ✅ Get GPS location then fetch nearby stations from Firestore
  Future<void> _showNearbyStations() async {
    setState(() => _loadingStations = true);

    Position? position;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable GPS.');
        setState(() => _loadingStations = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          setState(() => _loadingStations = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied. Enable it in settings.');
        setState(() => _loadingStations = false);
        return;
      }

      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showError('Could not get your location: $e');
      setState(() => _loadingStations = false);
      return;
    }

    // Fetch all stations from Firestore
    List<Map<String, dynamic>> nearbyStations = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stations')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Only include stations that have lat/lng stored
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        if (lat == null || lng == null) continue;

        final distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lng,
        );

        // Show stations within 10km
        if (distanceInMeters <= 10000) {
          nearbyStations.add({
            'id': doc.id,
            'name': data['stationName'] ?? 'Unknown Station',
            'address': data['address'] ?? '',
            'distance': (distanceInMeters / 1000).toStringAsFixed(1),
          });
        }
      }

      // Sort by distance
      nearbyStations.sort((a, b) =>
          double.parse(a['distance']).compareTo(double.parse(b['distance'])));
    } catch (e) {
      _showError('Failed to load stations: $e');
      setState(() => _loadingStations = false);
      return;
    }

    setState(() => _loadingStations = false);

    if (!mounted) return;

    // Show modern bottom sheet with nearby stations
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Nearby Stations', style: _T.h1.copyWith(fontSize: 18)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Stations within 10km of your location', style: _T.body.copyWith(fontSize: 12)),
              ),
              const SizedBox(height: 12),
              Divider(color: _T.border, height: 1),
              
              if (nearbyStations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.location_off_rounded, color: _T.textSecondary, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No stations found nearby.\nTry expanding your search area.',
                          textAlign: TextAlign.center,
                          style: _T.body,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: nearbyStations.length,
                    separatorBuilder: (_, __) => Divider(color: _T.border, height: 1, indent: 24, endIndent: 24),
                    itemBuilder: (context, index) {
                      final station = nearbyStations[index];
                      final isSelected = station['id'] == _selectedStationId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? _T.primary.withOpacity(0.12) : _T.muted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_gas_station_rounded,
                            color: isSelected ? _T.primary : _T.textSecondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          station['name'],
                          style: _T.h2.copyWith(
                            fontSize: 14,
                            color: isSelected ? _T.primary : _T.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${station['address']} • ${station['distance']} km away',
                          style: _T.label.copyWith(fontSize: 10),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: _T.primary, size: 22)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedStationId = station['id'];
                            _selectedStationName = station['name'];
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _T.body.copyWith(color: Colors.white)), 
        backgroundColor: _T.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (_selectedStationId.isEmpty) {
      _showError('Please select a station first.');
      return;
    }
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showError('Please fill in both Subject and Description.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'unknown',
        'stationId': _selectedStationId,
        'station': _selectedStationName,
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint submitted successfully!', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
        title: Text('Raise a Complaint', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complaint Details', style: _T.h1.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text('Report an issue to the PetroMind team', style: _T.body.copyWith(fontSize: 12)),
            const SizedBox(height: 24),

            // ── STATION SELECTOR ──
            Text('STATION', style: _T.label.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
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
                    child: const Icon(Icons.location_on_rounded, color: _T.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedStationName,
                          style: _T.h2.copyWith(
                            fontSize: 14,
                            color: _selectedStationId.isEmpty ? _T.textSecondary : _T.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loadingStations ? null : _showNearbyStations,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _T.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _loadingStations
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2),
                            )
                          : Text('Change', style: _T.label.copyWith(color: _T.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── SUBJECT FIELD ──
            _editableField(
              _subjectController,
              'SUBJECT',
              'Briefly describe the issue...',
            ),
            const SizedBox(height: 20),

            // ── DESCRIPTION FIELD ──
            _editableField(
              _descriptionController,
              'DESCRIPTION',
              'Explain the issue in detail...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // ── PHOTO UPLOAD (Optional) ──
            Text('ATTACHMENTS (OPTIONAL)', style: _T.label.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
                boxShadow: [
                  BoxShadow(
                    color: _T.dark.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _T.muted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: _T.textSecondary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text('Upload photo', style: _T.h2.copyWith(fontSize: 13, color: _T.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── SUBMIT BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitComplaint,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Complaint',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  disabledBackgroundColor: _T.muted,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE TEXT FIELD WIDGET ──
  Widget _editableField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _T.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.border),
            boxShadow: [
              BoxShadow(
                color: _T.dark.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: _T.body.copyWith(color: _T.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}