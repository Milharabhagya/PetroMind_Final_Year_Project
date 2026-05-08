// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches Station Dashboard, Admin Price Screen & Stock Management

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
//  SALES & TRANSACTIONS SCREEN
// ─────────────────────────────────────────────
class SalesTransactionsScreen extends StatelessWidget {
  const SalesTransactionsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
        title: Text('Sales & Transactions', style: _T.h2.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TODAY'S SALES SUMMARY ──
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(_uid)
                  .collection('sales')
                  .where('timestamp',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      )))
                  .snapshots(),
              builder: (context, snapshot) {
                double totalRevenue = 0;
                double totalLitres = 0;
                int totalTx = 0;

                if (snapshot.hasData) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalRevenue += (data['total'] as num?)?.toDouble() ?? 0;
                    totalLitres += (data['liters'] as num?)?.toDouble() ?? 0;
                    totalTx++;
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(24),
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
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text("Today's Revenue", style: _T.h2.copyWith(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'LKR ${NumberFormat('#,##0').format(totalRevenue)}',
                        style: _T.h1.copyWith(color: Colors.white, fontSize: 32, letterSpacing: -1),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withOpacity(0.15), height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryMetric(Icons.local_gas_station_rounded, '${totalLitres.toStringAsFixed(0)} Litres'),
                          _summaryMetric(Icons.receipt_long_rounded, '$totalTx Transactions'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── TRANSACTIONS LIST ──
            Text('Recent Transactions', style: _T.h1.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(_uid)
                  .collection('sales')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _T.primary));
                }

                final docs = snapshot.data?.docs ?? [];

                return Container(
                  decoration: _T.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _txHeader(),
                      Divider(color: _T.border, height: 1),
                      if (docs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.receipt_rounded, color: _T.muted, size: 48),
                                const SizedBox(height: 12),
                                Text('No transactions yet', style: _T.body.copyWith(color: _T.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...docs.asMap().entries.map((entry) {
                          final isLast = entry.key == docs.length - 1;
                          final data = entry.value.data() as Map<String, dynamic>;
                          final ts = data['timestamp'] as Timestamp?;
                          final time = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '--';
                          final fuel = data['fuelType'] as String? ?? '--';
                          final litres = (data['liters'] as num?)?.toDouble() ?? 0;
                          final total = (data['total'] as num?)?.toDouble() ?? 0;

                          return Column(
                            children: [
                              _txRow(
                                time,
                                fuel,
                                '${litres.toStringAsFixed(1)}L',
                                'LKR ${NumberFormat('#,##0').format(total)}',
                              ),
                              if (!isLast) Divider(color: _T.border, height: 1),
                            ],
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── STOCK LOGS ──
            Text('Inventory Logs', style: _T.h1.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(_uid)
                  .collection('stock_logs')
                  .orderBy('timestamp', descending: true)
                  .limit(15)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _T.primary));
                }

                final docs = snapshot.data?.docs ?? [];

                return Container(
                  decoration: _T.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _logHeader(),
                      Divider(color: _T.border, height: 1),
                      if (docs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2_rounded, color: _T.muted, size: 48),
                                const SizedBox(height: 12),
                                Text('No stock logs yet', style: _T.body.copyWith(color: _T.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...docs.asMap().entries.map((entry) {
                          final isLast = entry.key == docs.length - 1;
                          final data = entry.value.data() as Map<String, dynamic>;
                          final ts = data['timestamp'] as Timestamp?;
                          final date = ts != null ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) : '--';
                          final fuel = data['fuelType'] as String? ?? '--';
                          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                          final type = data['type'] as String? ?? '';
                          
                          return Column(
                            children: [
                              _logRow(date, fuel, amount, type),
                              if (!isLast) Divider(color: _T.border, height: 1),
                            ],
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGET HELPERS ──

  Widget _summaryMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(label, style: _T.label.copyWith(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _txHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('TIME', style: _T.label.copyWith(fontWeight: FontWeight.w700))),
          Expanded(flex: 3, child: Text('FUEL', style: _T.label.copyWith(fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text('LITRES', style: _T.label.copyWith(fontWeight: FontWeight.w700))),
          Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: _T.label.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _txRow(String time, String fuel, String litres, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(time, style: _T.body.copyWith(fontSize: 12, color: _T.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fuel.length > 12 ? '${fuel.substring(0, 12)}...' : fuel,
              style: _T.h2.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _T.muted, borderRadius: BorderRadius.circular(4)),
              child: Text(litres, style: _T.h2.copyWith(fontSize: 11, color: _T.textPrimary)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: _T.h2.copyWith(fontSize: 13, color: _T.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('DATE', style: _T.label.copyWith(fontWeight: FontWeight.w700))),
          Expanded(flex: 3, child: Text('FUEL', style: _T.label.copyWith(fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text('CHANGE', textAlign: TextAlign.right, style: _T.label.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _logRow(String date, String fuel, double amount, String type) {
    Color typeColor;
    IconData typeIcon;
    String prefix;

    if (type == 'inflow') {
      typeColor = _T.success;
      typeIcon = Icons.arrow_upward_rounded;
      prefix = '+';
    } else if (type == 'outflow') {
      typeColor = _T.warning;
      typeIcon = Icons.arrow_downward_rounded;
      prefix = '-';
    } else {
      typeColor = _T.info;
      typeIcon = Icons.edit_rounded;
      prefix = '=';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(date, style: _T.body.copyWith(fontSize: 11, color: _T.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fuel.length > 12 ? '${fuel.substring(0, 12)}...' : fuel,
              style: _T.h2.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(typeIcon, size: 14, color: typeColor),
                const SizedBox(width: 4),
                Text(
                  '$prefix${amount.toStringAsFixed(0)}L',
                  style: _T.h2.copyWith(fontSize: 13, color: typeColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}