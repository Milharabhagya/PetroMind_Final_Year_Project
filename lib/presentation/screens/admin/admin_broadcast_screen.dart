import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/notification_service.dart';

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

  static const h1 = TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.4);
  static const h2 = TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.2);
  static const label = TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.6);
  static const body = TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary);

  static BoxDecoration card({Color? color, bool hasBorder = true}) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(16),
    border: hasBorder ? Border.all(color: border, width: 1) : null,
    boxShadow: [BoxShadow(color: dark.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _db = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _selectedType = 'fuel_news';

  final List<Map<String, dynamic>> _types = [
    {'value': 'fuel_news',    'label': 'Fuel News',     'icon': Icons.newspaper_rounded,      'color': Color(0xFF2563EB)},
    {'value': 'price_change', 'label': 'Price Update',  'icon': Icons.price_change_rounded,   'color': Color(0xFFF59E0B)},
    {'value': 'general',      'label': 'General Alert', 'icon': Icons.notifications_rounded,  'color': Color(0xFF16A34A)},
  ];

  Future<void> _broadcast() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a message', style: _T.body.copyWith(color: Colors.white)),
        backgroundColor: _T.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _isSending = true);

    try {
      final stationsSnap = await _db.collection('stations').get();
      final stationIds = stationsSnap.docs.map((d) => d.id).toList();

      if (stationIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No stations to broadcast to', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _isSending = false);
        return;
      }

      await NotificationService.broadcastFuelNews(stationIds: stationIds, message: msg);

      if (!mounted) return;
      _messageController.clear();
      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Broadcast sent to ${stationIds.length} stations!', style: _T.body.copyWith(color: Colors.white)),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: _T.body.copyWith(color: Colors.white)),
        backgroundColor: _T.primary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Broadcast Message', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── INFO BANNER ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This message will be sent to ALL registered station owners as a notification.',
                      style: _T.body.copyWith(color: const Color(0xFF1E3A8A), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── TYPE SELECTOR ──
            Text('Message Type', style: _T.h2.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Choose the category for this broadcast', style: _T.body.copyWith(fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: _types.asMap().entries.map((entry) {
                final t = entry.value;
                final isLast = entry.key == _types.length - 1;
                final isSelected = _selectedType == t['value'];
                final color = t['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t['value'] as String),
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 10),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.08) : _T.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : _T.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(color: _T.dark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(t['icon'] as IconData,
                              color: isSelected ? color : _T.textSecondary, size: 20),
                          const SizedBox(height: 6),
                          Text(
                            t['label'] as String,
                            style: _T.label.copyWith(
                              color: isSelected ? color : _T.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── MESSAGE INPUT ──
            Text('Message', style: _T.h2.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Write the notification message for station owners', style: _T.body.copyWith(fontSize: 11)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
                boxShadow: [BoxShadow(color: _T.dark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 5,
                style: _T.body.copyWith(color: _T.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Government has updated Petrol 92 price to Rs.317.00 effective immediately.',
                  hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── SEND BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _broadcast,
                icon: _isSending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isSending ? 'Sending...' : 'Broadcast to All Stations',
                  style: const TextStyle(
                    fontFamily: 'Poppins', color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  disabledBackgroundColor: _T.muted,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── RECENT BROADCASTS ──
            Text('Recent Broadcasts', style: _T.h2.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('broadcasts').orderBy('timestamp', descending: true).limit(5).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: _T.card(),
                    child: Center(child: Text('No broadcasts sent yet', style: _T.body)),
                  );
                }
                final docs = snapshot.data!.docs;
                return Container(
                  decoration: _T.card(),
                  child: Column(
                    children: docs.asMap().entries.map((entry) {
                      final isLast = entry.key == docs.length - 1;
                      final data = entry.value.data() as Map<String, dynamic>;
                      final msg = data['message'] as String? ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final timeStr = ts != null
                          ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                          : '';
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _T.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.campaign_rounded, color: _T.primary, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(msg,
                                      style: _T.body.copyWith(color: _T.textPrimary, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text(timeStr, style: _T.label.copyWith(fontSize: 10)),
                              ],
                            ),
                          ),
                          if (!isLast) Divider(height: 1, color: _T.border, indent: 52),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}