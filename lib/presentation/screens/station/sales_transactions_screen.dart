import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesTransactionsScreen extends StatelessWidget {
  const SalesTransactionsScreen({super.key});

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

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
        title: const Text('Sales & Transactions',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Today's sales summary from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(_uid)
                  .collection('sales')
                  .where('timestamp',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(DateTime(
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
                    final data =
                        doc.data() as Map<String, dynamic>;
                    totalRevenue +=
                        (data['total'] as num?)
                                ?.toDouble() ??
                            0;
                    totalLitres +=
                        (data['liters'] as num?)
                                ?.toDouble() ??
                            0;
                    totalTx++;
                  }
                }

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
                      const Text("Today's Sales",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'LKR ${NumberFormat('#,##0').format(totalRevenue)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text(
                          '${totalLitres.toStringAsFixed(0)} Litres  ',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12),
                        ),
                        Text(
                          '$totalTx Transactions',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ✅ Transactions list from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(_uid)
                  .collection('sales')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs =
                    snapshot.data?.docs ?? [];

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
                      const Text('Transactions List',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _txHeader(),
                      if (docs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16),
                          child: Center(
                            child: Text(
                                'No transactions yet',
                                style: TextStyle(
                                    color: Colors.white70)),
                          ),
                        )
                      else
                        ...docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          final ts = data['timestamp']
                              as Timestamp?;
                          final time = ts != null
                              ? DateFormat('hh:mm a')
                                  .format(ts.toDate())
                              : '--';
                          final fuel =
                              data['fuelType'] as String? ??
                                  '--';
                          final litres =
                              (data['liters'] as num?)
                                      ?.toDouble() ??
                                  0;
                          final total =
                              (data['total'] as num?)
                                      ?.toDouble() ??
                                  0;
                          return _txRow(
                            time,
                            fuel.length > 6
                                ? fuel.substring(0, 6)
                                : fuel,
                            '${litres.toStringAsFixed(0)}L',
                            'LKR ${NumberFormat('#,##0').format(total)}',
                            '✓',
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ✅ Stock logs as transaction log
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .doc(_uid)
                  .collection('stock_logs')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs =
                    snapshot.data?.docs ?? [];

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
                      const Text('Stock Logs',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (docs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16),
                          child: Center(
                            child: Text('No stock logs yet',
                                style: TextStyle(
                                    color: Colors.white70)),
                          ),
                        )
                      else
                        ...docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          final ts = data['timestamp']
                              as Timestamp?;
                          final date = ts != null
                              ? DateFormat('dd-MM-yyyy')
                                  .format(ts.toDate())
                              : '--';
                          final fuel =
                              data['fuelType'] as String? ??
                                  '--';
                          final amount =
                              (data['amount'] as num?)
                                      ?.toDouble() ??
                                  0;
                          final type =
                              data['type'] as String? ?? '';
                          return _logRow(
                            date,
                            fuel,
                            '${type == 'inflow' ? '+' : '='}${amount.toStringAsFixed(0)}L',
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

  Widget _txHeader() {
    return const Row(
      children: [
        Expanded(
            child: Text('Time',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11))),
        Expanded(
            child: Text('Fuel',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11))),
        Expanded(
            child: Text('Litres',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11))),
        Expanded(
            child: Text('Amount',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11))),
        Expanded(
            child: Text('Status',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11))),
      ],
    );
  }

  Widget _txRow(String time, String fuel, String litres,
      String amount, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(time,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11))),
          Expanded(
              child: Text(fuel,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11))),
          Expanded(
              child: Text(litres,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11))),
          Expanded(
              child: Text(amount,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11))),
          Expanded(
            child: Text(status,
                style: TextStyle(
                    color: status == '✓'
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _logRow(
      String date, String receipt, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(date,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11))),
          Expanded(
              child: Text(receipt,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11))),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
        ],
      ),
    );
  }
}