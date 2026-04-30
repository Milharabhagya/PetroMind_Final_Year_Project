import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminStationsScreen extends StatefulWidget {
  const AdminStationsScreen({super.key});

  @override
  State<AdminStationsScreen> createState() =>
      _AdminStationsScreenState();
}

class _AdminStationsScreenState
    extends State<AdminStationsScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Station Management',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                onChanged: (v) =>
                    setState(() => _search = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search stations...',
                  hintStyle:
                      TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white38, size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _db.collection('stations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.amber));
                }
                var docs = snapshot.data!.docs;

                if (_search.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d =
                        doc.data() as Map<String, dynamic>;
                    final name =
                        (d['stationName'] as String? ??
                                d['name'] as String? ??
                                '')
                            .toLowerCase();
                    final brand =
                        (d['brand'] as String? ?? '')
                            .toLowerCase();
                    return name.contains(_search) ||
                        brand.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No stations found',
                        style: TextStyle(
                            color: Colors.white38)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()
                        as Map<String, dynamic>;
                    final name =
                        data['stationName'] as String? ??
                            data['name'] as String? ??
                            'Unknown';
                    final brand =
                        data['brand'] as String? ?? '—';
                    final city =
                        data['city'] as String? ?? '—';
                    final isOpen =
                        data['isOpen'] as bool? ?? false;
                    final revenue =
                        (data['totalRevenue'] as num?)
                                ?.toDouble() ??
                            0;
                    final email =
                        data['email'] as String? ?? '—';

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.greenAccent
                                .withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                ),
                                child: const Icon(
                                    Icons.local_gas_station,
                                    color:
                                        Colors.greenAccent,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color:
                                                Colors.white,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 14)),
                                    Text(
                                        '$brand • $city',
                                        style: const TextStyle(
                                            color: Colors
                                                .white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? Colors.green
                                          .withOpacity(0.2)
                                      : Colors.red
                                          .withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(
                                          6),
                                ),
                                child: Text(
                                  isOpen ? 'Open' : 'Closed',
                                  style: TextStyle(
                                      color: isOpen
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                              color: Colors.white12),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _infoChip(
                                  Icons.email_outlined,
                                  email,
                                  Colors.blueAccent),
                              const SizedBox(width: 10),
                              _infoChip(
                                  Icons.attach_money,
                                  'Rs.${NumberFormat('#,##0').format(revenue)}',
                                  Colors.greenAccent),
                            ],
                          ),
                        ],
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

  Widget _infoChip(
      IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white54, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}