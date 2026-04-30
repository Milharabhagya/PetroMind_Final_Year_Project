import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
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
        title: const Text('User Management',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── SEARCH ──
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
                  hintText: 'Search by name or email...',
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

          // ── USER LIST ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.amber));
                }
                var docs = snapshot.data!.docs;

                // Filter by search
                if (_search.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d =
                        doc.data() as Map<String, dynamic>;
                    final name =
                        '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'
                            .toLowerCase();
                    final email = (d['email'] as String? ??
                            '')
                        .toLowerCase();
                    return name.contains(_search) ||
                        email.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No users found',
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
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                            .trim();
                    final email =
                        data['email'] as String? ?? '';
                    final phone =
                        data['phone'] as String? ?? '—';
                    final ts =
                        data['createdAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat('dd MMM yyyy')
                            .format(ts.toDate())
                        : 'Unknown';
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : '?';

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blueAccent
                                .withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.blueAccent
                                    .withOpacity(0.2),
                            radius: 22,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isNotEmpty
                                      ? name
                                      : 'No name',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(email,
                                    style: const TextStyle(
                                        color:
                                            Colors.white54,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis),
                                Text('📞 $phone',
                                    style: const TextStyle(
                                        color:
                                            Colors.white38,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              const Icon(
                                  Icons
                                      .verified_user_rounded,
                                  color: Colors.greenAccent,
                                  size: 14),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10),
                              ),
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
}