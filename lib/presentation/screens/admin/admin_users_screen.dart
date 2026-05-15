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

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

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
        title: Text('User Management', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: Column(
        children: [

          // ── SEARCH ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
                boxShadow: [BoxShadow(color: _T.dark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                style: _T.body.copyWith(color: _T.textPrimary),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.5)),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded, color: _T.textSecondary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── USER LIST ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                }

                var docs = snapshot.data!.docs;
                if (_search.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name  = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.toLowerCase();
                    final email = (d['email'] as String? ?? '').toLowerCase();
                    return name.contains(_search) || email.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_rounded, color: _T.textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('No users found', style: _T.h2),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data    = docs[i].data() as Map<String, dynamic>;
                    final name    = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                    final email   = data['email'] as String? ?? '';
                    final phone   = data['phone'] as String? ?? '—';
                    final ts      = data['createdAt'] as Timestamp?;
                    final dateStr = ts != null ? DateFormat('dd MMM yyyy').format(ts.toDate()) : 'Unknown';
                    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: _T.card(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: _T.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(initial,
                                  style: _T.h2.copyWith(fontSize: 16, color: _T.primary)),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name.isNotEmpty ? name : 'No name',
                                      style: _T.h2.copyWith(fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(email,
                                      style: _T.body.copyWith(fontSize: 11),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          color: _T.textSecondary, size: 11),
                                      const SizedBox(width: 4),
                                      Text(phone, style: _T.body.copyWith(fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Date + verified
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_user_rounded,
                                      color: Color(0xFF16A34A), size: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(dateStr, style: _T.label.copyWith(fontSize: 9)),
                              ],
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
        ],
      ),
    );
  }
}