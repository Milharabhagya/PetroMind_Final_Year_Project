import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerFeedbackScreen extends StatefulWidget {
  const CustomerFeedbackScreen({super.key});

  @override
  State<CustomerFeedbackScreen> createState() =>
      _CustomerFeedbackScreenState();
}

class _CustomerFeedbackScreenState
    extends State<CustomerFeedbackScreen> {
  final _db = FirebaseFirestore.instance;
  final String _uid =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  String _stationName = '';
  String _stationBrand = '';

  @override
  void initState() {
    super.initState();
    if (_uid.isNotEmpty) _loadStationInfo();
  }

  Future<void> _loadStationInfo() async {
    try {
      final doc =
          await _db.collection('stations').doc(_uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _stationName =
            data?['stationName'] as String? ??
                data?['name'] as String? ??
                'My Station';
        _stationBrand =
            data?['brand'] as String? ?? '';
      });
    } catch (e) {
      debugPrint('_loadStationInfo error: $e');
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Avatar color based on first letter
  Color _avatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    if (name.isEmpty) return Colors.grey;
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
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
        title: const Text(
          'Customer Feedback',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: _uid.isEmpty
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('stations')
                  .doc(_uid)
                  .collection('ratings')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF8B0000)),
                  );
                }

                final docs = snapshot.data!.docs;

                // Calculate average rating
                double avgRating = 0;
                if (docs.isNotEmpty) {
                  double total = 0;
                  for (final doc in docs) {
                    total += ((doc.data()
                            as Map)['rating'] as num?)
                        ?.toDouble() ??
                        0;
                  }
                  avgRating = total / docs.length;
                }

                final displayName =
                    _stationBrand.isNotEmpty
                        ? '$_stationBrand $_stationName'
                        : _stationName;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── STATION BANNER ──
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              child: Container(
                                width: double.infinity,
                                color: Colors.grey[700],
                                child: const Center(
                                  child: Icon(
                                      Icons
                                          .local_gas_station,
                                      size: 60,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            // Station name badge
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius:
                                      BorderRadius.circular(
                                          4),
                                ),
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                      : 'My Station',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            // Live star rating
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  ...List.generate(5, (i) {
                                    if (i <
                                        avgRating.floor()) {
                                      return const Icon(
                                          Icons.star,
                                          color:
                                              Colors.amber,
                                          size: 16);
                                    } else if (i <
                                            avgRating &&
                                        avgRating -
                                                avgRating
                                                    .floor() >=
                                            0.5) {
                                      return const Icon(
                                          Icons.star_half,
                                          color:
                                              Colors.amber,
                                          size: 16);
                                    } else {
                                      return const Icon(
                                          Icons.star_border,
                                          color:
                                              Colors.amber,
                                          size: 16);
                                    }
                                  }),
                                  if (docs.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      avgRating
                                          .toStringAsFixed(
                                              1),
                                      style: const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight
                                                  .bold),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            // Review count badge
                            if (docs.isNotEmpty)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                            0xFF8B0000)
                                        .withOpacity(0.85),
                                    borderRadius:
                                        BorderRadius.circular(
                                            20),
                                  ),
                                  child: Text(
                                    '${docs.length} review${docs.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── REVIEWS LIST ──
                      if (docs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                  Icons
                                      .reviews_outlined,
                                  size: 48,
                                  color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No reviews yet',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Customer reviews will appear here',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      else
                        ...docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          final name =
                              data['userName'] as String? ??
                                  data['userId']
                                      as String? ??
                                  'Anonymous';
                          final rating =
                              (data['rating'] as num?)
                                      ?.toDouble() ??
                                  0;
                          final comment =
                              data['comment'] as String? ??
                                  '';
                          final ts =
                              data['timestamp'] as Timestamp?;
                          final timeStr = ts != null
                              ? _formatTime(ts.toDate())
                              : '';
                          final initial = name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?';

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          _avatarColor(name),
                                      radius: 18,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                            color:
                                                Colors.white,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 13),
                                          ),
                                          Row(
                                            children: List
                                                .generate(
                                              5,
                                              (i) => Icon(
                                                i <
                                                        rating
                                                            .floor()
                                                    ? Icons
                                                        .star
                                                    : (i <
                                                                rating &&
                                                            rating -
                                                                    rating.floor() >=
                                                                0.5
                                                        ? Icons
                                                            .star_half
                                                        : Icons
                                                            .star_border),
                                                color:
                                                    Colors.amber,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    comment,
                                    style: const TextStyle(
                                        color:
                                            Colors.black87,
                                        fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}