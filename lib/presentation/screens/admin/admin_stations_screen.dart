import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

class AdminStationsScreen extends StatefulWidget {
  const AdminStationsScreen({super.key});

  @override
  State<AdminStationsScreen> createState() => _AdminStationsScreenState();
}

class _AdminStationsScreenState extends State<AdminStationsScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

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
        title: Text('Station Management', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: Column(
        children: [

          // ── SEARCH ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
                boxShadow: [BoxShadow(color: _T.dark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                style: _T.body.copyWith(color: _T.textPrimary),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search stations...',
                  hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.5)),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded, color: _T.textSecondary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── STATION LIST ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('stations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                }

                var docs = snapshot.data!.docs;
                if (_search.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = (d['stationName'] as String? ?? d['name'] as String? ?? '').toLowerCase();
                    final brand = (d['brand'] as String? ?? '').toLowerCase();
                    return name.contains(_search) || brand.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_gas_station_rounded, color: _T.textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('No stations found', style: _T.h2),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final name    = data['stationName'] as String? ?? data['name'] as String? ?? 'Unknown';
                    final brand   = data['brand'] as String? ?? '—';
                    final city    = data['city'] as String? ?? '—';
                    final isOpen  = data['isOpen'] as bool? ?? false;
                    final revenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
                    final email   = data['email'] as String? ?? '—';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: _T.card(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Header row ──
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.local_gas_station_rounded,
                                      color: Color(0xFF16A34A), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: _T.h2.copyWith(fontSize: 14),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('$brand • $city',
                                          style: _T.body.copyWith(fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? const Color(0xFF16A34A).withOpacity(0.1)
                                        : const Color(0xFFDC2626).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOpen ? 'Open' : 'Closed',
                                    style: _T.label.copyWith(
                                      color: isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold, fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Divider(height: 20, color: _T.border),

                            // ── Info chips ──
                            Row(
                              children: [
                                _infoChip(Icons.email_outlined, email, const Color(0xFF2563EB)),
                                const SizedBox(width: 16),
                                _infoChip(Icons.account_balance_wallet_rounded,
                                    'Rs.${NumberFormat('#,##0').format(revenue)}',
                                    const Color(0xFF16A34A)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: _T.body.copyWith(fontSize: 11, color: _T.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}