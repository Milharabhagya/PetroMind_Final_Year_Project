// ✅ FIXED — Photo upload + Station complaint visibility
// Design: Minimalist Industrial SaaS · Poppins

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _T {
  static const primary       = Color(0xFFAD2831);
  static const dark          = Color(0xFF38040E);
  static const bg            = Color(0xFFF8F4F1);
  static const surface       = Color(0xFFFFFFFF);
  static const muted         = Color(0xFFF2EBE7);
  static const textPrimary   = Color(0xFF1A0A0C);
  static const textSecondary = Color(0xFF7A5C60);
  static const border        = Color(0xFFEADDDA);

  static const h1 = TextStyle(
    fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.4,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: -0.2,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500,
    color: textSecondary, letterSpacing: 0.6,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400,
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
  final _subjectController     = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting   = false;
  bool _isUploadingPhoto = false;

  // Station selection
  String _selectedStationName = 'Select a nearby station';
  String _selectedStationId   = '';
  bool   _loadingStations     = false;

  // ✅ Photo state
  File?   _pickedImage;
  String? _uploadedPhotoUrl;
  double  _uploadProgress = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── PHOTO PICKER ────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,   // compress to reduce upload size
        maxWidth: 1280,
      );
      if (picked == null) return;

      setState(() {
        _pickedImage      = File(picked.path);
        _uploadedPhotoUrl = null; // reset previous upload
      });
    } catch (e) {
      _showError('Could not open camera/gallery: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _T.border, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Add Photo', style: _T.h2),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _T.muted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _T.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: _T.label.copyWith(color: _T.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ─── FIREBASE STORAGE UPLOAD ──────────────────────────────────────────────
  // ✅ Uploads the picked image and returns the download URL
  Future<String?> _uploadPhoto() async {
    if (_pickedImage == null) return null;

    setState(() {
      _isUploadingPhoto = true;
      _uploadProgress   = 0;
    });

    try {
      final user      = FirebaseAuth.instance.currentUser;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uid       = user?.uid ?? 'anon';

      // Storage path: complaints/{userId}/{timestamp}.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('complaints')
          .child(uid)
          .child('$timestamp.jpg');

      final uploadTask = ref.putFile(
        _pickedImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Track upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _uploadedPhotoUrl = downloadUrl;
          _isUploadingPhoto = false;
        });
      }

      return downloadUrl;
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showError('Photo upload failed: $e');
      }
      return null;
    }
  }

  // ─── NEARBY STATION PICKER ────────────────────────────────────────────────
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
      _showError('Could not get your location.');
      setState(() => _loadingStations = false);
      return;
    }

    List<Map<String, dynamic>> nearbyStations = [];
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('stations').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat  = (data['latitude']  as num?)?.toDouble();
        final lng  = (data['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final distanceM = Geolocator.distanceBetween(
          position.latitude, position.longitude, lat, lng,
        );

        if (distanceM <= 10000) {
          nearbyStations.add({
            'id':       doc.id,
            'name':     data['stationName'] ?? 'Unknown Station',
            'address':  data['address']     ?? '',
            'distance': (distanceM / 1000).toStringAsFixed(1),
          });
        }
      }

      nearbyStations.sort((a, b) =>
          double.parse(a['distance']).compareTo(double.parse(b['distance'])));
    } catch (e) {
      _showError('Failed to load stations.');
      setState(() => _loadingStations = false);
      return;
    }

    setState(() => _loadingStations = false);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Nearby Stations',
                  style: _T.h1.copyWith(fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Stations within 10 km of your location',
                  style: _T.body.copyWith(fontSize: 12)),
            ),
            const SizedBox(height: 12),
            Divider(color: _T.border, height: 1),
            if (nearbyStations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 40, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.location_off_rounded,
                          color: _T.textSecondary, size: 40),
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
                    maxHeight:
                        MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: nearbyStations.length,
                  separatorBuilder: (_, __) => Divider(
                      color: _T.border,
                      height: 1,
                      indent: 24,
                      endIndent: 24),
                  itemBuilder: (context, i) {
                    final st         = nearbyStations[i];
                    final isSelected = st['id'] == _selectedStationId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _T.primary.withOpacity(0.12)
                              : _T.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_gas_station_rounded,
                            color: isSelected
                                ? _T.primary
                                : _T.textSecondary,
                            size: 20),
                      ),
                      title: Text(st['name'],
                          style: _T.h2.copyWith(
                              fontSize: 14,
                              color: isSelected
                                  ? _T.primary
                                  : _T.textPrimary)),
                      subtitle: Text(
                          '${st['address']} • ${st['distance']} km away',
                          style: _T.label.copyWith(fontSize: 10)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: _T.primary, size: 22)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedStationId   = st['id'];
                          _selectedStationName = st['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ─── SUBMIT ───────────────────────────────────────────────────────────────
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
      // ✅ Upload photo first if one was picked
      String? photoUrl;
      if (_pickedImage != null && _uploadedPhotoUrl == null) {
        photoUrl = await _uploadPhoto();
        // If upload failed, ask user if they want to continue without it
        if (photoUrl == null && mounted) {
          final continueAnyway = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Photo upload failed'),
              content: const Text(
                  'Would you like to submit the complaint without the photo?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Submit anyway')),
              ],
            ),
          );
          if (continueAnyway != true) {
            setState(() => _isSubmitting = false);
            return;
          }
        }
      } else {
        photoUrl = _uploadedPhotoUrl;
      }

      final user = FirebaseAuth.instance.currentUser;

      // ✅ Saved with stationId so station dashboard can query:
      //    FirebaseFirestore.instance
      //      .collection('complaints')
      //      .where('stationId', isEqualTo: currentStationId)
      //      .snapshots()
      await FirebaseFirestore.instance.collection('complaints').add({
        'userId':      user?.uid   ?? 'anonymous',
        'userEmail':   user?.email ?? 'unknown',
        'stationId':   _selectedStationId,   // ✅ station filters by this
        'station':     _selectedStationName,
        'subject':     _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'photoUrl':    photoUrl,             // ✅ null if no photo
        'status':      'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint submitted successfully! ✓',
              style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: _T.body.copyWith(color: Colors.white)),
        backgroundColor: _T.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Raise a Complaint',
            style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
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
            Text('Report an issue to the station directly',
                style: _T.body.copyWith(fontSize: 12)),
            const SizedBox(height: 24),

            // ── STATION SELECTOR ──────────────────────────────────────────
            Text('STATION',
                style: _T.label.copyWith(fontWeight: FontWeight.w600)),
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
                    child: const Icon(Icons.location_on_rounded,
                        color: _T.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedStationName,
                      style: _T.h2.copyWith(
                        fontSize: 14,
                        color: _selectedStationId.isEmpty
                            ? _T.textSecondary
                            : _T.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loadingStations ? null : _showNearbyStations,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _T.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _loadingStations
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: _T.primary, strokeWidth: 2),
                            )
                          : Text('Change',
                              style: _T.label.copyWith(
                                  color: _T.primary,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── SUBJECT ───────────────────────────────────────────────────
            _editableField(
                _subjectController, 'SUBJECT', 'Briefly describe the issue...'),
            const SizedBox(height: 20),

            // ── DESCRIPTION ───────────────────────────────────────────────
            _editableField(
              _descriptionController,
              'DESCRIPTION',
              'Explain the issue in detail...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // ── PHOTO UPLOAD ──────────────────────────────────────────────
            Text('ATTACHMENTS (OPTIONAL)',
                style: _T.label.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            if (_pickedImage != null) ...[
              // ── Preview picked image ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _pickedImage!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Upload progress overlay
                  if (_isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Uploaded checkmark
                  if (_uploadedPhotoUrl != null)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  // Remove button
                  if (!_isUploadingPhoto)
                    Positioned(
                      top: 8, left: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _pickedImage      = null;
                          _uploadedPhotoUrl = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Change photo button
              if (!_isUploadingPhoto)
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Text('Change photo',
                      style: _T.label.copyWith(
                          color: _T.primary,
                          decoration: TextDecoration.underline)),
                ),
            ] else ...[
              // ── Upload placeholder ──
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _T.border,
                        style: BorderStyle.solid),
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _T.muted,
                          shape: BoxShape.circle,
                          border: Border.all(color: _T.border),
                        ),
                        child: const Icon(Icons.cloud_upload_rounded,
                            color: _T.primary, size: 26),
                      ),
                      const SizedBox(height: 12),
                      Text('Tap to upload photo',
                          style: _T.h2
                              .copyWith(fontSize: 13, color: _T.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Camera or Gallery · JPEG/PNG',
                          style:
                              _T.label.copyWith(color: _T.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // ── SUBMIT ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _isUploadingPhoto)
                    ? null
                    : _submitComplaint,
                icon: (_isSubmitting || _isUploadingPhoto)
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
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
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _T.label.copyWith(fontWeight: FontWeight.w600)),
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: _T.body.copyWith(color: _T.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _T.body
                  .copyWith(color: _T.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}