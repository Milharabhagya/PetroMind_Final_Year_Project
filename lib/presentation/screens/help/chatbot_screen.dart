// ✅ PETROMIND AI CHATBOT — LIVE DATA v2
// Fixes:
//   1. Uses LocationService singleton so GPS is shared with the map screen
//   2. Fetches road alerts reported by customers
//   3. Fetches fuel prices, all stations, crowd data, notifications
//
// Design: Minimalist Industrial SaaS · Poppins

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/api_keys.dart';
import '../../../services/location_service.dart'; // ← shared singleton

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

  static const h2 = TextStyle(
    fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: -0.2,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500,
    color: textSecondary, letterSpacing: 0.6,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400,
    color: textSecondary,
  );
}

// ─────────────────────────────────────────────
//  LIVE CONTEXT LOADER
// ─────────────────────────────────────────────
class _LiveContextLoader {
  static final _db = FirebaseFirestore.instance;

  static Future<String> load() async {
    final results = await Future.wait([
      _fetchFuelPrices(),
      _fetchStations(),
      _fetchCrowdData(),
      _fetchRecentNotifications(),
      _fetchRoadAlerts(),
    ]);
    return results.join('\n\n');
  }

  // ── 1. FUEL PRICES ──────────────────────────────────────────────────────────
  static Future<String> _fetchFuelPrices() async {
    try {
      final snap = await _db
          .collection('fuel_prices_ceypetco')
          .orderBy('category')
          .get();
      if (snap.docs.isEmpty) {
        return 'FUEL PRICES (CEYPETCO):\nNo price data available.';
      }
      final lines = snap.docs.map((doc) {
        final d     = doc.data();
        final name  = d['name']          ?? doc.id;
        final price = d['price']         ?? '?';
        final date  = d['effectiveDate'] ?? '';
        return '  • $name: Rs.${price.toString()} per liter  ($date)';
      }).join('\n');
      return 'FUEL PRICES (CEYPETCO — LIVE):\n$lines';
    } catch (e) {
      return 'FUEL PRICES: Could not load. '
          'Fallback: Petrol 92 ~Rs.292, Diesel ~Rs.277.';
    }
  }

  // ── 2. STATIONS ─────────────────────────────────────────────────────────────
  static Future<String> _fetchStations() async {
    try {
      final snap = await _db.collection('stations').limit(40).get();
      if (snap.docs.isEmpty) return 'STATIONS: None registered.';

      final lines = snap.docs.map((doc) {
        final d        = doc.data();
        final name     = d['stationName'] ?? d['firstName'] ?? 'Unnamed';
        final address  = d['address']     ?? 'No address';
        final phone    = d['phone']       ?? '';
        final isOpen   = d['isOpen'] == true ? 'OPEN' : 'CLOSED';
        final rating   = d['averageRating'] != null
            ? '⭐ ${(d['averageRating'] as num).toStringAsFixed(1)}'
            : '';
        final promo    = d['promotionMessage'] ?? '';

        final stock    = d['stock'] as Map<String, dynamic>? ?? {};
        final stockStr = stock.entries
            .where((e) => (e.value as num? ?? 0) > 0)
            .map((e) => '${e.key}: ${(e.value as num).toStringAsFixed(0)}L')
            .join(', ');

        final prices    = d['fuelPrices'] as Map<String, dynamic>? ?? {};
        final pricesStr = prices.entries
            .map((e) => '${e.key}: Rs.${(e.value as num).toStringAsFixed(0)}')
            .join(', ');

        final lat = d['latitude']  ?? d['stationLat'];
        final lng = d['longitude'] ?? d['stationLng'];
        final loc = (lat != null && lng != null)
            ? 'Lat:${lat.toString()}, Lng:${lng.toString()}'
            : 'No GPS data';

        return '  • $name [$isOpen] $rating\n'
            '    Address: $address  $phone\n'
            '    Location: $loc\n'
            '    Stock: ${stockStr.isNotEmpty ? stockStr : "unknown"}\n'
            '    Prices: ${pricesStr.isNotEmpty ? pricesStr : "national price"}\n'
            '    ${promo.isNotEmpty ? "Promo: $promo" : ""}';
      }).join('\n');

      return 'REGISTERED FUEL STATIONS (LIVE — ${snap.docs.length} stations):\n$lines';
    } catch (e) {
      return 'STATIONS: Could not load.';
    }
  }

