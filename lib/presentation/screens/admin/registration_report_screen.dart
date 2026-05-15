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

  static const h1 = TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.4);
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

class RegistrationReportScreen extends StatefulWidget {
  const RegistrationReportScreen({super.key});

  @override
  State<RegistrationReportScreen> createState() => _RegistrationReportScreenState();
}

class _RegistrationReportScreenState extends State<RegistrationReportScreen> {
  List<_MonthData> _registrationData = [];
  bool _loadingChart = true;
  int _totalCustomers = 0;
  int _thisMonthCount = 0;
  int _lastMonthCount = 0;
  double _growthPercent = 0;
  String _selectedRange = '6 Months';

  final List<String> _ranges = ['3 Months', '6 Months', '12 Months'];

  @override
  void initState() {
    super.initState();
    _loadRegistrationData();
  }

  Future<void> _loadRegistrationData() async {
    setState(() => _loadingChart = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      final int monthsBack =
          _selectedRange == '3 Months' ? 3 : _selectedRange == '12 Months' ? 12 : 6;

      final Map<String, int> monthCounts = {};
      final now = DateTime.now();

      for (int i = monthsBack - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthCounts[key] = 0;
      }

      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final date = ts.toDate();
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (monthCounts.containsKey(key)) monthCounts[key] = (monthCounts[key] ?? 0) + 1;
        total++;
      }

      final thisMonthKey  = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastMonth     = DateTime(now.year, now.month - 1, 1);
      final lastMonthKey  = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
      final thisCount     = monthCounts[thisMonthKey] ?? 0;
      final lastCount     = monthCounts[lastMonthKey] ?? 0;
      double growth       = 0;
      if (lastCount > 0)       growth = ((thisCount - lastCount) / lastCount) * 100;
      else if (thisCount > 0)  growth = 100;

      final List<_MonthData> result = [];
      monthCounts.forEach((key, count) {
        final parts = key.split('-');
        final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        result.add(_MonthData(month: month, count: count, label: DateFormat('MMM yy').format(month)));
      });

      if (mounted) {
        setState(() {
          _registrationData = result;
          _totalCustomers   = total;
          _thisMonthCount   = thisCount;
          _lastMonthCount   = lastCount;
          _growthPercent    = growth;
          _loadingChart     = false;
        });
      }
    } catch (e) {
      debugPrint('Registration report error: $e');
      if (mounted) setState(() => _loadingChart = false);
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
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Registration Report', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: _loadingChart
          ? const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── SUMMARY CARDS ──
                  Row(children: [
                    _summaryCard(Icons.people_rounded, '$_totalCustomers', 'Total Customers', const Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    _summaryCard(Icons.person_add_rounded, '+$_thisMonthCount', 'This Month', _T.primary),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _summaryCard(Icons.history_rounded, '$_lastMonthCount', 'Last Month', const Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    _summaryCard(
                      _growthPercent >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      '${_growthPercent >= 0 ? '+' : ''}${_growthPercent.toStringAsFixed(1)}%',
                      'Growth',
                      _growthPercent >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── BAR CHART CARD ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_T.primary, _T.dark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: _T.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly Registrations',
                                style: TextStyle(fontFamily: 'Poppins', color: Colors.white,
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            // Range selector
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRange,
                                  dropdownColor: _T.dark,
                                  style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                                  items: _ranges.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedRange = val);
                                      _loadRegistrationData();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_registrationData.isEmpty)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No data available',
                                style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
                          ))
                        else
                          _buildBarChart(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── MONTHLY BREAKDOWN TABLE ──
                  Text('Monthly Breakdown', style: _T.h1.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _T.card(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
                              Expanded(child: Text('Month', style: _T.label.copyWith(fontWeight: FontWeight.w700))),
                              Text('New Users', style: _T.label.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: _T.border),
                        ..._registrationData.reversed.map((d) {
                          final isCurrentMonth =
                              d.month.year == DateTime.now().year && d.month.month == DateTime.now().month;
                          return Column(
                            children: [
                              Container(
                                color: isCurrentMonth ? _T.primary.withOpacity(0.04) : Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    if (isCurrentMonth)
                                      Container(
                                        width: 6, height: 6,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(color: _T.primary, shape: BoxShape.circle),
                                      ),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMMM yyyy').format(d.month),
                                        style: _T.h2.copyWith(
                                          fontSize: 13,
                                          color: isCurrentMonth ? _T.primary : _T.textPrimary,
                                          fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: d.count > 0 ? _T.primary.withOpacity(0.08) : _T.muted,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${d.count} users',
                                        style: _T.label.copyWith(
                                          color: d.count > 0 ? _T.primary : _T.textSecondary,
                                          fontWeight: FontWeight.w700, fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: _T.border),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBarChart() {
    final maxCount = _registrationData.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final maxVal   = maxCount == 0 ? 1 : maxCount;
    const chartH   = 160.0;
    const labelH   = 20.0;
    const barAreaH = chartH - labelH;

    return Column(
      children: [
        SizedBox(
          height: chartH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _registrationData.map((d) {
              final barH = (d.count / maxVal) * barAreaH;
              final isCurrent = d.month.year == DateTime.now().year && d.month.month == DateTime.now().month;
              return SizedBox(
                width: 32,
                height: chartH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: labelH,
                      child: Center(
                        child: d.count > 0
                            ? Text('${d.count}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.amber : Colors.white70,
                                  fontSize: 10, fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ))
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: barH < 4 ? 4 : barH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isCurrent
                              ? [Colors.amber[700]!, Colors.amber[300]!]
                              : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.7)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _registrationData.map((d) {
            final isCurrent = d.month.year == DateTime.now().year && d.month.month == DateTime.now().month;
            return SizedBox(
              width: 32,
              child: Text(DateFormat('MMM').format(d.month),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrent ? Colors.amber : Colors.white60,
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Poppins',
                  )),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            const Text('Registrations', style: TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Poppins')),
            const SizedBox(width: 16),
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            const Text('Current Month', style: TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Poppins')),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _T.card(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: _T.h2.copyWith(fontSize: 15, color: color),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(label, style: _T.label.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthData {
  final DateTime month;
  final int count;
  final String label;
  _MonthData({required this.month, required this.count, required this.label});
}