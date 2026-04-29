import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_keys.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() =>
      _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
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
    if (_lastMessageTime != null &&
        now.difference(_lastMessageTime!).inSeconds < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please wait a moment before sending again.'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF8B0000),
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

      final history = _messages
          .where((m) => m['text'] != text)
          .take(10)
          .toList();

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

      final url = Uri.parse(
        'https://api.groq.com/openai/v1/chat/completions',
      );

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
        final reply = data['choices'][0]['message']
            ['content'] as String;

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
        print('Groq error: ${response.statusCode} ${response.body}');
        _addErrorMessage();
      }
    } catch (e) {
      print('Groq exception: $e');
      _addErrorMessage();
    }
  }

  void _addErrorMessage() {
    if (mounted) {
      setState(() {
        _messages.add({
          'text':
              'Sorry, I\'m having trouble connecting right now. Please try again. 🙏',
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
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PetroMind AI',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('Powered by Groq AI',
                  style:
                      TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person,
                  color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // ── CHAT MESSAGES ──
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.smart_toy,
                                  color: Color(0xFF8B0000),
                                  size: 22),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft:
                                      Radius.circular(16),
                                  topRight:
                                      Radius.circular(16),
                                  bottomRight:
                                      Radius.circular(16),
                                ),
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

                    final msg = _messages[index];
                    final isBot = msg['isBot'] as bool;
                    final isFirst = index == 0;

                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        mainAxisAlignment: isBot
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          if (isBot) ...[
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.smart_toy,
                                  color: Color(0xFF8B0000),
                                  size: 22),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context)
                                          .size
                                          .width *
                                      0.60,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    const Radius.circular(16),
                                topRight:
                                    const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                    isBot ? 0 : 16),
                                bottomRight: Radius.circular(
                                    isBot ? 16 : 0),
                              ),
                            ),
                            child: isFirst
                                ? Text.rich(TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Hello! ',
                                        style: TextStyle(
                                            color: Color(
                                                0xFF8B0000),
                                            fontWeight:
                                                FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: msg['text']
                                            .toString()
                                            .replaceFirst(
                                                'Hello! ', ''),
                                        style: const TextStyle(
                                            color:
                                                Colors.black87),
                                      ),
                                    ],
                                  ))
                                : Text(
                                    msg['text'].toString(),
                                    style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Quick suggestion chips
              if (_messages.length <= 2)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () {
                        _messageController.text =
                            _suggestions[i].replaceAll(
                                RegExp(r'^[^\s]+\s'), '');
                        _sendMessage();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.4)),
                        ),
                        child: Text(
                          _suggestions[i],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // ── INPUT BAR ──
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                            color: Colors.black38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  _isTyping
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF8B0000),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send,
                              color: Color(0xFF8B0000),
                              size: 22),
                          onPressed: _sendMessage,
                        ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration:
          Duration(milliseconds: 400 + (index * 150)),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF8B0000),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}