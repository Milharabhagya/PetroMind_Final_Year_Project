import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

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
  String _selectedStationName = 'Select a station';
  String _selectedStationId = '';
  bool _loadingStations = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
          position!.latitude,
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

    // Show bottom sheet with nearby stations
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nearby Stations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Stations within 10km of your location',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 20),
              if (nearbyStations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No stations found nearby.\nTry expanding your search area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: nearbyStations.length,
                    itemBuilder: (context, index) {
                      final station = nearbyStations[index];
                      final isSelected =
                          station['id'] == _selectedStationId;
                      return ListTile(
                        leading: Icon(
                          Icons.local_gas_station,
                          color: isSelected
                              ? const Color(0xFF8B0000)
                              : Colors.grey,
                        ),
                        title: Text(
                          station['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF8B0000)
                                : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '${station['address']} • ${station['distance']} km away',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF8B0000))
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
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
        const SnackBar(
          content: Text('Complaint submitted successfully!'),
          backgroundColor: Colors.green,
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Raise a Complaint',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaint details',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ✅ Station selector with working change button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF8B0000)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected station',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _selectedStationName,
                          style: TextStyle(
                            color: _selectedStationId.isEmpty
                                ? Colors.red[300]
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadingStations ? null : _showNearbyStations,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF8B0000),
                          borderRadius: BorderRadius.circular(8)),
                      child: _loadingStations
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('change',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('Subject',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Briefly describe the issue...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain the issue in detail',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add photos (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Upload photo',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 8),
                  Icon(Icons.cloud_upload, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitComplaint,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Complaint',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
