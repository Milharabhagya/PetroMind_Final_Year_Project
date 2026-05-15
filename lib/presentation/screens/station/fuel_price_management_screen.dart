// ✅ STATION VIEW — READ ONLY
// Fuel prices are set by PetroMind Admin only.
// Station owners can VIEW but not EDIT prices.
// Design: Minimalist Industrial SaaS · Poppins

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

// ─────────────────────────────────────────────
//  FUEL PRICE MANAGEMENT SCREEN (Station — Read Only)
// ─────────────────────────────────────────────
class FuelPriceManagementScreen extends StatelessWidget {
  const FuelPriceManagementScreen({super.key});

  static const _collection = 'fuel_prices_ceypetco';

  String _formatUpdated(Timestamp? ts) {
    if (ts == null) return 'Not yet updated';
    final date = ts.toDate();
    final now  = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hr ago';
    return DateFormat('MMM d, y').format(date);
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
        title: Text('Current Fuel Prices',
            style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
        // ✅ Live indicator in app bar
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('Live',
                    style: _T.label.copyWith(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(_collection)
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_gas_station_rounded,
                      color: _T.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('No prices available yet.', style: _T.h2),
                  const SizedBox(height: 4),
                  Text('Admin will update prices shortly.',
                      style: _T.body.copyWith(fontSize: 12)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Split into retail and industrial
          final retailDocs = docs
              .where((d) => (d.data() as Map)['category'] == 'retail')
              .toList();
          final industrialDocs = docs
              .where((d) => (d.data() as Map)['category'] == 'industrial')
              .toList();
          final changedDocs = docs
              .where((d) => (d.data() as Map)['priceChanged'] == true)
              .toList();

          // Get last updated time from first doc
          final firstData  = docs.first.data() as Map<String, dynamic>;
          final lastUpdated = _formatUpdated(firstData['updatedAt'] as Timestamp?);
          final effectiveDate = firstData['effectiveDate'] as String? ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── ADMIN-CONTROLLED BANNER ──────────────────────────────
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
                        decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prices set by PetroMind Admin',
                                style: _T.h2.copyWith(
                                    fontSize: 13,
                                    color: const Color(0xFF1E3A8A))),
                            const SizedBox(height: 2),
                            Text(
                              'These are the official national fuel rates. '
                              'You cannot edit them.',
                              style: _T.body.copyWith(
                                  color: const Color(0xFF3B82F6), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── LAST UPDATED INFO ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: _T.card(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: _T.muted, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.update_rounded,
                            color: _T.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last updated: $lastUpdated',
                                style: _T.h2.copyWith(fontSize: 13)),
                            if (effectiveDate.isNotEmpty)
                              Text(effectiveDate,
                                  style: _T.body.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                      // Live pulse dot
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── RETAIL PRICES ─────────────────────────────────────────
                if (retailDocs.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('Retail Prices', style: _T.h1.copyWith(fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _T.muted,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _T.border),
                        ),
                        child: Text('READ ONLY',
                            style: _T.label.copyWith(fontSize: 9, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _T.card(),
                    child: Column(
                      children: retailDocs.asMap().entries.map((entry) {
                        final isLast = entry.key == retailDocs.length - 1;
                        return _priceRow(entry.value, isLast: isLast);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── INDUSTRIAL PRICES ─────────────────────────────────────
                if (industrialDocs.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('Industrial Prices', style: _T.h1.copyWith(fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _T.muted,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _T.border),
                        ),
                        child: Text('READ ONLY',
                            style: _T.label.copyWith(fontSize: 9, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _T.card(),
                    child: Column(
                      children: industrialDocs.asMap().entries.map((entry) {
                        final isLast = entry.key == industrialDocs.length - 1;
                        return _priceRow(entry.value, isLast: isLast);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── RECENT PRICE CHANGES ──────────────────────────────────
                if (changedDocs.isNotEmpty) ...[
                  Text('Recent Changes', style: _T.h1.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Latest price updates from admin',
                      style: _T.body.copyWith(fontSize: 12)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _T.card(),
                    child: Column(
                      children: changedDocs.asMap().entries.map((entry) {
                        final isLast  = entry.key == changedDocs.length - 1;
                        final doc     = entry.value;
                        final data    = doc.data() as Map<String, dynamic>;
                        final priceUp = data['priceUp'] == true;
                        final price   = (data['price'] as num?)?.toDouble() ?? 0.0;
                        final prevPrice = (data['previousPrice'] as num?)?.toDouble();

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: priceUp
                                          ? const Color(0xFFDC2626).withOpacity(0.1)
                                          : const Color(0xFF16A34A).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      priceUp
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      color: priceUp
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF16A34A),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['name'] ?? '',
                                            style: _T.h2.copyWith(fontSize: 13)),
                                        if (prevPrice != null)
                                          Text(
                                            'Rs. ${prevPrice.toStringAsFixed(2)} → Rs. ${price.toStringAsFixed(2)}',
                                            style: _T.body.copyWith(fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: priceUp
                                          ? const Color(0xFFDC2626).withOpacity(0.08)
                                          : const Color(0xFF16A34A).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      priceUp ? 'Increased' : 'Decreased',
                                      style: _T.label.copyWith(
                                        color: priceUp
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) Divider(height: 1, color: _T.border),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── BOTTOM INFO ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'These are the official CPC rates for Sri Lanka, '
                          'updated by the PetroMind admin team. '
                          'Prices update automatically for all customers when changed.',
                          style: _T.body.copyWith(
                              fontSize: 11, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── READ-ONLY PRICE ROW ───────────────────────────────────────────────────
  Widget _priceRow(QueryDocumentSnapshot doc, {required bool isLast}) {
    final data    = doc.data() as Map<String, dynamic>;
    final price   = (data['price'] as num?)?.toDouble() ?? 0.0;
    final name    = data['name'] as String? ?? '';
    final priceUp = data['priceUp'] as bool?;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Fuel icon ──
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: _T.muted, borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.local_gas_station_rounded,
                    color: _T.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),

              // ── Name ──
              Expanded(
                flex: 3,
                child: Text(name, style: _T.h2.copyWith(fontSize: 14)),
              ),

              // ── Price + trend ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rs. ${price.toStringAsFixed(2)}',
                    style: _T.h2.copyWith(color: _T.primary, fontSize: 15),
                  ),
                  Text(' /L', style: _T.label.copyWith(fontSize: 10)),
                  const SizedBox(width: 6),
                  if (priceUp != null)
                    Icon(
                      priceUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: priceUp
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: _T.border, indent: 56),
      ],
    );
  }
}