// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Station Dashboard & Customer App Design System

import 'package:flutter/material.dart';
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
//  FUEL PRICE MANAGEMENT SCREEN
// ─────────────────────────────────────────────
class AdminPriceScreen extends StatefulWidget {
  const AdminPriceScreen({super.key});

  @override
  State<AdminPriceScreen> createState() => _AdminPriceScreenState();
}

class _AdminPriceScreenState extends State<AdminPriceScreen> {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'fuel_prices_ceypetco';

  // Track edited prices — docId -> new price string
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _editing = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── LOGIC PRESERVED ──
  // ✅ Save all edited prices to Firestore at once
  Future<void> _saveAll(List<QueryDocumentSnapshot> docs) async {
    setState(() => _isSaving = true);

    try {
      final batch = _db.batch();
      bool anyEdit = false;

      for (final doc in docs) {
        final controller = _controllers[doc.id];
        if (controller == null) continue;
        final newPrice = double.tryParse(controller.text);
        if (newPrice == null) continue;
        final oldPrice = (doc.data() as Map<String, dynamic>)['price'] as num;
        if (newPrice == oldPrice.toDouble()) continue;

        // ✅ Update price + track change direction
        batch.update(_db.collection(_collection).doc(doc.id), {
          'price': newPrice,
          'previousPrice': oldPrice,
          'priceChanged': true,
          'priceUp': newPrice > oldPrice.toDouble(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        anyEdit = true;
      }

      if (anyEdit) {
        await batch.commit();
      }

      if (!mounted) return;
      setState(() => _editing.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Prices updated successfully!', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update prices: $e', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: _T.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Text('Manage Prices', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection(_collection).orderBy('category').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading prices', style: _T.body));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('No prices found.', style: _T.body));
          }

          // ✅ Initialize controllers for any new docs
          for (final doc in docs) {
            if (!_controllers.containsKey(doc.id)) {
              final data = doc.data() as Map<String, dynamic>;
              final price = (data['price'] as num).toDouble();
              _controllers[doc.id] = TextEditingController(text: price.toStringAsFixed(2));
            }
          }

          final changedDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['priceChanged'] == true).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Retail Fuel Prices', style: _T.h1.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text('Update the official rates for your station.', style: _T.body.copyWith(fontSize: 12)),
                const SizedBox(height: 16),

                // ── FUEL PRICE LIST ──
                Container(
                  decoration: _T.card(),
                  child: Column(
                    children: [
                      ...docs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final doc = entry.value;
                        final data = doc.data() as Map<String, dynamic>;
                        final isLast = i == docs.length - 1;
                        final isEditing = _editing[doc.id] == true;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _T.muted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.local_gas_station_rounded, color: _T.textSecondary, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      data['name'] ?? '',
                                      style: _T.h2.copyWith(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: isEditing
                                        ? Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _T.primary.withOpacity(0.05),
                                              border: Border.all(color: _T.primary.withOpacity(0.5)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: _controllers[doc.id],
                                              autofocus: true,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              style: _T.h2.copyWith(color: _T.primary, fontSize: 13),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                prefixText: 'Rs. ',
                                                prefixStyle: _T.h2.copyWith(color: _T.primary, fontSize: 13),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Rs. ${(data['price'] as num).toStringAsFixed(2)}',
                                                style: _T.h2.copyWith(color: _T.primary, fontSize: 14),
                                              ),
                                              Text(' /L', style: _T.label.copyWith(fontSize: 10)),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _editing[doc.id] = !isEditing;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isEditing ? const Color(0xFF16A34A).withOpacity(0.1) : _T.bg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isEditing ? 'Done' : 'Edit',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: isEditing ? const Color(0xFF15803D) : _T.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) Divider(height: 1, color: _T.border, indent: 56),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ Update button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveAll(docs),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                    label: Text(
                      _isSaving ? 'Updating...' : 'Publish New Prices',
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
                const SizedBox(height: 32),

                // ── PRICE CHANGED FUELS ──
                if (changedDocs.isNotEmpty) ...[
                  Text('Recent Changes', style: _T.h2),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _T.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...changedDocs.asMap().entries.map((entry) {
                          final isLast = entry.key == changedDocs.length - 1;
                          final doc = entry.value;
                          final data = doc.data() as Map<String, dynamic>;
                          final priceUp = data['priceUp'] == true;
                          
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        data['name'] ?? '',
                                        style: _T.h2.copyWith(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Rs. ${(data['price'] as num).toStringAsFixed(2)}',
                                            style: _T.h2.copyWith(color: _T.textPrimary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: priceUp ? const Color(0xFFDC2626).withOpacity(0.1) : const Color(0xFF16A34A).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        priceUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                        color: priceUp ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast) Divider(height: 1, color: _T.border),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}