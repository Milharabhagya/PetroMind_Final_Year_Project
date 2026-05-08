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
  final TextEditingController _globalDateController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _globalDateController.dispose();
    super.dispose();
  }

  // ── LOGIC PRESERVED ──
  // ✅ Save all edited prices to Firestore at once
  Future<void> _saveAll(List<QueryDocumentSnapshot> docs) async {
    setState(() => _isSaving = true);

    try {
      final batch = _db.batch();
      final globalDate = _globalDateController.text.trim();
      bool anyEdit = false;

      for (final doc in docs) {
        final controller = _controllers[doc.id];
        if (controller == null) continue;
        
        final newPrice = double.tryParse(controller.text);
        if (newPrice == null) continue;
        
        // Null-safe fetch of old price
        final data = doc.data() as Map<String, dynamic>;
        final oldPrice = (data['price'] as num?)?.toDouble() ?? newPrice;
        
        if (newPrice == oldPrice) continue;

        // ✅ Update price + track change direction safely
        final updateData = <String, dynamic>{
          'price': newPrice,
          'previousPrice': oldPrice,
          'priceChanged': true,
          'priceUp': newPrice > oldPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (globalDate.isNotEmpty) {
          updateData['effectiveDate'] = globalDate;
        }

        batch.update(_db.collection(_collection).doc(doc.id), updateData);
        anyEdit = true;
      }

      if (anyEdit) {
        await batch.commit();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Prices updated! Customers see new prices now.', style: _T.body.copyWith(color: Colors.white)),
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

  // ✅ Save a single edited price safely
  Future<void> _saveSingle(QueryDocumentSnapshot doc) async {
    final priceText = _controllers[doc.id]?.text.trim() ?? '';
    if (priceText.isEmpty) return;
    
    final newPrice = double.tryParse(priceText);
    if (newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid price value', style: _T.body.copyWith(color: Colors.white)),
          backgroundColor: _T.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final data = doc.data() as Map<String, dynamic>;
      final oldPrice = (data['price'] as num?)?.toDouble() ?? newPrice;

      final updateData = <String, dynamic>{
        'price': newPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Track history if price actually changed
      if (newPrice != oldPrice) {
        updateData['previousPrice'] = oldPrice;
        updateData['priceChanged'] = true;
        updateData['priceUp'] = newPrice > oldPrice;
      }
      
      final globalDate = _globalDateController.text.trim();
      if (globalDate.isNotEmpty) {
        updateData['effectiveDate'] = globalDate;
      }

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(doc.id)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Price saved!', style: _T.body.copyWith(color: Colors.white)),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: _T.body.copyWith(color: Colors.white)),
            backgroundColor: _T.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        title: Text('Update Fuel Prices', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
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

          // ✅ Initialize controllers for any new docs safely
          for (final doc in docs) {
            if (!_controllers.containsKey(doc.id)) {
              final data = doc.data() as Map<String, dynamic>;
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              _controllers[doc.id] = TextEditingController(text: price.toStringAsFixed(2));
            }
          }

          final retailDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['category'] == 'retail').toList();
          final industrialDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['category'] == 'industrial').toList();
          
          // Null-safe filtering for changed docs
          final changedDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['priceChanged'] == true).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── INFO BANNER ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Soft blue background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Changes are instant — all customers see updated prices immediately.',
                          style: _T.body.copyWith(color: const Color(0xFF1E3A8A), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── EFFECTIVE DATE ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _T.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Effective Date', style: _T.h2.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Applied to all prices when saved', style: _T.body.copyWith(fontSize: 11)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _T.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _T.border),
                        ),
                        child: TextField(
                          controller: _globalDateController,
                          style: _T.body.copyWith(color: _T.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. Effective Midnight, Mar 1, 2026',
                            hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.calendar_today_rounded, color: _T.textSecondary, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── RETAIL PRICES ──
                Text('Retail Fuel', style: _T.h1.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                ...retailDocs.map((doc) => _priceRow(doc)),

                const SizedBox(height: 16),

                // ── INDUSTRIAL PRICES ──
                if (industrialDocs.isNotEmpty) ...[
                  Text('Industrial Fuel', style: _T.h1.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  ...industrialDocs.map((doc) => _priceRow(doc)),
                  const SizedBox(height: 16),
                ],

                // ── SAVE ALL BUTTON ──
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
                      _isSaving ? 'Saving...' : 'Publish All Prices',
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

                // ── RECENT CHANGES HISTORY ──
                if (changedDocs.isNotEmpty) ...[
                  Text('Recent Changes', style: _T.h1.copyWith(fontSize: 18)),
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
                          
                          // Null-safe boolean check
                          final priceUp = data['priceUp'] == true;
                          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                          
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
                                            'Rs. ${price.toStringAsFixed(2)}',
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

  // ── REUSABLE PRICE ROW WIDGET ──
  Widget _priceRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Null-safe fetch of current price
    final currentPrice = (data['price'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _T.card(),
      child: Row(
        children: [
          // Fuel Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _T.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_gas_station_rounded, color: _T.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),

          // Fuel Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: _T.h2.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Current: Rs. ${currentPrice.toStringAsFixed(2)}',
                  style: _T.body.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // New Price Input
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.border),
              ),
              child: TextField(
                controller: _controllers[doc.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: _T.h2.copyWith(color: _T.primary, fontSize: 13),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  prefixText: 'Rs. ',
                  prefixStyle: _T.label.copyWith(color: _T.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Quick Save Button
          GestureDetector(
            onTap: () => _saveSingle(doc),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _T.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}