  // ── 3. CROWD DATA ────────────────────────────────────────────────────────────
  static Future<String> _fetchCrowdData() async {
    try {
      final now        = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snap = await _db
          .collection('crowd_data')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (snap.docs.isEmpty) return 'CROWD DATA: No data recorded today.';

      final Map<String, Map<String, dynamic>> byStation = {};
      for (final doc in snap.docs) {
        final d   = doc.data();
        final sid = d['stationId'] as String? ?? '';
        final h   = d['hour']       as int?    ?? -1;
        final c   = d['crowdCount'] as int?    ?? 0;
        if (!byStation.containsKey(sid) ||
            (byStation[sid]!['hour'] as int) < h) {
          byStation[sid] = {'hour': h, 'count': c};
        }
      }

      final lines = byStation.entries.map((e) {
        final count = e.value['count'] as int;
        final tag   = count > 20 ? '🔴 VERY BUSY'
                    : count > 10 ? '🟡 BUSY'
                    : '🟢 QUIET';
        return '  • Station ${e.key}: ~$count vehicles  $tag';
      }).join('\n');

      return 'CURRENT CROWD LEVELS (LIVE — today):\n$lines';
    } catch (e) {
      return 'CROWD DATA: Could not load.';
    }
  }

  // ── 4. SYSTEM NOTIFICATIONS ──────────────────────────────────────────────────
  static Future<String> _fetchRecentNotifications() async {
    try {
      final snap = await _db
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (snap.docs.isEmpty) return 'STATION ALERTS: None recently.';

      final lines = snap.docs.map((doc) {
        final d     = doc.data();
        final title = d['title']   ?? '';
        final msg   = d['message'] ?? '';
        final type  = d['type']    ?? '';
        final ts    = (d['createdAt'] as Timestamp?)?.toDate();
        final time  = ts != null
            ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
            : '';
        return '  • [$type] $title — $msg  ($time)';
      }).join('\n');

      return 'RECENT STATION ALERTS (LIVE):\n$lines';
    } catch (e) {
      return 'STATION ALERTS: Could not load.';
    }
  }

  // ── 5. ROAD ALERTS (customer-reported) ──────────────────────────────────────
  // Tries the three most common collection names — adjust to match yours.
  static Future<String> _fetchRoadAlerts() async {
    try {
      QuerySnapshot? snap;
      for (final col in ['road_alerts', 'area_alerts', 'reports']) {
        try {
          final s = await _db
              .collection(col)
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get();
          if (s.docs.isNotEmpty) { snap = s; break; }
        } catch (_) { continue; }
      }

      if (snap == null || snap.docs.isEmpty) {
        return 'ROAD ALERTS (customer-reported): No active alerts.';
      }

      final now   = DateTime.now();
      final lines = <String>[];

      for (final doc in snap.docs) {
        final d        = doc.data() as Map<String, dynamic>;
        final type     = d['type']         ?? d['alertType']   ?? 'Alert';
        final message  = d['message']      ?? d['description'] ?? '';
        final location = d['location']     ?? d['address']     ?? '';
        final reporter = d['reporterName'] ?? d['userName']    ?? 'Anonymous';
        final lat      = d['latitude']     ?? d['lat'];
        final lng      = d['longitude']    ?? d['lng'];
        final ts       = (d['createdAt']   as Timestamp?)?.toDate();
        final isActive = d['isActive']     ?? d['active'] ?? true;

        // Skip resolved or old alerts
        if (isActive == false) continue;
        if (ts != null && now.difference(ts).inHours > 6) continue;

        final timeStr = ts != null
            ? '${ts.hour.toString().padLeft(2, '0')}:'
              '${ts.minute.toString().padLeft(2, '0')}'
            : 'unknown time';
        final locStr  = (lat != null && lng != null)
            ? 'Lat:${lat.toString()}, Lng:${lng.toString()}'
            : location;

        lines.add('  • [$type] $message\n'
            '    Location: $locStr\n'
            '    Reported by: $reporter at $timeStr');
      }

      if (lines.isEmpty) {
        return 'ROAD ALERTS: No active alerts in the last 6 hours.';
      }

      return 'ROAD ALERTS — REPORTED BY CUSTOMERS (LIVE — ${lines.length} active):\n'
          '${lines.join('\n')}';
    } catch (e) {
      return 'ROAD ALERTS: Could not load (error: $e).';
    }
  }
}

