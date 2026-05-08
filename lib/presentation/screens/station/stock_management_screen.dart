// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins (Themed)
// Matches Station Dashboard, Admin Price Screen & Customer App

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'stock_history_widget.dart';
import '../../../data/services/notification_service.dart';

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

  // Functional Colors
  static const success    = Color(0xFF16A34A);
  static const warning    = Color(0xFFF59E0B);
  static const danger     = Color(0xFFDC2626);
  static const info       = Color(0xFF2563EB);

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
// TODAY'S STOCK SUMMARY CHART WIDGET
// ─────────────────────────────────────────────
class TodayStockChartWidget extends StatelessWidget {
  final String uid;
  const TodayStockChartWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    final fuelTypes = [
      'Petrol 92 Octane',
      'Petrol 95 Octane',
      'Auto Diesel',
      'Super Diesel',
      'Lanka Kerosene',
      'Industrial Kerosene',
      'Lanka Fuel Oil Super',
      'Lanka Fuel Oil 1500 Super',
    ];

    final shortLabels = {
      'Petrol 92 Octane': 'P92',
      'Petrol 95 Octane': 'P95',
      'Auto Diesel': 'ADsl',
      'Super Diesel': 'SDsl',
      'Lanka Kerosene': 'LKer',
      'Industrial Kerosene': 'IKer',
      'Lanka Fuel Oil Super': 'FOSup',
      'Lanka Fuel Oil 1500 Super': 'FO1500',
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayStartTs = Timestamp.fromDate(todayStart);

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('stations')
          .doc(uid)
          .collection('stock_logs')
          .where('timestamp', isGreaterThanOrEqualTo: todayStartTs)
          .snapshots(),
      builder: (context, logsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: db
              .collection('stations')
              .doc(uid)
              .collection('stock')
              .snapshots(),
          builder: (context, stockSnap) {
            if (!logsSnap.hasData || !stockSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              );
            }

            final currentStock = <String, double>{};
            for (final doc in stockSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final fuel = data['fuelType'] as String? ?? '';
              final litres = (data['stockLitres'] as num?)?.toDouble() ?? 0;
              currentStock[fuel] = litres;
            }

            final todayInflow = <String, double>{};
            final todayOutflow = <String, double>{};
            for (final fuel in fuelTypes) {
              todayInflow[fuel] = 0;
              todayOutflow[fuel] = 0;
            }

            for (final doc in logsSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final fuel = data['fuelType'] as String? ?? '';
              final type = data['type'] as String? ?? '';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              if (!fuelTypes.contains(fuel)) continue;
              if (type == 'inflow') {
                todayInflow[fuel] = (todayInflow[fuel] ?? 0) + amount;
              } else if (type == 'outflow') {
                todayOutflow[fuel] = (todayOutflow[fuel] ?? 0) + amount;
              }
            }

            final hasData = fuelTypes.any((f) =>
                (todayInflow[f] ?? 0) > 0 ||
                (todayOutflow[f] ?? 0) > 0 ||
                (currentStock[f] ?? 0) > 0);

            if (!hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, color: Colors.white.withOpacity(0.3), size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No stock data for today yet',
                      style: _T.body.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }

            final activeFuels = fuelTypes
                .where((f) =>
                    (todayInflow[f] ?? 0) > 0 ||
                    (todayOutflow[f] ?? 0) > 0 ||
                    (currentStock[f] ?? 0) > 0)
                .toList();

            final barGroups = <BarChartGroupData>[];
            for (int i = 0; i < activeFuels.length; i++) {
              final fuel = activeFuels[i];
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: todayInflow[fuel] ?? 0,
                      color: const Color(0xFF4ADE80), // Bright Neon Green
                      width: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    BarChartRodData(
                      toY: todayOutflow[fuel] ?? 0,
                      color: const Color(0xFFFBBF24), // Vibrant Amber
                      width: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    BarChartRodData(
                      toY: currentStock[fuel] ?? 0,
                      color: Colors.white, // Crisp White
                      width: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                  barsSpace: 4,
                ),
              );
            }

            double maxY = 0;
            for (final fuel in activeFuels) {
              for (final v in [
                todayInflow[fuel] ?? 0,
                todayOutflow[fuel] ?? 0,
                currentStock[fuel] ?? 0,
              ]) {
                if (v > maxY) maxY = v;
              }
            }
            if (maxY == 0) maxY = 100;
            final chartMaxY = (maxY * 1.2).ceilToDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _chartLegend(const Color(0xFF4ADE80), 'Received'),
                    const SizedBox(width: 16),
                    _chartLegend(const Color(0xFFFBBF24), 'Sold'),
                    const SizedBox(width: 16),
                    _chartLegend(Colors.white, 'Remaining'),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => _T.dark.withOpacity(0.9),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final fuel = activeFuels[groupIndex];
                            final labels = ['Received', 'Sold', 'Remaining'];
                            return BarTooltipItem(
                              '$fuel\n',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: '${labels[rodIndex]}: ${rod.toY.toStringAsFixed(0)}L',
                                  style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(1)}k'
                                    : value.toInt().toString(),
                                style: _T.label.copyWith(fontSize: 10, color: Colors.white60),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= activeFuels.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  shortLabels[activeFuels[idx]] ?? activeFuels[idx],
                                  style: _T.label.copyWith(fontSize: 10, color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withOpacity(0.15),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: _T.label.copyWith(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MAIN STOCK MANAGEMENT SCREEN
// ─────────────────────────────────────────────
class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<String> _fuelTypes = [
    'Air Pump',
    'Petrol 92 Octane',
    'Petrol 95 Octane',
    'Auto Diesel',
    'Super Diesel',
    'Lanka Kerosene',
    'Industrial Kerosene',
    'Lanka Fuel Oil Super',
    'Lanka Fuel Oil 1500 Super',
  ];

  final Map<String, String> _fuelPriceIds = {
    'Petrol 92 Octane': 'petrol_92',
    'Petrol 95 Octane': 'petrol_95',
    'Auto Diesel': 'auto_diesel',
    'Super Diesel': 'super_diesel',
    'Lanka Kerosene': 'lanka_kerosene',
    'Industrial Kerosene': 'industrial_kerosene',
    'Lanka Fuel Oil Super': 'fuel_oil_super',
    'Lanka Fuel Oil 1500 Super': 'fuel_oil_1500',
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeStock();
  }

  // ── LOGIC PRESERVED ──
  Future<void> _initializeStock() async {
    if (_uid.isEmpty) return;
    final batch = _db.batch();
    bool needsInit = false;
    for (final fuel in _fuelTypes) {
      final docId = fuel.replaceAll(' ', '_').toLowerCase();
      final ref = _db
          .collection('stations')
          .doc(_uid)
          .collection('stock')
          .doc(docId);
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, {
          'fuelType': fuel,
          'stockLitres': fuel == 'Air Pump' ? null : 0.0,
          'available': fuel == 'Air Pump' ? true : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        needsInit = true;
      }
    }
    if (needsInit) await batch.commit();
  }

  Future<double> _getFuelPrice(String fuel) async {
    final priceId = _fuelPriceIds[fuel];
    if (priceId == null) return 0;
    final doc = await _db
        .collection('fuel_prices_ceypetco')
        .doc(priceId)
        .get();
    return (doc.data()?['price'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _addInflow(String fuel, double amount) async {
    if (_uid.isEmpty) return;
    final docId = fuel.replaceAll(' ', '_').toLowerCase();
    final ref = _db
        .collection('stations')
        .doc(_uid)
        .collection('stock')
        .doc(docId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['stockLitres'] as num?)?.toDouble() ?? 0;
      tx.update(ref, {
        'stockLitres': current + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _db
        .collection('stations')
        .doc(_uid)
        .collection('stock_logs')
        .add({
      'fuelType': fuel,
      'type': 'inflow',
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await NotificationService.onStockUpdated(
      stationId: _uid,
      fuelType: fuel,
      changeType: 'inflow',
      amount: amount,
    );
  }

  Future<void> _reduceStock(String fuel, double amount) async {
    if (_uid.isEmpty) return;
    final docId = fuel.replaceAll(' ', '_').toLowerCase();
    final ref = _db
        .collection('stations')
        .doc(_uid)
        .collection('stock')
        .doc(docId);

    final price = await _getFuelPrice(fuel);
    final revenue = amount * price;
    double newStock = 0;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['stockLitres'] as num?)?.toDouble() ?? 0;
      newStock = (current - amount).clamp(0, double.infinity);
      tx.update(ref, {
        'stockLitres': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _db
        .collection('stations')
        .doc(_uid)
        .collection('stock_logs')
        .add({
      'fuelType': fuel,
      'type': 'outflow',
      'amount': amount,
      'pricePerLitre': price,
      'revenue': revenue,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('stations')
        .doc(_uid)
        .collection('sales')
        .add({
      'fuelType': fuel,
      'liters': amount,
      'pricePerLiter': price,
      'total': revenue,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('stations').doc(_uid).update({
      'totalRevenue': FieldValue.increment(revenue),
    });

    await NotificationService.onStockUpdated(
      stationId: _uid,
      fuelType: fuel,
      changeType: 'outflow',
      amount: amount,
      currentStock: newStock,
    );
  }

  Future<void> _editStock(String fuel, double newAmount) async {
    if (_uid.isEmpty) return;
    final docId = fuel.replaceAll(' ', '_').toLowerCase();
    await _db
        .collection('stations')
        .doc(_uid)
        .collection('stock')
        .doc(docId)
        .update({
      'stockLitres': newAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('stations')
        .doc(_uid)
        .collection('stock_logs')
        .add({
      'fuelType': fuel,
      'type': 'edit',
      'amount': newAmount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await NotificationService.onStockUpdated(
      stationId: _uid,
      fuelType: fuel,
      changeType: 'edit',
      amount: newAmount,
      currentStock: newAmount,
    );
  }

  Future<void> _toggleAirPump(bool available) async {
    if (_uid.isEmpty) return;
    await _db
        .collection('stations')
        .doc(_uid)
        .collection('stock')
        .doc('air_pump')
        .update({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('stations')
        .doc(_uid)
        .collection('stock_logs')
        .add({
      'fuelType': 'Air Pump',
      'type': 'availability',
      'available': available,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ── MODAL UI REPLACEMENTS ──
  void _showStockDialog(String fuel, double currentStock) {
    if (fuel == 'Air Pump') {
      _showAirPumpDialog();
      return;
    }

    final inflowCtrl = TextEditingController();
    final outflowCtrl = TextEditingController();
    final editCtrl = TextEditingController(text: currentStock.toStringAsFixed(1));
    int selectedTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20, right: 20, top: 12,
            ),
            decoration: const BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2)),
                ),
                Text('Manage $fuel', style: _T.h1.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text('Current: ${currentStock.toStringAsFixed(1)} L', style: _T.label.copyWith(color: _T.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Segmented Control Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _T.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _tabBtn('Add', 0, selectedTab, (v) => setStateDialog(() => selectedTab = v)),
                      _tabBtn('Reduce', 1, selectedTab, (v) => setStateDialog(() => selectedTab = v)),
                      _tabBtn('Set', 2, selectedTab, (v) => setStateDialog(() => selectedTab = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Inputs
                if (selectedTab == 0)
                  _buildDialogInput(inflowCtrl, 'Litres received (inflow)', Icons.arrow_upward_rounded, _T.success)
                else if (selectedTab == 1)
                  _buildDialogInput(outflowCtrl, 'Litres sold (outflow)', Icons.arrow_downward_rounded, _T.warning)
                else
                  _buildDialogInput(editCtrl, 'Set exact stock (Litres)', Icons.edit_rounded, _T.info),
                
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text('Cancel', style: _T.h2.copyWith(fontSize: 14, color: _T.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isSaving = true);
                          try {
                            if (selectedTab == 0) {
                              final amount = double.tryParse(inflowCtrl.text);
                              if (amount != null && amount > 0) {
                                await _addInflow(fuel, amount);
                              }
                            } else if (selectedTab == 1) {
                              final amount = double.tryParse(outflowCtrl.text);
                              if (amount != null && amount > 0) {
                                await _reduceStock(fuel, amount);
                              }
                            } else {
                              final amount = double.tryParse(editCtrl.text);
                              if (amount != null && amount >= 0) {
                                await _editStock(fuel, amount);
                              }
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Stock updated!', style: _T.body.copyWith(color: Colors.white)),
                                  backgroundColor: _T.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e', style: _T.body.copyWith(color: Colors.white)),
                                  backgroundColor: _T.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                        child: Text('Save Changes', style: _T.h2.copyWith(fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAirPumpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StreamBuilder<DocumentSnapshot>(
        stream: _db
            .collection('stations')
            .doc(_uid)
            .collection('stock')
            .doc('air_pump')
            .snapshots(),
        builder: (context, snapshot) {
          final available = (snapshot.data?.data() as Map<String, dynamic>?)?['available'] as bool? ?? true;
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            decoration: const BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2)),
                ),
                Text('Air Pump Status', style: _T.h1.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text('Set availability for customers', style: _T.body.copyWith(fontSize: 13)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await _toggleAirPump(true);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: available ? _T.success : _T.muted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: available ? _T.success : _T.border),
                          ),
                          child: Center(
                            child: Text(
                              'Available',
                              style: _T.h2.copyWith(
                                fontSize: 14,
                                color: available ? Colors.white : _T.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await _toggleAirPump(false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !available ? _T.danger : _T.muted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: !available ? _T.danger : _T.border),
                          ),
                          child: Center(
                            child: Text(
                              'Unavailable',
                              style: _T.h2.copyWith(
                                fontSize: 14,
                                color: !available ? Colors.white : _T.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogInput(TextEditingController ctrl, String label, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: _T.body.copyWith(color: _T.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _T.label.copyWith(color: _T.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int index, int selected, Function(int) onTap) {
    final isSelected = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _T.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(color: _T.dark.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _T.h2.copyWith(
              fontSize: 12,
              color: isSelected ? _T.primary : _T.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──
  Color _stockColor(double litres, String fuel, bool? available) {
    if (fuel == 'Air Pump') {
      return available == true ? _T.success : _T.danger;
    }
    if (litres <= 0) return _T.danger;
    if (litres < 200) return _T.danger;
    if (litres < 500) return _T.warning;
    return _T.success;
  }

  String _stockLabel(double litres, String fuel, bool? available) {
    if (fuel == 'Air Pump') {
      return available == true ? 'Available' : 'Unavailable';
    }
    return '${litres.toStringAsFixed(0)} L';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Stock Management', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: _uid.isEmpty
          ? Center(child: Text('Not logged in', style: _T.body))
          : Column(
              children: [
                // ── CURRENT STOCK LIST ──
                Expanded(
                  flex: 5,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('stations')
                        .doc(_uid)
                        .collection('stock')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      final stockMap = <String, double>{};
                      final availMap = <String, bool>{};

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final fuel = data['fuelType'] as String? ?? '';
                        final litres = (data['stockLitres'] as num?)?.toDouble() ?? 0;
                        final avail = data['available'] as bool?;
                        stockMap[fuel] = litres;
                        if (avail != null) availMap[fuel] = avail;
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _fuelTypes.length,
                        itemBuilder: (context, index) {
                          final fuel = _fuelTypes[index];
                          final litres = stockMap[fuel] ?? 0;
                          final available = availMap[fuel];
                          final color = _stockColor(litres, fuel, available);
                          final label = _stockLabel(litres, fuel, available);

                          return GestureDetector(
                            onTap: () => _showStockDialog(fuel, litres),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: _T.card(),
                              child: Row(
                                children: [
                                  // Fuel Icon / Indicator
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      fuel,
                                      style: _T.h2.copyWith(fontSize: 14),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        label,
                                        style: _T.h2.copyWith(fontSize: 13, color: color),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _T.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: _T.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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

                // ── TODAY'S STOCK SUMMARY CHART ──
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_T.primary, _T.dark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _T.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Summary", style: _T.h1.copyWith(fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Tap bars for detailed info', style: _T.label.copyWith(fontSize: 10, color: Colors.white60)),
                        const SizedBox(height: 12),
                        Expanded(child: TodayStockChartWidget(uid: _uid)),
                      ],
                    ),
                  ),
                ),

                // ── STOCK HISTORY (Embedded Widget) ──
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    padding: const EdgeInsets.all(16),
                    decoration: _T.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock History Logs', style: _T.h1.copyWith(fontSize: 16, color: _T.primary)),
                        const SizedBox(height: 12),
                        Expanded(child: StockHistoryWidget(uid: _uid)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}