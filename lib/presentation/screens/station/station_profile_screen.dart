import 'package:flutter/material.dart';

class StationProfileScreen extends StatefulWidget {
  const StationProfileScreen({super.key});

  @override
  State<StationProfileScreen> createState() => _StationProfileScreenState();
}

class _StationProfileScreenState extends State<StationProfileScreen> {
  final _stationNameController = TextEditingController(text: 'Kaduwela IOC!');
  final _cityController = TextEditingController(text: 'Kaduwela');
  final _brandController = TextEditingController(text: 'IOC');
  final _emailController = TextEditingController(text: 'lockduwela@gmail.com');

  bool _isEditing = false;

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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        // ✅ removed notification + profile icons
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── AVATAR ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'IOC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('IOC',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),

            // ── RATING ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  4,
                  (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                ),
                const Icon(Icons.star_border, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text('4.0', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 24),

            // ── STATION NAME with ONE pencil ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B0000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _isEditing
                        ? TextField(
                            controller: _stationNameController,
                            autofocus: true,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration:
                                const InputDecoration(border: InputBorder.none),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              _stationNameController.text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isEditing = !_isEditing),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit, color: Colors.white54, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── CITY ──
            _buildField(_cityController),
            const SizedBox(height: 12),

            // ── BRAND ──
            _buildField(_brandController),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter your name and an optional profile photo',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),

            // ── EMAIL ──
            _buildField(_emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter your Email address',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            const SizedBox(height: 32),

            // ── SAVE BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save edits',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
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

  // ── FIELDS WITHOUT ICONS ──
  Widget _buildField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6B0000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _isEditing
          ? TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(border: InputBorder.none),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                controller.text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
    );
  }
}