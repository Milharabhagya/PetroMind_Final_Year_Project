// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches HomeScreen, PriceScreen, AlertsScreen, ProfileScreen & AreaChat Design System

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_keys.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  DateTime? _lastMessageTime;

  // ✅ Key now comes from config file — not hardcoded
  static const String _apiKey = groqApiKey;

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hello! I\'m PetroMind AI 🤖\n\nI can help you with:\n• Current fuel prices in Sri Lanka\n• Finding nearby fuel stations\n• Vehicle fuel advice\n• Any fuel-related questions\n\nHow can I assist you today?',
      'isBot': true,
    },
  ];

  static const String _systemPrompt = '''
You are PetroMind AI, a helpful assistant for the PetroMind fuel tracking app in Sri Lanka.
Current fuel prices in Sri Lanka:
- Petrol (Octane 92): Rs. 298 per liter
- Diesel: Rs. 246 per liter
- Super Diesel: Rs. 281 per liter
- Kerosene: Rs. 182 per liter
Major fuel station brands: CEYPETCO, Lanka IOC, LAUGFS, SINOPEC, SHELL.
Always respond helpfully about fuel prices, stations, and vehicle advice.
Keep responses concise and friendly. Use emojis occasionally.
Respond in the same language the user writes in (Sinhala, Tamil, or English).
''';

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    final now = DateTime.now();
    if (_lastMessageTime != null && now.difference(_lastMessageTime!).inSeconds < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait a moment before sending again.', style: _T.body.copyWith(color: Colors.white)),
          duration: const Duration(seconds: 1),
          backgroundColor: _T.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    _lastMessageTime = now;

    setState(() {
      _messages.add({'text': text, 'isBot': false});
      _isTyping = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final List<Map<String, dynamic>> groqMessages = [];

      groqMessages.add({
        'role': 'system',
        'content': _systemPrompt,
      });

      final history = _messages.where((m) => m['text'] != text).take(10).toList();

      for (final m in history) {
        groqMessages.add({
          'role': m['isBot'] == true ? 'assistant' : 'user',
          'content': m['text'].toString(),
        });
      }

      groqMessages.add({
        'role': 'user',
        'content': text,
      });

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': groqMessages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;

        if (mounted) {
          setState(() {
            _messages.add({
              'text': reply.trim(),
              'isBot': true,
            });
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
          'text': 'Sorry, I\'m having trouble connecting right now. Please try again. 🙏',
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
    '🚗 Best fuel for my car?',
    '💰 Trip cost calculator',
    '⏰ Best time to fill up?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _T.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _T.primary.withOpacity(0.2)),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: _T.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PetroMind AI', style: _T.h2.copyWith(fontSize: 15)),
                Text('Powered by Groq LLaMA', style: _T.label.copyWith(fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── CHAT MESSAGES ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // ── TYPING INDICATOR ──
                if (index == _messages.length && _isTyping) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _T.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy_rounded, color: _T.primary, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _T.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(color: _T.border),
                            boxShadow: [
                              BoxShadow(
                                color: _T.dark.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(0),
                              const SizedBox(width: 4),
                              _dot(1),
                              const SizedBox(width: 4),
                              _dot(2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ── MESSAGE BUBBLE ──
                final msg = _messages[index];
                final isBot = msg['isBot'] as bool;
                final isFirst = index == 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      if (isBot) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _T.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy_rounded, color: _T.primary, size: 14),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isBot ? _T.surface : _T.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isBot ? 0 : 16),
                              bottomRight: Radius.circular(isBot ? 16 : 0),
                            ),
                            border: isBot ? Border.all(color: _T.border) : null,
                            boxShadow: [
                              BoxShadow(
                                color: _T.dark.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isFirst
                              ? Text.rich(TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Hello! ',
                                      style: _T.h2.copyWith(fontSize: 14, color: _T.primary),
                                    ),
                                    TextSpan(
                                      text: msg['text'].toString().replaceFirst('Hello! ', ''),
                                      style: _T.body.copyWith(fontSize: 13, color: _T.textPrimary),
                                    ),
                                  ],
                                ))
                              : Text(
                                  msg['text'].toString(),
                                  style: _T.body.copyWith(
                                    fontSize: 13,
                                    color: isBot ? _T.textPrimary : Colors.white,
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

          // ── QUICK SUGGESTION CHIPS ──
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
                    _messageController.text = _suggestions[i].replaceAll(RegExp(r'^[^\s]+\s'), '');
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _T.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _T.border),
                      boxShadow: [
                        BoxShadow(
                          color: _T.dark.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _suggestions[i],
                      style: _T.body.copyWith(fontSize: 11, color: _T.textPrimary),
                    ),
                  ),
                ),
              ),
            ),

          // ── INPUT BAR ──
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: _T.surface,
              boxShadow: [
                BoxShadow(
                  color: _T.dark.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
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
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.6)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isTyping ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isTyping ? _T.muted : _T.primary,
                      shape: BoxShape.circle,
                      boxShadow: _isTyping ? null : [
                        BoxShadow(
                          color: _T.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: _isTyping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _T.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}