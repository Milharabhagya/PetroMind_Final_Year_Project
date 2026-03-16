import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello! How can i assist you today?', 'isBot': true},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isBot': false,
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        leading: Builder(builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        title: const Text('Get a support',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isBot = msg['isBot'] as bool;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: isBot
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          if (isBot) ...[
                            // Robot avatar
                            Container(
                              width: 36, height: 36,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.smart_toy,
                                  color: Color(0xFF8B0000), size: 22),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.55,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isBot ? 0 : 16),
                                bottomRight: Radius.circular(isBot ? 16 : 0),
                              ),
                            ),
                            child: Text.rich(
                              isBot
                                  ? TextSpan(children: [
                                      const TextSpan(
                                        text: 'Hello! ',
                                        style: TextStyle(
                                            color: Color(0xFF8B0000),
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: msg['text']
                                            .toString()
                                            .replaceFirst('Hello! ', ''),
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                    ])
                                  : TextSpan(
                                      text: msg['text'],
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

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
                        hintStyle: TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: Color(0xFF8B0000), size: 22),
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
}