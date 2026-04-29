import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'stock_history_widget.dart';

// ─────────────────────────────────────────────
// TODAY'S STOCK SUMMARY CHART WIDGET
// ─────────────────────────────────────────────
class TodayStockChartWidget extends StatelessWidget {
  final String uid;
  const TodayStockChartWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    // Fuel types that have litres (exclude Air Pump)
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

    // Short labels for chart X-axis
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
      // Get today's stock logs
      stream: db
          .collection('stations')
          .doc(uid)
          .collection('stock_logs')
          .where('timestamp', isGreaterThanOrEqualTo: todayStartTs)
          .snapshots(),
      builder: (context, logsSnap) {
        return StreamBuilder<QuerySnapshot>(
          // Get current stock levels
          stream: db
              .collection('stations')
              .doc(uid)
              .collection('stock')
              .snapshots(),
          builder: (context, stockSnap) {
            if (!logsSnap.hasData || !stockSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // Build current stock map
            final currentStock = <String, double>{};
            for (final doc in stockSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final fuel = data['fuelType'] as String? ?? '';
              final litres = (data['stockLitres'] as num?)?.toDouble() ?? 0;
              currentStock[fuel] = litres;
            }

            // Aggregate today's inflow and outflow per fuel
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

            // Check if there is any data to show
            final hasData = fuelTypes.any((f) =>
                (todayInflow[f] ?? 0) > 0 ||
                (todayOutflow[f] ?? 0) > 0 ||
                (currentStock[f] ?? 0) > 0);

            if (!hasData) {
              return const Center(
                child: Text(
                  'No stock data for today yet',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            }

            // Only show fuels that have at least some data
            final activeFuels = fuelTypes
                .where((f) =>
                    (todayInflow[f] ?? 0) > 0 ||
                    (todayOutflow[f] ?? 0) > 0 ||
                    (currentStock[f] ?? 0) > 0)
                .toList();

            // Build bar groups
            final barGroups = <BarChartGroupData>[];
            for (int i = 0; i < activeFuels.length; i++) {
              final fuel = activeFuels[i];
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    // Received (inflow) - green
                    BarChartRodData(
                      toY: todayInflow[fuel] ?? 0,
                      color: Colors.greenAccent,
                      width: 8,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    // Sold (outflow) - orange/red
                    BarChartRodData(
                      toY: todayOutflow[fuel] ?? 0,
                      color: Colors.orangeAccent,
                      width: 8,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    // Remaining - blue/light
                    BarChartRodData(
                      toY: currentStock[fuel] ?? 0,
                      color: Colors.lightBlueAccent,
                      width: 8,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                  barsSpace: 3,
                ),
              );
            }

            // Max Y value for chart scaling
            double maxY = 0;
            for (final fuel in activeFuels) {
              final vals = [
                todayInflow[fuel] ?? 0,
                todayOutflow[fuel] ?? 0,
                currentStock[fuel] ?? 0,
              ];
              for (final v in vals) {
                if (v > maxY) maxY = v;
              }
            }
            if (maxY == 0) maxY = 100;
            final chartMaxY = (maxY * 1.2).ceilToDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legend row
                Row(
                  children: [
                    _chartLegend(Colors.greenAccent, 'Received'),
                    const SizedBox(width: 12),
                    _chartLegend(Colors.orangeAccent, 'Sold'),
                    const SizedBox(width: 12),
                    _chartLegend(Colors.lightBlueAccent, 'Remaining'),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              Colors.black.withOpacity(0.8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final fuel = activeFuels[groupIndex];
                            final labels = ['Received', 'Sold', 'Remaining'];
                            return BarTooltipItem(
                              '${fuel}\n${labels[rodIndex]}: ${rod.toY.toStringAsFixed(0)}L',
                              const TextStyle(
                                  color: Colors.white, fontSize: 11),
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
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 9),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= activeFuels.length) {
                                return const SizedBox();
                              }
                              final fuel = activeFuels[idx];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  shortLabels[fuel] ?? fuel,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 9),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
      final current =
          (snap.data()?['stockLitres'] as num?)?.toDouble() ?? 0;
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

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current =
          (snap.data()?['stockLitres'] as num?)?.toDouble() ?? 0;
      final newStock = (current - amount).clamp(0, double.infinity);
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

  void _showStockDialog(String fuel, double currentStock) {
    if (fuel == 'Air Pump') {
      _showAirPumpDialog();
      return;
    }

    final inflowCtrl = TextEditingController();
    final outflowCtrl = TextEditingController();
    final editCtrl =
        TextEditingController(text: currentStock.toStringAsFixed(1));
    int selectedTab = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Text(fuel,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _tabBtn('Add', 0, selectedTab,
                        (v) => setStateDialog(() => selectedTab = v)),
                    const SizedBox(width: 4),
                    _tabBtn('Reduce', 1, selectedTab,
                        (v) => setStateDialog(() => selectedTab = v)),
                    const SizedBox(width: 4),
                    _tabBtn('Edit', 2, selectedTab,
                        (v) => setStateDialog(() => selectedTab = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Current: ${currentStock.toStringAsFixed(1)} L',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (selectedTab == 0)
                  TextField(
                    controller: inflowCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Litres received (inflow)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.arrow_upward,
                          color: Colors.green),
                    ),
                  )
                else if (selectedTab == 1)
                  TextField(
                    controller: outflowCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Litres sold (outflow)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.arrow_downward,
                          color: Colors.red),
                    ),
                  )
                else
                  TextField(
                    controller: editCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Set stock to (Litres)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixIcon:
                          const Icon(Icons.edit, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000)),
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
                      final amount =
                          double.tryParse(outflowCtrl.text);
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
                        const SnackBar(
                          content: Text('✅ Stock updated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                child: const Text('Save',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAirPumpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<DocumentSnapshot>(
        stream: _db
            .collection('stations')
            .doc(_uid)
            .collection('stock')
            .doc('air_pump')
            .snapshots(),
        builder: (context, snapshot) {
          final available =
              (snapshot.data?.data() as Map<String, dynamic>?)?[
                      'available'] as bool? ??
                  true;
          return AlertDialog(
            title: const Text('Air Pump',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Set air pump availability for customers:',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _toggleAirPump(true);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: available
                              ? Colors.green
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✅ Available',
                          style: TextStyle(
                              color: available
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _toggleAirPump(false);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: !available
                              ? Colors.red
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '❌ Unavailable',
                          style: TextStyle(
                              color: !available
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabBtn(
      String label, int index, int selected, Function(int) onTap) {
    final isSelected = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF8B0000) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Color _stockColor(double litres, String fuel, bool? available) {
    if (fuel == 'Air Pump') {
      return available == true ? Colors.green : Colors.red;
    }
    if (litres <= 0) return Colors.red;
    if (litres < 200) return Colors.red;
    if (litres < 500) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(double litres, String fuel, bool? available) {
    if (fuel == 'Air Pump') {
      return available == true ? 'Available' : 'Unavailable';
    }
    return '${litres.toStringAsFixed(0)} Litres';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        automaticallyImplyLeading: false,
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
        title: const Text('Stock Management',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _uid.isEmpty
          ? const Center(child: Text('Not logged in'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── CURRENT STOCK ──
                  Expanded(
                    flex: 3,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('stations')
                          .doc(_uid)
                          .collection('stock')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF8B0000)),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        final stockMap = <String, double>{};
                        final availMap = <String, bool>{};

                        for (final doc in docs) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final fuel =
                              data['fuelType'] as String? ?? '';
                          final litres =
                              (data['stockLitres'] as num?)
                                      ?.toDouble() ??
                                  0;
                          final avail = data['available'] as bool?;
                          stockMap[fuel] = litres;
                          if (avail != null) availMap[fuel] = avail;
                        }

                        Timestamp? lastUpdated;
                        for (final doc in docs) {
                          final ts = (doc.data()
                                  as Map)['updatedAt'] as Timestamp?;
                          if (ts != null &&
                              (lastUpdated == null ||
                                  ts.seconds > lastUpdated.seconds)) {
                            lastUpdated = ts;
                          }
                        }
                        final updatedStr = lastUpdated != null
                            ? _formatTime(lastUpdated.toDate())
                            : 'Never';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B0000),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Fuel Inventory',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              Text(
                                'Last Updated: $updatedStr',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11),
                              ),
                              const Text(
                                'Tap any item to Add / Reduce / Edit',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _fuelTypes.length,
                                  itemBuilder: (context, index) {
                                    final fuel = _fuelTypes[index];
                                    final litres =
                                        stockMap[fuel] ?? 0;
                                    final available = availMap[fuel];
                                    final color = _stockColor(
                                        litres, fuel, available);
                                    final label = _stockLabel(
                                        litres, fuel, available);
                                    return GestureDetector(
                                      onTap: () => _showStockDialog(
                                          fuel, litres),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 8),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fuel,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                  color: color,
                                                  fontSize: 12),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit,
                                                size: 14,
                                                color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── TODAY'S STOCK SUMMARY CHART ──
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                "Today's Stock Summary",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap bars for details',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TodayStockChartWidget(uid: _uid),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── STOCK HISTORY ──
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stock History',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: StockHistoryWidget(uid: _uid),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── LEGEND ──
                  Row(
                    children: [
                      _legend(Colors.green, 'High Stock'),
                      const SizedBox(width: 16),
                      _legend(Colors.orange, 'Medium Stock'),
                      const SizedBox(width: 16),
                      _legend(Colors.red, 'Low Stock'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}