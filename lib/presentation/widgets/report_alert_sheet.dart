import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petromind/data/models/road_alert_model.dart'; // ✅ FIXED
import 'package:petromind/data/services/road_alert_service.dart'; // ✅ FIXED

class ReportAlertSheet extends StatefulWidget {
  final double userLat;
  final double userLng;

  const ReportAlertSheet({
    super.key,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<ReportAlertSheet> createState() =>
      _ReportAlertSheetState();
}

class _ReportAlertSheetState
    extends State<ReportAlertSheet> {
  String? _selectedType;
  final TextEditingController _descController =
      TextEditingController();
  bool _isSubmitting = false;
  final RoadAlertService _alertService =
      RoadAlertService();

  final List<Map<String, dynamic>> _alertTypes = [
    {
      'type': 'accident',
      'label': 'Accident',
      'icon': '🚨',
      'color': Colors.red
    },
    {
      'type': 'police',
      'label': 'Police',
      'icon': '🚔',
      'color': Colors.blue
    },
    {
      'type': 'roadblock',
      'label': 'Road Block',
      'icon': '🚧',
      'color': Colors.orange
    },
    {
      'type': 'traffic',
      'label': 'Heavy Traffic',
      'icon': '🚦',
      'color': Colors.amber
    },
  ];

  Future<void> _submit() async {
    if (_selectedType == null) return;
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;

    final alert = RoadAlert(
      id: '',
      type: _selectedType!,
      lat: widget.userLat,
      lng: widget.userLng,
      reportedBy: user?.uid ?? 'anonymous',
      reportedAt: DateTime.now(),
      description:
          _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
    );

    await _alertService.reportAlert(alert);
    setState(() => _isSubmitting = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
                20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Report a Road Alert',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Help other drivers by reporting what you see.',
            style:
                TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Alert type selector
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: _alertTypes.map((alertType) {
              final isSelected =
                  _selectedType == alertType['type'];
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedType =
                        alertType['type'] as String),
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (alertType['color'] as Color)
                            .withValues(alpha: 0.15)
                        : Colors.grey[100],
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? alertType['color'] as Color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(alertType['icon'] as String,
                          style: const TextStyle(
                              fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        alertType['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? alertType['color']
                                  as Color
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Optional description
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle:
                  const TextStyle(fontSize: 13),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedType == null ||
                      _isSubmitting
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF8B0000),
                padding: const EdgeInsets.symmetric(
                    vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}