// ─────────────────────────────────────────────
//  CHATBOT SCREEN
// ─────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController  = ScrollController();

  bool      _isTyping         = false;
  bool      _isLoadingContext = true;
  DateTime? _lastMessageTime;

  static const String _apiKey = groqApiKey;

  String _liveContext = '';

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I\'m PetroMind AI 🤖\n\n'
          'I can help you with:\n'
          '• Live fuel prices in Sri Lanka\n'
          '• Nearby stations & stock levels\n'
          '• Road alerts reported by drivers\n'
          '• Crowd levels at stations\n'
          '• Vehicle fuel advice\n\n'
          'How can I assist you today?',
      'isBot': true,
    },
  ];

  // ── SYSTEM PROMPT ──────────────────────────────────────────────────────────
  String _buildSystemPrompt() {
    // ✅ Uses shared LocationService — same GPS the map screen uses
    final locCtx = LocationService.instance.contextString;

    return '''
You are PetroMind AI, the assistant for the PetroMind fuel tracking app in Sri Lanka.
You have access to LIVE database data fetched just before this message. Use it.
Never say "I don't have real-time data" — you DO.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USER LOCATION (from app GPS — same coordinates used by the map screen):
$locCtx
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LIVE DATA FROM DATABASE (fetched moments ago):
$_liveContext
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RULES:
1. PRICES — always quote from FUEL PRICES above. Never guess.
2. NEARBY STATIONS — use user Lat/Lng and station Lat/Lng to find the closest.
   Mention name, address, open/closed status, stock, and rough distance.
3. OUT OF STOCK — if stock = 0 for a fuel type, say so clearly.
4. CROWD — use CROWD LEVELS to recommend best time to visit.
5. ROAD ALERTS — when user asks about road conditions, accidents, or hazards,
   check ROAD ALERTS above and report active ones with location and time.
   If none, say the road looks clear.
6. TRIP COST — ask for km/L if not provided, then calculate using live price.
7. Keep replies concise and friendly. Use emojis occasionally.
8. Reply in the same language the user writes (Sinhala, Tamil, or English).
''';
  }

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    // Ensure location is ready (may already be fetched by home/map screen)
    await LocationService.instance.init();
    await _refreshLiveContext();
    if (mounted) setState(() => _isLoadingContext = false);
  }

  Future<void> _refreshLiveContext() async {
    try {
      final ctx = await _LiveContextLoader.load();
      if (mounted) setState(() => _liveContext = ctx);
    } catch (_) {
      if (mounted) {
        setState(() => _liveContext =
            'Live data temporarily unavailable. Use general knowledge as fallback.');
      }
    }
  }

  // ── SEND MESSAGE ──────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    final now = DateTime.now();
    if (_lastMessageTime != null &&
        now.difference(_lastMessageTime!).inSeconds < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please wait a moment.',
            style: _T.body.copyWith(color: Colors.white)),
        duration: const Duration(seconds: 1),
        backgroundColor: _T.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    _lastMessageTime = now;

    setState(() {
      _messages.add({'text': text, 'isBot': false});
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    // Always refresh live data before answering
    await _refreshLiveContext();

    try {
      final List<Map<String, dynamic>> msgs = [
        {'role': 'system', 'content': _buildSystemPrompt()},
      ];

      final history = _messages
          .where((m) => m['text'] != text)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .toList();

      for (final m in history) {
        msgs.add({
          'role': m['isBot'] == true ? 'assistant' : 'user',
          'content': m['text'].toString(),
        });
      }
      msgs.add({'role': 'user', 'content': text});

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': msgs,
          'temperature': 0.7,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data  = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        if (mounted) {
          setState(() {
            _messages.add({'text': reply.trim(), 'isBot': true});
            _isTyping = false;
          });
          _scrollToBottom();
        }
      } else {
        debugPrint('Groq error: ${response.statusCode} ${response.body}');
        _addErrorMessage();
      }
    } catch (e) {
      debugPrint('Groq exception: $e');
      _addErrorMessage();
    }
  }

  void _addErrorMessage() {
    if (mounted) {
      setState(() {
        _messages.add({
          'text': 'Sorry, I\'m having trouble connecting. Please try again. 🙏',
          'isBot': true,
        });
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  final List<String> _suggestions = [
    '⛽ Petrol price today?',
    '🗺️ Find nearby stations',
    '⚠️ Any road alerts near me?',
    '📦 Check stock levels',
    '🕐 Best time to fill up?',
    '💰 Trip cost calculator',
    '🔔 Recent station alerts?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locOk = LocationService.instance.hasLocation;

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _T.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _T.primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: _T.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PetroMind AI', style: _T.h2.copyWith(fontSize: 15)),
              Text('Powered by Groq LLaMA',
                  style: _T.label.copyWith(fontSize: 9)),
            ],
          ),
          const Spacer(),
          if (locOk)
            _StatusChip(icon: Icons.location_on,
                label: 'GPS', color: Colors.green),
          const SizedBox(width: 6),
          _StatusChip(
            icon: _isLoadingContext
                ? Icons.sync_rounded
                : Icons.cloud_done_rounded,
            label: _isLoadingContext ? 'Syncing' : 'LIVE',
            color: _isLoadingContext ? _T.textSecondary : _T.primary,
          ),
        ]),
      ),

      body: Column(children: [
        // Loading banner
        if (_isLoadingContext)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _T.primary.withOpacity(0.07),
            child: Row(children: [
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _T.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Fetching live prices, road alerts & station data…',
                style: _T.label.copyWith(fontSize: 10, color: _T.primary),
              ),
            ]),
          ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _BotAvatar(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _T.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(color: _T.border),
                          boxShadow: [BoxShadow(
                              color: _T.dark.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _dot(0), const SizedBox(width: 4),
                          _dot(1), const SizedBox(width: 4),
                          _dot(2),
                        ]),
                      ),
                    ],
                  ),
                );
              }

              final msg    = _messages[index];
              final isBot  = msg['isBot'] as bool;
              final isFirst = index == 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: isBot
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    if (isBot) ...[_BotAvatar(), const SizedBox(width: 8)],
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isBot ? _T.surface : _T.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isBot ? 0 : 16),
                            bottomRight: Radius.circular(isBot ? 16 : 0),
                          ),
                          border: isBot
                              ? Border.all(color: _T.border)
                              : null,
                          boxShadow: [BoxShadow(
                              color: _T.dark.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))],
                        ),
                        child: isFirst
                            ? Text.rich(TextSpan(children: [
                                TextSpan(
                                  text: 'Hello! ',
                                  style: _T.h2.copyWith(
                                      fontSize: 14, color: _T.primary),
                                ),
                                TextSpan(
                                  text: msg['text']
                                      .toString()
                                      .replaceFirst('Hello! ', ''),
                                  style: _T.body.copyWith(
                                      fontSize: 13,
                                      color: _T.textPrimary),
                                ),
                              ]))
                            : Text(
                                msg['text'].toString(),
                                style: _T.body.copyWith(
                                  fontSize: 13,
                                  color: isBot
                                      ? _T.textPrimary
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Suggestion chips
        if (_messages.length <= 2)
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  _messageController.text =
                      _suggestions[i].replaceAll(RegExp(r'^[^\s]+\s'), '');
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _T.border),
                    boxShadow: [BoxShadow(
                        color: _T.dark.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: Text(_suggestions[i],
                      style: _T.body
                          .copyWith(fontSize: 11, color: _T.textPrimary)),
                ),
              ),
            ),
          ),

        // Input bar
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: _T.surface,
            boxShadow: [BoxShadow(
                color: _T.dark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4))],
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _T.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: _T.body.copyWith(color: _T.textPrimary),
                  enabled: !_isLoadingContext,
                  decoration: InputDecoration(
                    hintText: _isLoadingContext
                        ? 'Fetching live data…'
                        : 'Type a message...',
                    hintStyle: _T.body.copyWith(
                        color: _T.textSecondary.withOpacity(0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_isTyping || _isLoadingContext) ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isTyping || _isLoadingContext)
                      ? _T.muted
                      : _T.primary,
                  shape: BoxShape.circle,
                  boxShadow: (_isTyping || _isLoadingContext)
                      ? null
                      : [BoxShadow(
                          color: _T.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))],
                ),
                child: (_isTyping || _isLoadingContext)
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int index) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0),
    duration: Duration(milliseconds: 400 + (index * 150)),
    builder: (_, v, __) => Opacity(
      opacity: v,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(
            color: _T.textSecondary, shape: BoxShape.circle),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────
class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
        color: _T.primary.withOpacity(0.12), shape: BoxShape.circle),
    child: const Icon(Icons.smart_toy_rounded,
        color: _T.primary, size: 14),
  );
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _StatusChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 10),
      const SizedBox(width: 3),
      Text(label, style: _T.label.copyWith(fontSize: 9, color: color)),
    ]),
  );
}