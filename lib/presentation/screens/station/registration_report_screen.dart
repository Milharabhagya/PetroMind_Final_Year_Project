import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistrationReportScreen extends StatefulWidget {
  const RegistrationReportScreen({super.key});

  @override
  State<RegistrationReportScreen> createState() =>
      _RegistrationReportScreenState();
}

class _RegistrationReportScreenState
    extends State<RegistrationReportScreen> {
  List<_MonthData> _registrationData = [];
  bool _loadingChart = true;
  int _totalCustomers = 0;
  int _thisMonthCount = 0;
  int _lastMonthCount = 0;
  double _growthPercent = 0;
  String _selectedRange = '6 Months';

  final List<String> _ranges = [
    '3 Months',
    '6 Months',
    '12 Months'
  ];

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
          _selectedRange == '3 Months'
              ? 3
              : _selectedRange == '12 Months'
                  ? 12
                  : 6;

      final Map<String, int> monthCounts = {};
      final now = DateTime.now();

      for (int i = monthsBack - 1; i >= 0; i--) {
        final month =
            DateTime(now.year, now.month - i, 1);
        final key =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthCounts[key] = 0;
      }

      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final date = ts.toDate();
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (monthCounts.containsKey(key)) {
          monthCounts[key] =
              (monthCounts[key] ?? 0) + 1;
        }
        total++;
      }

      final thisMonthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastMonth =
          DateTime(now.year, now.month - 1, 1);
      final lastMonthKey =
          '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';

      final thisCount = monthCounts[thisMonthKey] ?? 0;
      final lastCount = monthCounts[lastMonthKey] ?? 0;
      double growth = 0;
      if (lastCount > 0) {
        growth =
            ((thisCount - lastCount) / lastCount) * 100;
      } else if (thisCount > 0) {
        growth = 100;
      }

      final List<_MonthData> result = [];
      monthCounts.forEach((key, count) {
        final parts = key.split('-');
        final month = DateTime(
            int.parse(parts[0]), int.parse(parts[1]));
        result.add(_MonthData(
          month: month,
          count: count,
          label: DateFormat('MMM yy').format(month),
        ));
      });

      if (mounted) {
        setState(() {
          _registrationData = result;
          _totalCustomers = total;
          _thisMonthCount = thisCount;
          _lastMonthCount = lastCount;
          _growthPercent = growth;
          _loadingChart = false;
        });
      }
    } catch (e) {
      print('Registration report error: $e');
      if (mounted) {
        setState(() => _loadingChart = false);
      }
    }
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
            child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registration Report',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loadingChart
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF8B0000)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ── SUMMARY CARDS ──
                  Row(children: [
                    _summaryCard(
                      icon: Icons.people,
                      value: '$_totalCustomers',
                      label: 'Total Customers',
                      color: const Color(0xFF8B0000),
                    ),
                    const SizedBox(width: 10),
                    _summaryCard(
                      icon: Icons.person_add,
                      value: '+$_thisMonthCount',
                      label: 'This Month',
                      color: Colors.blue[700]!,
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _summaryCard(
                      icon: Icons.history,
                      value: '$_lastMonthCount',
                      label: 'Last Month',
                      color: Colors.orange[700]!,
                    ),
                    const SizedBox(width: 10),
                    _summaryCard(
                      icon: _growthPercent >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      value:
                          '${_growthPercent >= 0 ? '+' : ''}${_growthPercent.toStringAsFixed(1)}%',
                      label: 'Growth',
                      color: _growthPercent >= 0
                          ? Colors.green[700]!
                          : Colors.red[700]!,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── CHART CARD ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ── Header + range selector ──
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Monthly Registrations',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 14),
                            ),
                            // ✅ Range selector
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(
                                        alpha: 0.15),
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRange,
                                  dropdownColor:
                                      const Color(
                                          0xFF8B0000),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11),
                                  icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                      size: 16),
                                  items: _ranges
                                      .map((r) =>
                                          DropdownMenuItem<String>(
                                            value: r,
                                            child: Text(r),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() =>
                                          _selectedRange =
                                              val);
                                      _loadRegistrationData();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── BARS ──
                        if (_registrationData.isEmpty)
                          const Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(20),
                              child: Text(
                                'No data available',
                                style: TextStyle(
                                    color:
                                        Colors.white54),
                              ),
                            ),
                          )
                        else
                          _buildBarChart(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── MONTHLY BREAKDOWN TABLE ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.05),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Breakdown',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF8B0000)),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const Row(children: [
                          Expanded(
                            child: Text('Month',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 12,
                                    color:
                                        Colors.grey)),
                          ),
                          Text('New Users',
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey)),
                        ]),
                        const Divider(),
                        ..._registrationData.reversed
                            .map((d) {
                          final isCurrentMonth =
                              d.month.year ==
                                      DateTime.now()
                                          .year &&
                                  d.month.month ==
                                      DateTime.now()
                                          .month;
                          return Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                                    vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrentMonth
                                  ? Colors.amber
                                      .withValues(
                                          alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(
                                      6),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Row(children: [
                                  if (isCurrentMonth)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin:
                                          const EdgeInsets
                                              .only(
                                              right: 6),
                                      decoration:
                                          const BoxDecoration(
                                        color:
                                            Colors.amber,
                                        shape: BoxShape
                                            .circle,
                                      ),
                                    ),
                                  Text(
                                    DateFormat(
                                            'MMMM yyyy')
                                        .format(d.month),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isCurrentMonth
                                          ? Colors
                                              .amber[800]
                                          : Colors
                                              .black87,
                                      fontWeight: isCurrentMonth
                                          ? FontWeight
                                              .bold
                                          : FontWeight
                                              .normal,
                                    ),
                                  ),
                                ]),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 10,
                                        vertical: 3),
                                decoration:
                                    BoxDecoration(
                                  color: d.count > 0
                                      ? const Color(
                                              0xFF8B0000)
                                          .withValues(
                                              alpha: 0.1)
                                      : Colors.grey[100],
                                  borderRadius:
                                      BorderRadius
                                          .circular(6),
                                ),
                                child: Text(
                                  '${d.count} users',
                                  style: TextStyle(
                                    color: d.count > 0
                                        ? const Color(
                                            0xFF8B0000)
                                        : Colors.grey,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ]),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildBarChart() {
    final maxCount = _registrationData
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b);
    final maxVal = maxCount == 0 ? 1 : maxCount;
    const chartHeight = 160.0;
    const labelHeight = 20.0;
    const barAreaHeight = chartHeight - labelHeight;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: _registrationData.map((d) {
              final barH =
                  (d.count / maxVal) * barAreaHeight;
              final isCurrentMonth =
                  d.month.year ==
                          DateTime.now().year &&
                      d.month.month ==
                          DateTime.now().month;

              return SizedBox(
                width: 32,
                height: chartHeight,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: labelHeight,
                      child: Center(
                        child: d.count > 0
                            ? Text(
                                '${d.count}',
                                style: TextStyle(
                                  color: isCurrentMonth
                                      ? Colors.amber
                                      : Colors.white70,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: barH < 4 ? 4 : barH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin:
                              Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isCurrentMonth
                              ? [
                                  Colors.amber[700]!,
                                  Colors.amber[300]!
                                ]
                              : [
                                  Colors.white
                                      .withValues(
                                          alpha: 0.4),
                                  Colors.white
                                      .withValues(
                                          alpha: 0.8),
                                ],
                        ),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Month labels
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children: _registrationData.map((d) {
            final isCurrentMonth =
                d.month.year == DateTime.now().year &&
                    d.month.month ==
                        DateTime.now().month;
            return SizedBox(
              width: 32,
              child: Text(
                DateFormat('MMM').format(d.month),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCurrentMonth
                      ? Colors.amber
                      : Colors.white60,
                  fontSize: 9,
                  fontWeight: isCurrentMonth
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: 0.6),
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Registrations',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10)),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Current Month',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── DATA MODEL ──
class _MonthData {
  final DateTime month;
  final int count;
  final String label;

  _MonthData({
    required this.month,
    required this.count,
    required this.label,
  });
}